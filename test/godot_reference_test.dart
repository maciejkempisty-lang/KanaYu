// Migration oracle: generate fixtures using the unchanged Flutter domain and
// the pinned fsrs 2.0.1 package. Godot tests consume these without Dart at runtime.
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:fsrs/fsrs.dart' as fsrs;
import 'package:kanayu/data/catalog.dart';
import 'package:kanayu/data/journal.dart';
import 'package:kanayu/domain/learning_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  test('generate native migration reference from original rules', () async {
    final scheduler = fsrs.Scheduler(enableFuzzing: false);
    final cases = <Map<String, dynamic>>[];
    for (var seed = 0; seed < 12; seed++) {
      var time = DateTime.utc(2026, 1, 1);
      var card = fsrs.Card(cardId: 1, due: time);
      final steps = <Map<String, dynamic>>[];
      for (var i = 0; i < 40; i++) {
        final rating = fsrs.Rating.values[(i * 7 + seed + i ~/ 4) % 4];
        time = time.add(Duration(seconds: [0, 60, 3600, 86400, 604800, 2592000][(i+seed)%6]));
        card = scheduler.reviewCard(card, rating, reviewDateTime: time).card;
        steps.add({'time': time.millisecondsSinceEpoch / 1000, 'rating': rating.value, 'card': card.toMap()});
      }
      cases.add({'steps': steps});
    }
    final catalog = await Catalog.load();
    var now = DateTime.utc(2026, 1, 1);
    final db = Journal(NativeDatabase.memory());
    final store = LearningStore(catalog, db, clock: () => now);
    await store.initialize();
    for (final k in catalog.kana) {
      await store.expose(k);
      await store.answer(k, raw:k.reading, shownAt:now, showSolution:true);
    }
    for (final days in [1, 7, 1, 1, 30]) {
      await store.endSession('test');
      now = now.add(Duration(days:days));
      for (final k in catalog.kana) {
        await store.answer(k, raw:days==1 ? 'wrong' : k.reading, shownAt:now);
      }
    }
    await store.completeLesson();
    final output = {
      'fsrs': cases,
      'journal': jsonDecode(store.exportJson()),
      'cards': store.cards.map((k,v) => MapEntry(k,v.toMap())),
      'statuses':store.statuses,
      'fsrs_config':store.fsrsConfig,
    };
    File('godot/tests/fixtures/flutter-reference.json').writeAsStringSync(jsonEncode(output));
    await db.close();
    store.dispose();
    expect(cases.length,12);
  });
}
