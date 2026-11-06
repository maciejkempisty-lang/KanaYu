import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:kanayu/data/catalog.dart';
import 'package:kanayu/data/journal.dart';
import 'package:kanayu/domain/learning_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Tests deliberately create independent temporary SQLite databases.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late LearningStore store;
  late Catalog catalog;
  late Journal db;
  late DateTime now;
  Kana getKana() => catalog.kana.first;
  Future<Map<String, dynamic>> answer({
    String? raw,
    bool dontKnow = false,
    List<Map<String, dynamic>> support = const [],
    String source = 'lesson',
  }) => store.answer(
    getKana(),
    raw: raw ?? getKana().reading,
    shownAt: now,
    source: source,
    dontKnow: dontKnow,
    support: support,
  );
  Future<void> next(Duration elapsed) async {
    await store.endSession('test');
    now = now.add(elapsed);
    await store.ensureSession();
  }

  setUp(() async {
    now = DateTime.utc(2026, 10, 28, 10);
    catalog = await Catalog.load();
    db = Journal(NativeDatabase.memory());
    store = LearningStore(catalog, db, clock: () => now);
    await store.initialize();
  });
  tearDown(() async {
    store.dispose();
    await db.close();
  });

  test(
    'normalization accepts technical differences, preserves vowel length',
    () {
      expect(normalizeAnswer(' Ｋ Ａ\n'), 'ka');
      expect(normalizeAnswer('o\u0304'), 'ō');
      expect(normalizeAnswer('oo'), isNot(normalizeAnswer('o')));
    },
  );
  test(
    'catalog has ten distinct kana, ordered stroke paths, local audio and accepted answers',
    () {
      expect(catalog.kana.map((k) => k.char).join(), 'あいうえおかきくけこ');
      expect(catalog.kana.map((k) => k.id).toSet(), hasLength(10));
      for (final k in [...catalog.kana, ...catalog.allWords]) {
        expect(k.accepted, contains(k.reading));
        expect(File('assets/${k.audio}').existsSync(), true);
      }
      for (final k in catalog.kana) {
        expect(k.strokes, isNotEmpty);
      }
    },
  );
  test(
    'exposure creates no card; raw failed response is retained before reveal',
    () async {
      await store.expose(getKana());
      expect(store.cards, isEmpty);
      final e = await store.answer(
        getKana(),
        raw: 'wrong',
        shownAt: now,
        showSolution: true,
      );
      expect(e['raw_response'], 'wrong');
      expect(e['fsrs_decision']['rating'], 'Again');
      expect(store.events.last['type'], 'solution_revealed');
      expect(store.events.last['attempt_id'], e['attempt_id']);
      expect(store.events[store.events.length - 2]['type'], 'attempt');
    },
  );
  test('partial hint before a correct answer is Again, not Good', () async {
    final e = await answer(
      support: [
        {'type': 'mnemonic', 'timestamp': now.toIso8601String()},
      ],
    );
    expect(e['first_attempt_result'], 'correct');
    expect(e['fsrs_decision']['rating'], 'Again');
  });
  test(
    'one FSRS update per card per session, corrective remains in journal',
    () async {
      await answer(dontKnow: true);
      final snapshot = store.cards.values.single.toMap();
      final e = await answer();
      expect(e['fsrs_decision']['applied'], false);
      final correction = await answer(source: 'corrective');
      expect(correction['type'], 'corrective');
      expect(correction['fsrs_decision']['applied'], false);
      expect(store.cards.values.single.toMap(), snapshot);
      expect(
        store.events.where(
          (e) => ['attempt', 'corrective'].contains(e['type']),
        ),
        hasLength(3),
      );
    },
  );
  test('real FSRS package updates same-day reviews in new sessions', () async {
    await answer();
    final first = store.cards.values.single;
    await next(Duration(hours: 1));
    final e = await answer();
    final second = store.cards.values.single;
    expect(e['fsrs_decision']['applied'], true);
    expect(second.lastReview, now);
    expect(second.stability, isNot(first.stability));
    final expected = fsrs.Scheduler(
      enableFuzzing: false,
    ).reviewCard(first, fsrs.Rating.good, reviewDateTime: now).card;
    expect(second.toMap(), expected.toMap());
  });
  test('30 minutes of inactivity creates a new session, 29 does not', () async {
    final id = store.sessionId;
    now = now.add(Duration(minutes: 29));
    await store.ensureSession();
    expect(store.sessionId, id);
    now = now.add(Duration(minutes: 30));
    await store.ensureSession();
    expect(store.sessionId, isNot(id));
    expect(
      store.events.where((e) => e['type'] == 'session_end').last['reason'],
      'inactivity',
    );
  });
  test(
    'mastery requires three distinct sessions with final seven-day gap; refresh takes a day',
    () async {
      await answer();
      await answer();
      expect(store.status(getKana()), 'Ćwiczony');
      await next(Duration(days: 1));
      await answer();
      expect(store.status(getKana()), 'Ćwiczony');
      await next(Duration(days: 7));
      await answer();
      expect(store.status(getKana()), 'Utrwalony w czytaniu');
      await next(Duration(days: 1));
      await answer(raw: 'i');
      expect(store.status(getKana()), 'Do odświeżenia');
      await next(Duration(hours: 1));
      await answer();
      expect(store.status(getKana()), 'Do odświeżenia');
      await next(Duration(days: 1));
      await answer();
      expect(store.status(getKana()), 'Utrwalony w czytaniu');
    },
  );
  test('word reading and recognition never create kana cards', () async {
    final word = catalog.words.first;
    await store.answer(
      word,
      raw: word.reading,
      shownAt: now,
      skill: 'word_reading',
    );
    await store.answer(getKana(), raw: 'a', shownAt: now, mode: 'choice');
    expect(store.cards, isEmpty);
    expect(store.status(getKana()), 'Nowy');
  });
  test(
    'writing is committed before reveal and graded as independent self evidence',
    () async {
      final strokes = [
        [
          [.1, .2, 0],
          [.3, .4, 100],
        ],
      ];
      await store.commitDrawing(
        getKana(),
        'drawing-1',
        strokes,
        now,
        'minigame',
      );
      expect(store.cards, isEmpty);
      expect(
        store.events[store.events.length - 2]['raw_response']['strokes'],
        strokes,
      );
      await store.answer(
        getKana(),
        raw: {'strokes': strokes},
        shownAt: now,
        skill: 'kana_writing',
        mode: 'drawing',
        grading: 'self',
        selfCorrect: true,
        attemptId: 'drawing-1',
      );
      expect(store.cards.keys.single, '${getKana().id}|kana_writing');
      expect(store.events.last['grading_mode'], 'self');
      expect(store.events.last['raw_response']['strokes'], strokes);
    },
  );
  test(
    'day 7/30 measurements are anchored to introduction and update scheduler',
    () async {
      await store.expose(getKana());
      now = now.add(Duration(days: 6));
      expect(store.measurementsDue, isEmpty);
      now = now.add(Duration(days: 1));
      expect(store.measurementDay(getKana()), 7);
      final e = await answer(source: 'measurement');
      expect(e['measurement_day'], 7);
      expect(e['measurement_clean'], true);
      expect(e['fsrs_decision']['applied'], true);
      expect(store.measurementsDue, isEmpty);
      now = now.add(Duration(days: 23));
      expect(store.measurementDay(getKana()), 30);
    },
  );
  test(
    'SQLite round trip recreates exact scheduling, raw evidence and reward',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'kanayu-journal-test',
      );
      final file = File('${directory.path}/test.sqlite');
      final firstDb = Journal(NativeDatabase(file));
      final first = LearningStore(catalog, firstDb, clock: () => now);
      await first.initialize();
      await first.answer(getKana(), raw: ' Ａ ', shownAt: now);
      await first.completeLesson();
      final state = first.cards.values.single.toMap();
      await firstDb.close();
      first.dispose();
      final secondDb = Journal(NativeDatabase(file));
      final second = LearningStore(
        catalog,
        secondDb,
        clock: () => now.add(Duration(hours: 1)),
      );
      await second.initialize();
      expect(second.cards.values.single.toMap(), state);
      expect(second.lanternUnlocked, true);
      expect(
        second.events.firstWhere((e) => e['type'] == 'attempt')['raw_response'],
        ' Ａ ',
      );
      expect(jsonDecode(second.exportJson())['schema'], 'kanayu-journal/1');
      await secondDb.close();
      second.dispose();
      await directory.delete(recursive: true);
    },
  );
  test(
    'events keep their own copy of lists the caller mutates later',
    () async {
      final support = [
        {'type': 'mnemonic'},
      ];
      await answer(support: support);
      support.clear();
      final drawing = [
        [
          [.1, .1, 0],
          [.5, .5, 10],
        ],
      ];
      await store.commitDrawing(getKana(), 'd-1', drawing, now, 'minigame');
      drawing.clear();
      final attempt = store.events.firstWhere((e) => e['type'] == 'attempt');
      expect(attempt['support_used'], hasLength(1));
      final committed = store.events.firstWhere(
        (e) => e['type'] == 'response_committed',
      );
      expect(committed['raw_response']['strokes'], hasLength(1));
      expect(store.exportJson(), contains('mnemonic'));
      // The hinted success must not count as clean recall after the next write.
      await next(Duration(days: 8));
      await answer();
      expect(store.status(getKana()), 'Ćwiczony');
    },
  );
  test(
    'success right after seeing the item does not update FSRS or mastery',
    () async {
      await answer(); // first review creates the card
      final snapshot = store.cards.values.single.toMap();
      for (var i = 0; i < 3; i++) {
        await next(Duration(days: 8));
        await store.expose(getKana(), source: 'minigame');
        expect(store.due, isEmpty);
        final e = await answer(source: 'scheduled_review');
        expect(e['exposed_in_session'], true);
        expect(e['fsrs_decision']['applied'], false);
        expect(e['fsrs_decision']['reason'], 'recent_exposure');
      }
      expect(store.status(getKana()), 'Ćwiczony');
      expect(store.cards.values.single.toMap(), snapshot);
    },
  );
  test(
    'first lesson review after introduction still creates the card',
    () async {
      await store.expose(getKana());
      final e = await answer();
      expect(e['fsrs_decision']['applied'], true);
      expect(e['exposed_in_session'], true);
      expect(store.cards, hasLength(1));
    },
  );
  test(
    'failure after seeing the item still marks mastered card for refresh',
    () async {
      await answer();
      await next(Duration(days: 1));
      await answer();
      await next(Duration(days: 7));
      await answer();
      expect(store.status(getKana()), 'Utrwalony w czytaniu');
      await next(Duration(days: 1));
      await store.expose(getKana(), source: 'minigame');
      await answer(raw: 'i');
      expect(store.status(getKana()), 'Do odświeżenia');
    },
  );
  test('writing cards get their own due queue', () async {
    await store.answer(
      getKana(),
      raw: {'strokes': []},
      shownAt: now,
      skill: 'kana_writing',
      mode: 'drawing',
      grading: 'self',
      selfCorrect: true,
    );
    expect(store.dueFor('kana_writing'), isEmpty);
    await next(Duration(days: 30));
    expect(store.dueFor('kana_writing').single.id, getKana().id);
    expect(store.due, isEmpty);
  });
  test('measurement waits for a session without earlier contact', () async {
    await store.expose(getKana());
    await next(Duration(days: 7));
    expect(store.measurementsDue.single.id, getKana().id);
    await answer(source: 'minigame');
    expect(store.measurementsDue, isEmpty);
    final e = await answer(source: 'measurement');
    expect(e['measurement_clean'], false);
  });
  test(
    'session end records last activity; retired words stay resolvable',
    () async {
      final started = now;
      now = now.add(Duration(minutes: 5));
      await store.endSession('test');
      final end = store.events.lastWhere((e) => e['type'] == 'session_end');
      expect(end['last_activity_at'], started.toIso8601String());
      expect(catalog.words.map((w) => w.char), ['いいえ', 'ここ', 'いい']);
      expect(catalog.item('word.kao').retired, true);
    },
  );
}
