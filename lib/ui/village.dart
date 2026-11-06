import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../data/catalog.dart';
import '../domain/learning_store.dart';
import 'design.dart';
import 'lesson.dart';
import 'resident.dart';
import 'kigi_art.dart';
import '../audio/app_audio.dart';

class VillagePage extends StatefulWidget {
  final LearningStore store;
  const VillagePage({super.key, required this.store});
  @override
  State<VillagePage> createState() => _VillagePageState();
}

class _VillagePageState extends State<VillagePage> {
  int tab = 0;
  LearningStore get store => widget.store;
  Future<void> _lesson({
    List<Kana>? items,
    String source = 'lesson',
    bool writing = false,
  }) async {
    AudioScope.of(context)?.activate();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonPage(
          store: store,
          items: items,
          source: source,
          writing: writing,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _welcome() async {
    AudioScope.of(context)?.activate();
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, 4, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Yuu · opiekun szkoły'),
                SizedBox(height: 12),
                Text(
                  'Zaczynamy od małych kroków.',
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 14),
                Text(
                  'Poznamy あいうえお i かきくけこ. Najpierw zobaczysz i usłyszysz każdy znak, a potem spróbujesz odczytać go samodzielnie.',
                  style: TextStyle(color: muted, fontSize: 16, height: 1.6),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.headphones_rounded, size: 18, color: muted),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Dźwięk możesz odtwarzać przyciskiem.'),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: Text('Wejdź do szkoły'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (go == true && mounted) await _lesson();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => AnnotatedRegion<SystemUiOverlayStyle>(
      value: tab == 0 ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: tab == 0 ? forest : cream,
        body: SafeArea(
          bottom: false,
          child: PageBody(
            child: tab == 0
                ? _village()
                : tab == 1
                ? _notebook()
                : _journal(),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          backgroundColor: cream,
          indicatorColor: paleLeaf,
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.cottage_outlined),
              selectedIcon: Icon(Icons.cottage_rounded),
              label: 'Polana',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories),
              label: 'Moje znaki',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_edu_outlined),
              selectedIcon: Icon(Icons.history_edu),
              label: 'Dziennik',
            ),
          ],
        ),
      ),
    ),
  );
  Widget _village() => LayoutBuilder(
    builder: (context, constraints) {
      final sceneHeight = (constraints.maxHeight * .61).clamp(330.0, 490.0);
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: sceneHeight,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/art/kigi-village.png',
                    fit: BoxFit.cover,
                    alignment: Alignment(0, .05),
                    excludeFromSemantics: true,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [forest.withValues(alpha: 0), forest],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 18,
                    right: 18,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: ink.withValues(alpha: .08),
                                blurRadius: 15,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.spa_rounded, color: forest, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'KanaYu',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        MusicButton(),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 80,
                    left: 22,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: cream.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'POLANA POCZĄTKÓW',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w800,
                          color: forest,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: sceneHeight * .49,
                    right: 35,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: cream,
                        foregroundColor: forest,
                        minimumSize: Size(44, 44),
                        padding: EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: _welcome,
                      icon: Icon(Icons.door_front_door_outlined, size: 18),
                      label: Text('学校  Szkoła', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  if (store.lanternUnlocked)
                    Positioned(
                      top: sceneHeight * .61,
                      right: 36,
                      child: Lantern(size: 39),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 12,
                    width: 140,
                    height: 158,
                    child: Semantics(
                      button: true,
                      label: 'Yuu, liściasty opiekun szkoły. Porozmawiaj.',
                      child: GestureDetector(
                        onTap: _welcome,
                        child: Resident(),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 36,
                    left: 151,
                    right: 18,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YUU',
                            style: TextStyle(
                              color: forest,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            store.lanternUnlocked
                                ? 'Twój lampion już świeci. Dobrze znów cię widzieć!'
                                : 'Chodź, pokażę ci szkołę. Zaczniemy od małych kroków.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: forest,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Paper(
              padding: EdgeInsets.all(21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Eyebrow('Dziś na polanie'),
                      Spacer(),
                      Icon(Icons.wb_sunny_outlined, size: 18, color: forest),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Pierwsze światło',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'あ い う え お   ·   か き く け こ',
                    style: TextStyle(
                      fontFamily: 'KleeOne',
                      fontSize: 19,
                      color: forest,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Poznaj 10 znaków i zapal lampion przy szkole. Każdy krok w swoim tempie.',
                    style: TextStyle(fontSize: 14, color: muted, height: 1.4),
                  ),
                  SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _welcome,
                      child: Text(
                        store.lanternUnlocked
                            ? 'Odwiedź szkołę ponownie'
                            : 'Zacznij lekcję',
                      ),
                    ),
                  ),
                  if (store.due.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _lesson(
                          items: store.due,
                          source: 'scheduled_review',
                        ),
                        child: Text('Najpierw powtórki (${store.due.length})'),
                      ),
                    ),
                  if (store.dueFor('kana_writing').isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _lesson(
                          items: store.dueFor('kana_writing'),
                          source: 'scheduled_review',
                          writing: true,
                        ),
                        child: Text(
                          'Powtórz pisanie (${store.dueFor('kana_writing').length})',
                        ),
                      ),
                    ),
                  if (store.introducedCount > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        '${store.introducedCount} / ${store.catalog.kana.length} poznanych · ${_count(store.catalog.words.length, 'słowo', 'słowa', 'słów')} w lekcji',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            color: forest,
            padding: EdgeInsets.fromLTRB(32, 0, 32, 22),
            child: Row(
              children: [
                Icon(Icons.park_outlined, size: 20, color: paleLeaf),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Za strumieniem czeka ogród katakany.\nOdkryjemy go w kolejnych rozdziałach.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: cream),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
  Widget _notebook() {
    final due = store.due;
    final dueWriting = store.dueFor('kana_writing');
    final known = store.introducedKana;
    final mastered = store.catalog.kana
        .where((k) => store.status(k).startsWith('Utrwalony'))
        .length;
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Eyebrow('Twój notes'),
        SizedBox(height: 8),
        Text(
          'Małe ślady postępu.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text(
          'Poznanie znaku to początek. Utrwalenie sprawdzamy podczas kolejnych spotkań.',
          style: TextStyle(color: muted, height: 1.6),
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _stat(
                '${store.introducedCount}/${store.catalog.kana.length}',
                'poznanych',
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: _stat('$mastered', 'utrwalonych')),
          ],
        ),
        SizedBox(height: 20),
        if (store.measurementsDue.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: FilledButton.icon(
              onPressed: () =>
                  _lesson(items: store.measurementsDue, source: 'measurement'),
              icon: Icon(Icons.event_available),
              label: Text('Sprawdź pamięć · pomiar po przerwie'),
            ),
          ),
        if (due.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _lesson(items: due, source: 'scheduled_review'),
            icon: Icon(Icons.refresh),
            label: Text('Znaki na dzisiaj: ${due.length}'),
          ),
        if (dueWriting.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: due.isEmpty ? 0 : 10),
            child: FilledButton.icon(
              onPressed: () => _lesson(
                items: dueWriting,
                source: 'scheduled_review',
                writing: true,
              ),
              icon: Icon(Icons.gesture_rounded),
              label: Text('Pisanie na dzisiaj: ${dueWriting.length}'),
            ),
          ),
        if (due.isEmpty && dueWriting.isEmpty)
          Paper(
            color: Color(0xFFEAF0E5),
            child: Row(
              children: [
                Icon(Icons.spa_outlined, color: forest),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Na teraz wystarczy. Wioska spokojnie na ciebie poczeka.',
                    style: TextStyle(color: forest),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: store.catalog.kana
              .map(
                (k) => SizedBox(
                  width: 100,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _detail(k),
                    child: Paper(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text(k.char, style: TextStyle(fontSize: 40)),
                          Text(
                            store.status(k),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: known.isEmpty
              ? null
              : () => _lesson(items: known, source: 'minigame'),
          icon: Icon(Icons.style_outlined),
          label: Text('Poćwicz czytanie'),
        ),
        SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: known.isEmpty
              ? null
              : () => _lesson(items: known, source: 'minigame', writing: true),
          icon: Icon(Icons.gesture_rounded),
          label: Text('Włącz pisanie · samoocena'),
        ),
        SizedBox(height: 14),
        Text(
          known.isEmpty
              ? 'Ćwiczenia otworzą się po poznaniu pierwszych znaków w szkole.'
              : 'Ćwiczymy tylko poznane znaki. Kolejna próba tej samej karty w jednej sesji nie zmienia terminu powtórki.',
          style: TextStyle(fontSize: 12, color: muted, height: 1.6),
        ),
      ],
    );
  }

  String _count(int n, String one, String few, String many) => Intl.plural(
    n,
    one: '$n $one',
    few: '$n $few',
    many: '$n $many',
    other: '$n $few',
    locale: 'pl',
  );
  Widget _stat(String value, String label) => Paper(
    padding: EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 28, color: forest)),
        Text(label, style: TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
  Future<void> _detail(Kana k) async {
    try {
      await store.expose(
        k,
        source: 'minigame',
        prompt: ['char', 'romaji_label'],
      );
    } catch (e) {
      if (mounted) showFailure(context, e);
      return;
    }
    if (!mounted) return;
    final card = store.cards['${k.id}|kana_reading'];
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${k.char}  ${k.reading}', style: TextStyle(fontSize: 44)),
              SizedBox(height: 14),
              Text(
                store.status(k),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text('Pisanie: ${store.status(k, 'kana_writing')}'),
              SizedBox(height: 12),
              Text(
                card == null
                    ? 'Termin powtórki pojawi się po pierwszej próbie.'
                    : 'Termin: ${DateFormat('dd.MM.yyyy · HH:mm').format(card.due.toLocal())}',
                style: TextStyle(color: muted),
              ),
              SizedBox(height: 12),
              Text(
                'Przeglądanie znaku zapisujemy jako kontakt z materiałem. Do końca tej sesji odpowiedź na ten znak nie zmieni terminu powtórki ani statusu.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _journal() {
    final attempts = store.events
        .where((e) => ['attempt', 'corrective'].contains(e['type']))
        .toList()
        .reversed
        .take(30)
        .toList();
    return ListView(
      padding: EdgeInsets.all(24),
      children: [
        Eyebrow('Zapisane na tym urządzeniu'),
        SizedBox(height: 8),
        Text(
          'Historia spotkań.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 12),
        Text(
          'Każda pierwsza próba ma znaczenie — także błąd. Twój dziennik pozostaje lokalnie.',
          style: TextStyle(color: muted, height: 1.6),
        ),
        SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: _export,
          icon: Icon(Icons.ios_share_rounded),
          label: Text('Eksportuj dziennik JSON'),
        ),
        SizedBox(height: 22),
        if (attempts.isEmpty)
          Paper(
            child: Text(
              'Pierwszy wpis pojawi się po ćwiczeniu w szkole.',
              style: TextStyle(color: muted),
            ),
          ),
        for (final e in attempts)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Paper(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    store.catalog.item(e['content_item_id']).char,
                    style: TextStyle(fontSize: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['first_attempt_result'] == 'correct'
                              ? 'Poprawna odpowiedź'
                              : e['first_attempt_result'] == 'dont_know'
                              ? 'Jeszcze nie pamiętam'
                              : 'Próba do odświeżenia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${e['skill'] == 'kana_writing'
                              ? 'Pisanie · samoocena'
                              : e['skill'] == 'word_reading'
                              ? 'Czytanie słowa'
                              : 'Odczyt znaku'} · ${DateFormat('dd.MM · HH:mm').format(DateTime.parse(e['timestamp']).toLocal())}',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                        if ((e['support_used'] as List).isNotEmpty)
                          Text(
                            'Ze wskazówką',
                            style: TextStyle(fontSize: 11, color: terracotta),
                          ),
                        if (e['type'] == 'corrective')
                          Text(
                            'Ćwiczenie korekcyjne',
                            style: TextStyle(fontSize: 11, color: muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 22),
        Paper(
          color: Color(0xFFF0EEE5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O prototypie',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'KanaYu $appVersion · Flutter + Rive\nWymowa: syntetyczny głos japoński Kyoko.\nKreski: KanjiVG, CC BY-SA 3.0, Ulrich Apel i współtwórcy.\nFonty: Nunito, Klee One, Zen Maru Gothic — SIL OFL.\nYuu: własna grafika wektorowa i animacja Rive dla KanaYu.\nPolana Kigi: ilustracja wygenerowana dla aplikacji.\nMuzyka: YuSoundtrack, utwór dostarczony przez autora projektu.',
                style: TextStyle(fontSize: 12, color: muted, height: 1.7),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Future<void> _export() async {
    try {
      final bytes = utf8.encode(store.exportJson());
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/json')],
          fileNameOverrides: ['kanayu-dziennik.json'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Eksport się nie powiódł: $e')));
      }
    }
  }
}
