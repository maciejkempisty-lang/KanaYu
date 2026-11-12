extends RefCounted
## Unicode canonical decomposition, ordering and composition (including Hangul).
static var tables: Dictionary = {}

static func decompose(code: int, output: Array) -> void:
	if code>=0xac00 and code<0xac00+11172:
		var index := code-0xac00
		output.append(0x1100+int(index/588))
		output.append(0x1161+int((index%588)/28))
		if index%28!=0: output.append(0x11a7+index%28)
	elif tables.decomposition.has(str(code)):
		for part in tables.decomposition[str(code)]: decompose(int(part),output)
	else: output.append(code)

static func combine(a: int,b: int) -> int:
	if a>=0x1100 and a<0x1100+19 and b>=0x1161 and b<0x1161+21:
		return 0xac00+((a-0x1100)*21+b-0x1161)*28
	if a>=0xac00 and a<0xac00+11172 and (a-0xac00)%28==0 and b>0x11a7 and b<0x11a7+28:
		return a+b-0x11a7
	return int(tables.composition.get("%d,%d" % [a,b],-1))

static func normalize(value: String) -> String:
	if tables.is_empty(): tables = JSON.parse_string(FileAccess.get_file_as_string("res://assets/content/unicode-nfc.json"))
	var decomposed: Array = []
	for c in value: decompose(c.unicode_at(0),decomposed)
	for i in range(1,decomposed.size()):
		var j := i
		var rank := int(tables.combining.get(str(decomposed[j]),0))
		if rank==0: continue
		while j>0 and int(tables.combining.get(str(decomposed[j-1]),0))>rank:
			var old = decomposed[j-1]
			decomposed[j-1] = decomposed[j]
			decomposed[j] = old
			j -= 1
	if decomposed.is_empty(): return ""
	var composed: Array = [decomposed[0]]
	var starter := 0
	var last_rank := 0
	for i in range(1,decomposed.size()):
		var code := int(decomposed[i])
		var rank := int(tables.combining.get(str(code),0))
		var combination := combine(int(composed[starter]),code)
		if combination!=-1 and (last_rank<rank or last_rank==0): composed[starter] = combination
		else:
			if rank==0: starter = composed.size()
			composed.append(code)
			last_rank = rank
	var result := ""
	for c in composed: result += String.chr(int(c))
	return result
