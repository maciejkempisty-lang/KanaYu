import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import '../data/catalog.dart';
import '../data/journal.dart';

const appVersion = '0.2.0+3';
const gradingVersion = 'grading-rules/0.2';
const masteryVersion = 'mastery-rules/0.2';
const _uuid = Uuid();

class LearningStore extends ChangeNotifier {
  final Catalog catalog;
  final Journal journal;
  final DateTime Function() clock;
  final List<Map<String, dynamic>> events = [];
  final Map<String, fsrs.Card> cards = {};
  final Map<String, String> statuses = {};
  // Indexes rebuilt by _replay, so lookups do not scan the whole journal.
  final Set<String> _introduced = {};
  final Map<String, DateTime> _lastExposure = {};
  final Map<String, Set<String>> _exposedIn = {},
      _contactIn = {},
      _appliedIn = {};
  late final fsrs.Scheduler scheduler;
  late final Map<String, dynamic> fsrsConfig;
  String? sessionId;
  DateTime? lastActivity;
  Future<void> _writes = Future.value();
  LearningStore(this.catalog, this.journal, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now {
    // Fuzzing is explicitly disabled to make event replay deterministic.
    scheduler = fsrs.Scheduler(enableFuzzing: false);
    fsrsConfig = {
      'library': 'fsrs',
      'library_version': '2.0.1',
      'algorithm': 'FSRS-6',
      'params_hash': sha256
          .convert(utf8.encode(jsonEncode(scheduler.parameters)))
          .toString(),
      'desired_retention': 0.9,
      'enable_fuzzing': false,
      'learning_steps_seconds': [60, 600],
      'relearning_steps_seconds': [600],
    };
  }
  Future<void> initialize() async {
    events.addAll(await journal.readEvents());
    _replay();
    // An unclosed session from a killed process is closed on the next launch.
    final starts = events.where((e) => e['type'] == 'session_start').toList();
    if (starts.isNotEmpty) {
      final old = starts.last['session_id'];
      if (!events.any(
        (e) => e['type'] == 'session_end' && e['session_id'] == old,
      )) {
        await _commit([
          _event('session_end', {
            'session_id': old,
            'reason': 'previous_process_ended',
            'last_activity_at': events.lastWhere(
              (e) => e['session_id'] == old,
            )['timestamp'],
          }),
        ]);
      }
    }
    await ensureSession();
  }

  Map<String, dynamic> _event(
    String type, [
    Map<String, dynamic> data = const {},
  ]) => {
    'type': type,
    'event_id': _uuid.v4(),
    'session_id': sessionId,
    'timestamp': clock().toUtc().toIso8601String(),
    'tz_offset_min': clock().timeZoneOffset.inMinutes,
    'app_version': appVersion,
    'content_version': catalog.version,
    'grading_rules_version': gradingVersion,
    'mastery_rules_version': masteryVersion,
    // A deep copy: callers may keep mutating the lists they passed in.
    ...(jsonDecode(jsonEncode(data)) as Map<String, dynamic>),
  };
  Future<void> _commit(List<Map<String, dynamic>> batch) {
    final result = _writes.then((_) async {
      await journal.appendAll(batch);
      events.addAll(batch);
      _replay();
      notifyListeners();
    });
    _writes = result.catchError((Object _) {});
    return result;
  }

  Future<void> ensureSession() async {
    final now = clock().toUtc();
    if (sessionId != null &&
        lastActivity != null &&
        now.difference(lastActivity!) >= Duration(minutes: 30)) {
      await endSession('inactivity');
    }
    if (sessionId == null) {
      sessionId = _uuid.v4();
      await _commit([_event('session_start')]);
    }
    lastActivity = now;
  }

  void touch() {
    final now = clock().toUtc();
    if (lastActivity != null &&
        now.difference(lastActivity!) < Duration(minutes: 30)) {
      lastActivity = now;
    }
  }

  bool get musicEnabled =>
      events.reversed
              .where(
                (e) =>
                    e['type'] == 'preference_changed' &&
                    e['key'] == 'music_enabled',
              )
              .firstOrNull?['value']
          as bool? ??
      true;

  Future<void> setMusicEnabled(bool value) => _commit([
    _event('preference_changed', {'key': 'music_enabled', 'value': value}),
  ]);

  /// The session a new answer would belong to, or null if it has expired.
  String? get activeSessionId =>
      sessionId != null &&
          lastActivity != null &&
          clock().toUtc().difference(lastActivity!) < Duration(minutes: 30)
      ? sessionId
      : null;

  Future<void> endSession(String reason) async {
    if (sessionId == null) return;
    await _commit([
      _event('session_end', {
        'reason': reason,
        'last_activity_at': lastActivity?.toIso8601String(),
      }),
    ]);
    sessionId = null;
    lastActivity = null;
  }

  Future<void> expose(
    Kana k, {
    String source = 'lesson',
    List<String> prompt = const ['char', 'romaji_label', 'stroke_animation'],
  }) async {
    await ensureSession();
    await _commit([
      _event('exposure', {
        'content_item_id': k.id,
        'content_item_version': k.version,
        'task_source': source,
        'prompt_shown': prompt,
        'lesson_introduction': source == 'lesson',
      }),
    ]);
  }

  bool introduced(Kana k) => _introduced.contains(k.id);
  int get introducedCount => catalog.kana.where(introduced).length;
  List<Kana> get introducedKana => catalog.kana.where(introduced).toList();
  String status(Kana k, [String skill = 'kana_reading']) =>
      statuses['${k.id}|$skill'] ?? (introduced(k) ? 'Poznany' : 'Nowy');

  /// Item was shown (exposure) earlier in the active session.
  bool shownThisSession(Kana k) =>
      _exposedIn[activeSessionId]?.contains(k.id) ?? false;

  /// Cards due now whose answer would still update FSRS in this session.
  List<Kana> dueFor(String skill) => catalog.kana.where((k) {
    final key = '${k.id}|$skill';
    final c = cards[key];
    return c != null &&
        !c.due.isAfter(clock().toUtc()) &&
        !(_appliedIn[activeSessionId]?.contains(key) ?? false) &&
        !shownThisSession(k);
  }).toList();
  List<Kana> get due => dueFor('kana_reading');
  bool get lanternUnlocked =>
      events.any((e) => e['type'] == 'lesson_completed');
  Future<void> completeLesson() async {
    await ensureSession();
    await _commit([
      _event('lesson_completed', {
        'lesson_id': 'first-ten',
        'reward_id': 'first-lantern',
      }),
    ]);
  }

  /// Items already seen or answered in the active session wait for the next
  /// one, so a measurement is never taken right after practice.
  List<Kana> get measurementsDue => catalog.kana
      .where(
        (k) =>
            measurementDay(k) != null &&
            !(_contactIn[activeSessionId]?.contains(k.id) ?? false),
      )
      .toList();
  int? measurementDay(Kana k) {
    final exposures = events.where(
      (e) =>
          e['type'] == 'exposure' &&
          e['content_item_id'] == k.id &&
          e['lesson_introduction'] == true,
    );
    if (exposures.isEmpty) return null;
    final days = clock()
        .toUtc()
        .difference(DateTime.parse(exposures.first['timestamp']))
        .inDays;
    for (final d in [if (days >= 30) 30 else 7]) {
      if (days >= d &&
          !events.any(
            (e) =>
                e['type'] == 'attempt' &&
                e['content_item_id'] == k.id &&
                e['measurement_day'] == d,
          )) {
        return d;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> answer(
    Kana k, {
    required Object raw,
    required DateTime shownAt,
    String source = 'lesson',
    String skill = 'kana_reading',
    String mode = 'text',
    String grading = 'automatic',
    bool? selfCorrect,
    bool dontKnow = false,
    List<Map<String, dynamic>> support = const [],
    List<String> prompt = const ['char'],
    String? attemptId,
    DateTime? revealedAt,
    bool showSolution = false,
  }) async {
    await ensureSession();
    final normalized = raw is String ? normalizeAnswer(raw) : null;
    final matched = normalized != null
        ? k.accepted.where((a) => normalizeAnswer(a) == normalized).firstOrNull
        : null;
    final correct =
        !dontKnow &&
        (grading == 'self' ? selfCorrect == true : matched != null);
    final assistance = support.any(
      (s) => s['type'] != 'audio_replay' || skill == 'kana_reading',
    );
    final key = '${k.id}|$skill';
    final duplicate = _appliedIn[sessionId]?.contains(key) ?? false;
    final exposed = _exposedIn[sessionId]?.contains(k.id) ?? false;
    final contacted = _contactIn[sessionId]?.contains(k.id) ?? false;
    final lastExposure = _lastExposure[k.id];
    // Seeing the answer earlier in the session is not independent recall.
    // A brand-new card still gets its first (learning) review.
    final recentExposure = exposed && cards.containsKey(key);
    final eligible =
        ['kana_reading', 'kana_writing'].contains(skill) &&
        ['text', 'drawing', 'spoken'].contains(mode) &&
        source != 'corrective';
    final applied = eligible && !duplicate && !recentExposure;
    final e = _event(source == 'corrective' ? 'corrective' : 'attempt', {
      'attempt_id': attemptId ?? _uuid.v4(),
      'content_item_id': k.id,
      'content_item_version': k.version,
      'card_key': key,
      'skill': skill,
      'task_source': source,
      'response_mode': mode,
      'grading_mode': grading,
      'prompt_shown': prompt,
      'support_used': support,
      'raw_response': dontKnow ? {'dont_know': true, 'response': raw} : raw,
      'normalized_response': normalized,
      'matched_answer': matched,
      'first_attempt_result': dontKnow
          ? 'dont_know'
          : correct
          ? 'correct'
          : 'incorrect',
      'latency_ms': (revealedAt ?? clock())
          .toUtc()
          .difference(shownAt.toUtc())
          .inMilliseconds
          .clamp(0, 1 << 31),
      'solution_revealed_at': revealedAt?.toUtc().toIso8601String(),
      'fsrs_decision': {
        'applied': applied,
        'rating': applied ? (correct && !assistance ? 'Good' : 'Again') : null,
        'reason': !eligible
            ? 'not_scheduled_recall'
            : duplicate
            ? 'second_attempt_in_session'
            : recentExposure
            ? 'recent_exposure'
            : assistance
            ? 'assisted_recall'
            : 'first_recall_in_session',
      },
      'fsrs_config': fsrsConfig,
      'exposed_in_session': exposed,
      'ms_since_last_exposure': lastExposure == null
          ? null
          : clock().toUtc().difference(lastExposure).inMilliseconds,
      if (source == 'measurement') ...{
        'measurement_day': measurementDay(k),
        'measurement_clean': !contacted,
      },
    });
    await _commit([
      e,
      if (showSolution)
        _event('solution_revealed', {
          'attempt_id': e['attempt_id'],
          'content_item_id': k.id,
          'content_item_version': k.version,
          'prompt_shown': ['char', 'romaji_label'],
        }),
    ]);
    return e;
  }

  Future<void> commitDrawing(
    Kana k,
    String id,
    Object raw,
    DateTime shownAt,
    String source,
  ) async {
    await ensureSession();
    await _commit([
      _event('response_committed', {
        'attempt_id': id,
        'content_item_id': k.id,
        'content_item_version': k.version,
        'raw_response': {'strokes': raw, 'coordinate_space': 'normalized_0_1'},
        'skill': 'kana_writing',
        'task_source': source,
        'response_mode': 'drawing',
        'grading_mode': 'self',
        'latency_ms': clock()
            .toUtc()
            .difference(shownAt.toUtc())
            .inMilliseconds,
      }),
      _event('solution_revealed', {
        'attempt_id': id,
        'content_item_id': k.id,
        'content_item_version': k.version,
        'prompt_shown': [
          'stroke_overlay',
          'stroke_animation',
          'drawing_replay',
        ],
      }),
    ]);
  }

  Future<void> reveal(Kana k, String attemptId) => _commit([
    _event('solution_revealed', {
      'attempt_id': attemptId,
      'content_item_id': k.id,
      'content_item_version': k.version,
      'prompt_shown': ['char', 'romaji_label'],
    }),
  ]);
  void _replay() {
    cards.clear();
    statuses.clear();
    _introduced.clear();
    _lastExposure.clear();
    _exposedIn.clear();
    _contactIn.clear();
    _appliedIn.clear();
    final correctSessions = <String, Set<String>>{};
    final previous = <String, DateTime>{};
    final failedAt = <String, DateTime>{};
    final failedSession = <String, String>{};
    for (final e in events) {
      final type = e['type'];
      final session = e['session_id'] as String?;
      final item = e['content_item_id'] as String?;
      if (session == null || item == null) continue;
      final time = DateTime.parse(e['timestamp']);
      if (type == 'exposure') {
        if (e['lesson_introduction'] == true) _introduced.add(item);
        _lastExposure[item] = time;
        (_exposedIn[session] ??= {}).add(item);
        (_contactIn[session] ??= {}).add(item);
        continue;
      }
      if (type == 'corrective') (_contactIn[session] ??= {}).add(item);
      if (type != 'attempt') continue;
      final exposedBefore = _exposedIn[session]?.contains(item) ?? false;
      (_contactIn[session] ??= {}).add(item);
      final key = e['card_key'] as String;
      final decision = e['fsrs_decision'] as Map;
      if (decision['applied'] == true) {
        final base =
            cards[key] ?? fsrs.Card(cardId: cards.length + 1, due: time);
        cards[key] = scheduler
            .reviewCard(
              base,
              decision['rating'] == 'Good'
                  ? fsrs.Rating.good
                  : fsrs.Rating.again,
              reviewDateTime: time,
            )
            .card;
        (_appliedIn[session] ??= {}).add(key);
      }
      final writing =
          e['skill'] == 'kana_writing' && e['grading_mode'] == 'self';
      final reading =
          e['skill'] == 'kana_reading' &&
          e['grading_mode'] == 'automatic' &&
          e['response_mode'] == 'text';
      if (!writing && !reading) continue;
      if (!['text', 'drawing'].contains(e['response_mode'])) continue;
      final clean =
          e['first_attempt_result'] == 'correct' &&
          (e['support_used'] as List).isEmpty;
      final mastered = writing
          ? 'Utrwalony (samoocena)'
          : 'Utrwalony w czytaniu';
      final before = statuses[key];
      statuses.putIfAbsent(key, () => 'Ćwiczony');
      // A success right after seeing the item in the same session is not
      // evidence of recall; a failure still counts.
      if (clean && exposedBefore) continue;
      if (!clean && (before == mastered || before == 'Do odświeżenia')) {
        statuses[key] = 'Do odświeżenia';
        failedAt[key] = time;
        failedSession[key] = session;
      } else if (clean) {
        (correctSessions[key] ??= <String>{}).add(session);
        if (before == 'Do odświeżenia') {
          if (session != failedSession[key] &&
              time.difference(failedAt[key]!) >= Duration(days: 1)) {
            statuses[key] = mastered;
          }
        } else if (correctSessions[key]!.length >= 3 &&
            previous[key] != null &&
            time.difference(previous[key]!) >= Duration(days: 7)) {
          statuses[key] = mastered;
        }
      }
      previous[key] = time;
    }
  }

  String exportJson() => JsonEncoder.withIndent('  ').convert({
    'schema': 'kanayu-journal/1',
    'exported_at': clock().toUtc().toIso8601String(),
    'events': events,
  });
}
