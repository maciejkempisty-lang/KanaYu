import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/catalog.dart';
import '../domain/learning_store.dart';
import 'design.dart';
import 'strokes.dart';
import 'kigi_art.dart';
import '../audio/app_audio.dart';

class LessonTask {
  final Kana kana;
  final String kind, source;
  const LessonTask(this.kana, this.kind, this.source);
}

class LessonPage extends StatefulWidget {
  final LearningStore store;
  final List<Kana>? items;
  final String source;
  final bool writing;
  const LessonPage({
    super.key,
    required this.store,
    this.items,
    this.source = 'lesson',
    this.writing = false,
  });
  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  final text = TextEditingController();
  final scroll = ScrollController();
  AppAudio? audio;
  bool ownsAudio = false;
  final support = <Map<String, dynamic>>[];
  final Drawing drawing = [];
  late final List<LessonTask> tasks;
  int index = 0, correct = 0, attempted = 0;
  bool busy = false,
      feedback = false,
      finished = false,
      locked = false,
      hint = false;
  String? error, attemptId;
  Map<String, dynamic>? answer;
  late DateTime shownAt;
  DateTime? revealedAt;
  LessonTask get task => tasks[index];
  bool get fullLesson =>
      widget.source == 'lesson' && !widget.writing && widget.items == null;
  @override
  void initState() {
    super.initState();
    tasks = [];
    if (fullLesson) {
      for (final batch in [
        widget.store.catalog.kana.take(5).toList(),
        widget.store.catalog.kana.skip(5).toList(),
      ]) {
        tasks.addAll(batch.map((k) => LessonTask(k, 'exposure', 'lesson')));
        for (final i in [2, 0, 4, 1, 3]) {
          tasks.add(LessonTask(batch[i], 'reading', 'lesson'));
        }
      }
      tasks.addAll(
        widget.store.catalog.words.map((k) => LessonTask(k, 'word', 'lesson')),
      );
    } else {
      tasks.addAll(
        (widget.items ?? widget.store.catalog.kana).map(
          (k) => LessonTask(
            k,
            widget.writing ? 'writing' : 'reading',
            widget.source,
          ),
        ),
      );
    }
    shownAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  @override
  void dispose() {
    text.dispose();
    scroll.dispose();
    if (ownsAudio) {
      audio?.dispose();
    } else {
      audio?.stopVoice();
    }
    super.dispose();
  }

  Future<void> _enter() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.store.ensureSession();
      if (task.kind == 'exposure') await widget.store.expose(task.kana);
      if (mounted) {
        setState(() {
          busy = false;
          shownAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Nie udało się zapisać zadania. Spróbuj ponownie.';
        });
      }
    }
  }

  Future<void> _play() async {
    try {
      if (audio == null) {
        audio = AudioScope.of(context);
        if (audio == null) {
          audio = AppAudio(enabled: false);
          ownsAudio = true;
        }
      }
      await audio!.playVoice(task.kana.audio);
      if (audio!.error != null) throw StateError(audio!.error!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nie udało się odtworzyć dźwięku.')),
        );
      }
    }
  }

  Future<void> _submit({bool dontKnow = false, bool? selfCorrect}) async {
    if (busy || feedback) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      final e = await widget.store.answer(
        task.kana,
        raw: task.kind == 'writing'
            ? {
                'strokes': drawing,
                'coordinate_space': 'normalized_0_1',
                'locked_at': revealedAt?.toUtc().toIso8601String(),
              }
            : text.text,
        shownAt: shownAt,
        source: task.source,
        skill: task.kind == 'word'
            ? 'word_reading'
            : task.kind == 'writing'
            ? 'kana_writing'
            : 'kana_reading',
        mode: task.kind == 'writing' ? 'drawing' : 'text',
        grading: task.kind == 'writing' ? 'self' : 'automatic',
        selfCorrect: selfCorrect,
        dontKnow: dontKnow,
        support: support,
        prompt: task.kind == 'writing' ? ['romaji_prompt'] : ['char'],
        attemptId: attemptId,
        revealedAt: revealedAt,
        showSolution: task.kind != 'writing',
      );
      if (!mounted) return;
      final clean = e['first_attempt_result'] == 'correct' && support.isEmpty;
      if (task.source != 'corrective' && task.kind != 'exposure') {
        attempted++;
        if (clean) correct++;
      }
      if (!clean && task.kind == 'reading' && task.source != 'corrective') {
        // A delayed repair is logged, but never rescheduled in this session.
        tasks.insert(
          (index + 3).clamp(0, tasks.length),
          LessonTask(task.kana, 'reading', 'corrective'),
        );
      }
      setState(() {
        answer = e;
        feedback = true;
        busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        showFailure(context, e);
      }
    }
  }

  Future<void> _lockDrawing() async {
    if (busy) return;
    setState(() => busy = true);
    final id = Uuid().v4();
    try {
      final time = DateTime.now();
      await widget.store.commitDrawing(
        task.kana,
        id,
        drawing,
        shownAt,
        task.source,
      );
      if (mounted) {
        setState(() {
          attemptId = id;
          revealedAt = time;
          locked = true;
          busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        showFailure(context, e);
      }
    }
  }

  Future<void> _next() async {
    if (busy) return;
    setState(() => busy = true);
    FocusManager.instance.primaryFocus?.unfocus();
    await audio?.stopVoice();
    if (index == tasks.length - 1) {
      setState(() => busy = true);
      try {
        if (fullLesson) await widget.store.completeLesson();
        if (mounted) setState(() => finished = true);
      } catch (e) {
        if (mounted) {
          setState(() => busy = false);
          showFailure(context, e);
        }
      }
      return;
    }
    setState(() {
      index++;
      feedback = false;
      answer = null;
      hint = false;
      support.clear();
      drawing.clear();
      locked = false;
      attemptId = null;
      revealedAt = null;
      text.clear();
    });
    await _enter();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) scroll.jumpTo(0);
    });
  }

  Future<bool> _leave() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text('Przerwa na herbatę?'),
          content: Text(
            'Zapisane próby zostają w dzienniku. Do lekcji możesz wrócić z wioski.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text('Zostaję'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('Wróć do wioski'),
            ),
          ],
        ),
      ) ??
      false;
  @override
  Widget build(BuildContext context) {
    if (finished) return _result();
    final k = task.kana;
    final exposure = task.kind == 'exposure';
    final writing = task.kind == 'writing';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _leave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: sky,
        appBar: AppBar(
          backgroundColor: sky,
          title: Text(
            writing
                ? 'Pracownia pisania'
                : fullLesson
                ? 'Pierwsze światło'
                : 'Spokojna powtórka',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [MusicButton(), SizedBox(width: 12)],
        ),
        body: SafeArea(
          top: false,
          child: PageBody(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                controller: scroll,
                child: _LessonBody(
                  minHeight: constraints.maxHeight,
                  expand: !writing,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(22, 4, 22, 0),
                      child: LeafProgress(value: index, total: tasks.length),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(26, 20, 26, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(
                            exposure
                                ? 'Poznaj znak'
                                : writing
                                ? 'Z pamięci · samoocena'
                                : task.kind == 'word'
                                ? 'Pierwsze słowa'
                                : task.source == 'corrective'
                                ? 'Jeszcze jedno spotkanie'
                                : 'Samodzielny odczyt',
                          ),
                          SizedBox(height: 5),
                          Text(
                            exposure
                                ? 'Mały znak, nowy dźwięk.'
                                : writing
                                ? 'Napisz „${k.reading}”.'
                                : task.kind == 'word'
                                ? 'Potrafisz już złożyć słowo.'
                                : 'Jak czytamy ten znak?',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (writing)
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Paper(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Napisz z pamięci, a potem porównaj ze wzorcem.',
                                style: TextStyle(color: muted),
                              ),
                              SizedBox(height: 16),
                              ..._writing(),
                              if (feedback) ...[
                                SizedBox(height: 16),
                                _feedback(),
                                SizedBox(height: 16),
                                _continueButton(),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.fromLTRB(38, 4, 38, 14),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 330),
                            child: KanaBoard(
                              child: exposure
                                  ? Center(
                                      child: StrokeView(
                                        key: ValueKey(k.id),
                                        paths: k.strokes,
                                        animate: true,
                                        size: 180,
                                      ),
                                    )
                                  : Center(
                                      child: Semantics(
                                        label: 'Znak do odczytania',
                                        child: ExcludeSemantics(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              k.char,
                                              style: TextStyle(
                                                fontFamily: 'KleeOne',
                                                fontSize: task.kind == 'word'
                                                    ? 72
                                                    : 116,
                                                height: 1.55,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    if (!writing) Meadow(child: _practicePanel()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _practicePanel() {
    final k = task.kana;
    final exposure = task.kind == 'exposure';
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: cream),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cream,
            side: BorderSide(color: leaf),
            minimumSize: Size(48, 48),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error != null) ...[
                  Text(error!, style: TextStyle(color: cream)),
                  TextButton(
                    onPressed: _enter,
                    child: Text('Spróbuj ponownie'),
                  ),
                ] else if (exposure) ...[
                  Row(
                    children: [
                      Text(
                        k.reading,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: cream,
                        ),
                      ),
                      Spacer(),
                      OutlinedButton.icon(
                        onPressed: _play,
                        icon: Icon(Icons.volume_up_rounded),
                        label: Text('Posłuchaj'),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),
                  Text(
                    k.note,
                    style: TextStyle(color: cream, height: 1.5, fontSize: 14),
                  ),
                  if (k.variants.any((v) => v['note'] != null))
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        k.variants
                            .where((v) => v['note'] != null)
                            .map((v) => v['note'])
                            .join(' '),
                        style: TextStyle(
                          color: paleLeaf,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ] else ...[
                  Text(
                    task.kind == 'word'
                        ? 'Wpisz odczyt słowa w rōmaji'
                        : 'Wpisz odczyt w rōmaji',
                    style: TextStyle(
                      color: cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Semantics(
                    label: 'Twój odczyt',
                    child: TextField(
                      key: ValueKey('answer'),
                      controller: text,
                      enabled: !feedback && !busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      textCapitalization: TextCapitalization.none,
                      keyboardType: TextInputType.visiblePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (text.text.trim().isNotEmpty) {
                          _submit();
                        }
                      },
                      onChanged: (_) {
                        widget.store.touch();
                        setState(() {});
                      },
                      decoration: InputDecoration(hintText: 'np. ka'),
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                  ),
                  if (hint && !feedback)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Paper(child: Text(k.mnemonic)),
                    ),
                  // Shape notes are deliberately not offered as recall hints.
                  if (!feedback &&
                      task.source != 'measurement' &&
                      k.mnemonic.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: hint || busy
                            ? null
                            : () => setState(() {
                                hint = true;
                                support.add({
                                  'type': 'mnemonic',
                                  'timestamp': DateTime.now()
                                      .toUtc()
                                      .toIso8601String(),
                                });
                              }),
                        icon: Icon(Icons.lightbulb_outline_rounded, size: 18),
                        label: Text('Potrzebuję wskazówki'),
                      ),
                    ),
                  if (feedback)
                    Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Theme(data: appTheme(), child: _feedback()),
                    ),
                ],
              ],
            ),
            Padding(
              padding: EdgeInsets.only(top: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (exposure || feedback)
                    _continueButton()
                  else ...[
                    FilledButton(
                      onPressed:
                          busy || text.text.trim().isEmpty || error != null
                          ? null
                          : () => _submit(),
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: Color(0xFFB6C49B),
                        disabledForegroundColor: Color(0xFF37482F),
                      ),
                      child: Text(busy ? 'Zapisuję…' : 'Sprawdź'),
                    ),
                    SizedBox(height: 6),
                    TextButton(
                      onPressed: busy || error != null
                          ? null
                          : () => _submit(dontKnow: true),
                      child: Text('Nie wiem jeszcze'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _continueButton() => FilledButton(
    onPressed: busy || error != null ? null : _next,
    child: Text(
      busy
          ? 'Zapisuję…'
          : feedback && index == tasks.length - 1
          ? 'Zakończ'
          : 'Dalej',
    ),
  );

  List<Widget> _writing() {
    if (!locked) {
      return [
        SizedBox(
          height: 280,
          child: Center(
            child: SizedBox.square(
              dimension: 280,
              child: DrawingPad(
                key: ValueKey(task.kana.id),
                drawing: drawing,
                onChanged: () {
                  widget.store.touch();
                  setState(() {});
                },
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: busy ? null : () => setState(() => drawing.clear()),
              icon: Icon(Icons.refresh_rounded),
              label: Text('Wyczyść'),
            ),
          ],
        ),
        FilledButton(
          onPressed: busy || drawing.isEmpty ? null : _lockDrawing,
          child: Text(busy ? 'Zapisuję…' : 'Zatwierdź i porównaj'),
        ),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  await _lockDrawing();
                  if (locked) await _submit(dontKnow: true, selfCorrect: false);
                },
          child: Text('Nie pamiętam'),
        ),
      ];
    }
    return [
      Center(
        child: StrokeView(
          paths: task.kana.strokes,
          drawing: drawing,
          overlay: true,
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Twój zapis nałożony na wzorzec',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 12),
      ),
      SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, c) {
          final size = (c.maxWidth - 16) / 2;
          return Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    StrokeView(drawing: drawing, animate: true, size: size),
                    Text('Twoje kreski', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    StrokeView(
                      paths: task.kana.strokes,
                      animate: true,
                      size: size,
                    ),
                    Text('Wzorzec', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      SizedBox(height: 16),
      Text(
        'Twoje kreski: ${drawing.length}. Wzorzec: ${task.kana.strokes.length}. Liczba kresek jest wskazówką, nie oceną. ${task.kana.variants.where((v) => v['note'] != null).map((v) => v['note']).join(' ')}',
        style: TextStyle(color: muted, fontSize: 13, height: 1.5),
      ),
      if (!feedback) ...[
        SizedBox(height: 20),
        Text(
          'Czy zapis był poprawny?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        FilledButton(
          onPressed: busy ? null : () => _submit(selfCorrect: true),
          child: Text('Poprawnie — samoocena'),
        ),
        TextButton(
          onPressed: busy ? null : () => _submit(selfCorrect: false),
          child: Text('Błąd lub nie pamiętam'),
        ),
      ],
    ];
  }

  Widget _feedback() {
    final good = answer!['first_attempt_result'] == 'correct';
    final assisted = support.isNotEmpty;
    final confused = widget.store.catalog.kana
        .where(
          (k) =>
              k.id != task.kana.id &&
              k.accepted.contains(normalizeAnswer(text.text)),
        )
        .firstOrNull;
    return Paper(
      color: good && !assisted ? Color(0xFFEAF0E5) : Color(0xFFF5EBDD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                good && !assisted
                    ? Icons.check_circle_outline
                    : Icons.spa_outlined,
                color: forest,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  good
                      ? (assisted
                            ? 'Z pomocą też się uczymy.'
                            : 'Tak, właśnie tak!')
                      : 'Ten znak jeszcze wróci.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${task.kana.char}  →  ${task.kana.reading}',
            style: TextStyle(fontSize: 27),
          ),
          if (task.kind == 'word')
            Text(task.kana.note, style: TextStyle(color: muted)),
          if (!good && confused != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Dla porównania: ${confused.char} czytamy „${confused.reading}”.',
              ),
            ),
          SizedBox(height: 8),
          Text(
            task.source == 'corrective'
                ? 'To ćwiczenie po podpowiedzi. Wynik zapisujemy osobno.'
                : assisted
                ? 'Zapisano użycie wskazówki. Wrócimy do samodzielnej próby.'
                : answer!['fsrs_decision']['reason'] == 'recent_exposure'
                ? 'Ten znak był już pokazany w tej sesji, więc próba nie zmienia terminu powtórki ani statusu.'
                : task.kind == 'writing'
                ? 'Zapisano samoocenę. Aplikacja nie rozpoznaje pisma.'
                : good
                ? 'Odpowiedź zapisana. Kolejne spotkania pomogą ją utrwalić.'
                : 'Nie musisz pamiętać wszystkiego od razu.',
            style: TextStyle(color: muted, fontSize: 13, height: 1.5),
          ),
          TextButton.icon(
            onPressed: _play,
            icon: Icon(Icons.volume_up_rounded, size: 19),
            label: Text('Posłuchaj wymowy'),
          ),
        ],
      ),
    );
  }

  Widget _result() => Scaffold(
    appBar: AppBar(title: Text('Dobra robota')),
    body: SafeArea(
      child: PageBody(
        child: ListView(
          padding: EdgeInsets.all(28),
          children: [
            SizedBox(height: 30),
            Center(
              child: Container(
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: paleLeaf,
                  shape: BoxShape.circle,
                ),
                child: Lantern(size: 100),
              ),
            ),
            SizedBox(height: 32),
            Eyebrow(
              fullLesson
                  ? 'Nowy zakątek twojej historii'
                  : 'Kolejne spotkanie za nami',
            ),
            SizedBox(height: 12),
            Text(
              fullLesson
                  ? 'Pierwsze światło\nw wiosce.'
                  : 'Dziękuję za dzisiejszą chwilę.',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            SizedBox(height: 18),
            Text(
              fullLesson
                  ? 'Lampion przy szkole już świeci. To pamiątka pierwszej lekcji, a poznane znaki będziemy spokojnie utrwalać.'
                  : 'Twoje próby są zapisane. Wróć, gdy przyjdzie pora na kolejne spotkanie.',
              style: TextStyle(fontSize: 16, color: muted, height: 1.6),
            ),
            SizedBox(height: 24),
            Paper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$correct / $attempted',
                    style: TextStyle(fontSize: 30, color: forest),
                  ),
                  Text(
                    widget.writing
                        ? 'Poprawne próby według samooceny.'
                        : 'Samodzielne poprawne odpowiedzi w tej rundzie.',
                    style: TextStyle(color: muted),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Utrwalenie sprawdzimy w kolejnych dniach.',
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.cottage_outlined),
              label: Text('Wróć do wioski'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Fill the viewport on tall screens; retain natural scrolling with a keyboard
/// or larger text. Drawing uses its own layout and avoids intrinsic measurement.
class _LessonBody extends StatelessWidget {
  final double minHeight;
  final bool expand;
  final List<Widget> children;
  const _LessonBody({
    required this.minHeight,
    required this.expand,
    required this.children,
  });
  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: expand
          ? [
              ...children.take(children.length - 1),
              Expanded(child: children.last),
            ]
          : children,
    );
    return expand
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(child: content),
          )
        : content;
  }
}
