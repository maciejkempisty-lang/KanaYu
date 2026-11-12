extends RefCounted
var version: String
var kana: Array
var all_words: Array
var words: Array
var by_id: Dictionary = {}

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/content/hiragana.json"))
	version = data.version
	kana = data.items
	all_words = data.words
	words = all_words.filter(func(k): return not k.get("retired",false))
	for k in kana+all_words:
		k["note"] = k.get("shape_note",k.get("meaning",""))
		k["mnemonic"] = k.get("mnemonic","")
		k["audio"] = k.get("audio","audio/%s.wav" % k.reading)
		by_id[k.id] = k

static func normalize(raw: String) -> String:
	var narrow := ""
	for c in raw:
		var code := c.unicode_at(0)
		narrow += String.chr(code-0xfee0) if code>=0xff01 and code<=0xff5e else c
	var canonical: String = preload("res://scripts/learning/unicode_nfc.gd").normalize(narrow).to_lower()
	var result := ""
	for c in canonical:
		var code := c.unicode_at(0)
		if code in [9,10,11,12,13,32,160,5760,8232,8233,8239,8287,12288,65279] or (code>=8192 and code<=8202): continue
		result += c
	return result
