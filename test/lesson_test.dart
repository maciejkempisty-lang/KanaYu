import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanayu/data/catalog.dart';
import 'package:kanayu/data/journal.dart';
import 'package:kanayu/domain/learning_store.dart';
import 'package:kanayu/ui/design.dart';
import 'package:kanayu/ui/lesson.dart';
import 'package:kanayu/ui/strokes.dart';

void main() {
  testWidgets('small screen with large text keeps reading controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    late Journal db;
    late LearningStore store;
    await tester.runAsync(() async {
      db = Journal(NativeDatabase.memory());
      store = LearningStore(await Catalog.load(), db);
      await store.initialize();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: LessonPage(
          store: store,
          items: [store.catalog.kana.first],
          source: 'minigame',
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pump();
    await tester.ensureVisible(find.text('Sprawdź'));
    await tester.tap(find.text('Sprawdź'));
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Tak, właśnie tak!'));
    expect(tester.takeException(), isNull);
    expect(store.events.where((e) => e['type'] == 'attempt'), hasLength(1));
    await tester.pumpWidget(SizedBox());
    store.dispose();
    await tester.runAsync(db.close);
  });
  testWidgets(
    'writing records stroke before reveal and does not scroll during drawing',
    (tester) async {
      tester.view.physicalSize = Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Journal db;
      late LearningStore store;
      await tester.runAsync(() async {
        db = Journal(NativeDatabase.memory());
        store = LearningStore(await Catalog.load(), db);
        await store.initialize();
      });
      Future<void> tick() async {
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(Duration(milliseconds: 10)),
          );
          await tester.pump(Duration(milliseconds: 50));
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: LessonPage(
            store: store,
            items: [store.catalog.kana.first],
            writing: true,
            source: 'minigame',
          ),
        ),
      );
      await tick();
      final pad = find.byType(DrawingPad);
      final y = tester.getTopLeft(pad).dy;
      await tester.drag(pad, Offset(30, 100));
      await tester.pump();
      expect(tester.getTopLeft(pad).dy, y);
      await tester.ensureVisible(find.text('Zatwierdź i porównaj'));
      await tester.tap(find.text('Zatwierdź i porównaj'));
      await tick();
      expect(
        store.events.where((e) => e['type'] == 'response_committed'),
        hasLength(1),
      );
      expect(store.cards, isEmpty);
      expect(find.byType(DrawingPad), findsNothing);
      await tester.ensureVisible(find.text('Poprawnie — samoocena'));
      await tester.tap(find.text('Poprawnie — samoocena'));
      await tick();
      final e = store.events.last;
      expect(e['response_mode'], 'drawing');
      expect(e['grading_mode'], 'self');
      expect(e['raw_response']['strokes'], hasLength(1));
      expect(e['fsrs_decision']['rating'], 'Good');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(SizedBox());
      store.dispose();
      await tester.runAsync(db.close);
    },
  );
  testWidgets(
    'complete 10-kana lesson on a 390px screen persists 13 answers and reward',
    (tester) async {
      tester.view.physicalSize = Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Journal db;
      late LearningStore store;
      await tester.runAsync(() async {
        final catalog = await Catalog.load();
        db = Journal(NativeDatabase.memory());
        store = LearningStore(catalog, db);
        await store.initialize();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: LessonPage(store: store),
        ),
      );
      Future<void> tick() async {
        for (var step = 0; step < 8; step++) {
          await tester.runAsync(
            () => Future<void>.delayed(Duration(milliseconds: 10)),
          );
          await tester.pump(Duration(milliseconds: 50));
        }
      }

      Future<void> tap(String label) async {
        await tester.pump();
        final f = find.widgetWithText(FilledButton, label);
        await tester.ensureVisible(f);
        expect(tester.widget<FilledButton>(f).onPressed, isNotNull);
        await tester.tap(f);
        await tick();
      }

      await tick();
      for (var group = 0; group < 2; group++) {
        for (var i = 0; i < 5; i++) {
          await tap('Dalej');
          expect(tester.takeException(), isNull);
        }
        for (final i in [2, 0, 4, 1, 3]) {
          await tester.enterText(
            find.byType(TextField),
            store.catalog.kana[group * 5 + i].reading,
          );
          await tap('Sprawdź');
          expect(find.text('Tak, właśnie tak!'), findsOneWidget);
          await tap('Dalej');
          expect(tester.takeException(), isNull);
        }
      }
      for (var i = 0; i < 3; i++) {
        await tester.enterText(
          find.byType(TextField),
          store.catalog.words[i].reading,
        );
        await tap('Sprawdź');
        await tap(i == 2 ? 'Zakończ' : 'Dalej');
      }
      expect(find.text('Pierwsze światło\nw wiosce.'), findsOneWidget);
      expect(store.introducedCount, 10);
      expect(store.cards, hasLength(10));
      expect(store.lanternUnlocked, true);
      expect(store.events.where((e) => e['type'] == 'attempt'), hasLength(13));
      expect(store.statuses.values.every((s) => s == 'Ćwiczony'), true);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(SizedBox());
      store.dispose();
      await tester.runAsync(db.close);
    },
  );
  testWidgets(
    'hinted correct answer records Again; raw text and reveal stay linked',
    (tester) async {
      late Journal db;
      late LearningStore store;
      await tester.runAsync(() async {
        // Shipped content has no reviewed mnemonics yet, so the test brings one.
        final catalog = Catalog('test', [
          Kana(
            id: 'kana.hira.a',
            char: 'あ',
            reading: 'a',
            accepted: ['a'],
            mnemonic: 'Testowe skojarzenie.',
            audio: 'audio/a.wav',
          ),
        ], []);
        db = Journal(NativeDatabase.memory());
        store = LearningStore(catalog, db);
        await store.initialize();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: LessonPage(
            store: store,
            items: [store.catalog.kana.first],
            source: 'minigame',
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: 40)),
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Potrzebuję wskazówki'));
      await tester.tap(find.text('Potrzebuję wskazówki'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), ' Ａ ');
      await tester.pump();
      await tester.ensureVisible(find.text('Sprawdź'));
      await tester.tap(find.text('Sprawdź'));
      await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: 40)),
      );
      await tester.pump();
      expect(find.text('Z pomocą też się uczymy.'), findsOneWidget);
      final e = store.events.firstWhere((e) => e['type'] == 'attempt');
      expect(e['raw_response'], ' Ａ ');
      expect(e['fsrs_decision']['rating'], 'Again');
      expect(store.events.last['attempt_id'], e['attempt_id']);
      await tester.pumpWidget(SizedBox());
      store.dispose();
      await tester.runAsync(db.close);
    },
  );
  testWidgets('no hint button without a reviewed mnemonic', (tester) async {
    late Journal db;
    late LearningStore store;
    await tester.runAsync(() async {
      db = Journal(NativeDatabase.memory());
      store = LearningStore(await Catalog.load(), db);
      await store.initialize();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: LessonPage(
          store: store,
          items: [store.catalog.kana.first],
          source: 'minigame',
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: 40)),
    );
    await tester.pump();
    expect(find.text('Jak czytamy ten znak?'), findsOneWidget);
    expect(find.text('Potrzebuję wskazówki'), findsNothing);
    await tester.pumpWidget(SizedBox());
    store.dispose();
    await tester.runAsync(db.close);
  });
}
