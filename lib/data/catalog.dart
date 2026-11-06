import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

class Kana {
  /// [note] describes the shape (kana) or the meaning (words); it is shown
  /// with the item and does not help recall. [mnemonic] is the only recall
  /// hint; items without one offer no hint button.
  final String id, char, reading, note, mnemonic, audio;
  final int version;
  final bool retired;
  final List<String> accepted, strokes;
  final List<Map<String, dynamic>> variants;
  const Kana({
    required this.id,
    required this.char,
    required this.reading,
    required this.accepted,
    this.note = '',
    this.mnemonic = '',
    this.audio = '',
    this.strokes = const [],
    this.variants = const [],
    this.version = 1,
    this.retired = false,
  });
  factory Kana.fromJson(Map<String, dynamic> j) => Kana(
    id: j['id'],
    char: j['char'],
    reading: j['reading'],
    accepted: List<String>.from(j['accepted']),
    note: j['shape_note'] ?? j['meaning'] ?? '',
    mnemonic: j['mnemonic'] ?? '',
    audio: j['audio'] ?? 'audio/${j['reading']}.wav',
    strokes: List<String>.from(j['strokes'] ?? []),
    variants: (j['variants'] as List? ?? [])
        .map((v) => Map<String, dynamic>.from(v))
        .toList(),
    version: j['version'],
    retired: j['retired'] == true,
  );
}

class Catalog {
  final String version;
  final List<Kana> kana, allWords;
  const Catalog(this.version, this.kana, this.allWords);

  /// Words used in lessons. Retired words stay resolvable for old journal
  /// entries.
  List<Kana> get words => allWords.where((w) => !w.retired).toList();
  static Future<Catalog> load() async {
    final j = jsonDecode(
      await rootBundle.loadString('assets/content/hiragana.json'),
    );
    return Catalog(
      j['version'],
      (j['items'] as List).map((x) => Kana.fromJson(x)).toList(),
      (j['words'] as List).map((x) => Kana.fromJson(x)).toList(),
    );
  }

  Kana item(String id) => [...kana, ...allWords].firstWhere((x) => x.id == id);
}

String normalizeAnswer(String raw) {
  final narrow = String.fromCharCodes(
    raw.runes.map((r) => r >= 0xff01 && r <= 0xff5e ? r - 0xfee0 : r),
  );
  return unorm
      .nfc(narrow)
      .toLowerCase()
      .replaceAll(RegExp(r'\s', unicode: true), '');
}
