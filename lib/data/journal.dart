import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Immutable records are the source of truth. No FSRS snapshots are persisted.
class Journal extends GeneratedDatabase {
  Journal([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'kanayu',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.dart.js'),
              ),
            ),
      );
  @override
  int get schemaVersion => 1;
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => const [];
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement(
        'CREATE TABLE events (seq INTEGER PRIMARY KEY AUTOINCREMENT, event_id TEXT NOT NULL UNIQUE, payload TEXT NOT NULL)',
      );
    },
  );
  Future<List<Map<String, dynamic>>> readEvents() async =>
      (await customSelect('SELECT payload FROM events ORDER BY seq').get())
          .map(
            (r) =>
                jsonDecode(r.read<String>('payload')) as Map<String, dynamic>,
          )
          .toList();
  Future<void> appendAll(List<Map<String, dynamic>> events) =>
      transaction(() async {
        for (final e in events) {
          await customStatement(
            'INSERT INTO events(event_id,payload) VALUES (?,?)',
            [e['event_id'], jsonEncode(e)],
          );
        }
      });
}
