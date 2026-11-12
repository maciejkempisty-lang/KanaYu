extends RefCounted
const Catalog = preload("res://scripts/learning/catalog.gd")
const FSRS = preload("res://scripts/learning/fsrs.gd")
var catalog := Catalog.new()
var events: Array = []
var cards: Dictionary = {}
var statuses: Dictionary = {}
var introduced: Dictionary = {}
var exposed_in: Dictionary = {}
var contact_in: Dictionary = {}
var applied_in: Dictionary = {}
var last_exposure: Dictionary = {}
var session_id = null
var last_activity = null
var disk_digest := ""
var path := "user://learning-journal.json"
var error := ""
var recovery_notice := ""
var initialized := false
var load_failed := false
var clock: Callable = func(): return Time.get_unix_time_from_system()
var fsrs_config := {"library":"fsrs","library_version":"2.0.1","algorithm":"FSRS-6","desired_retention":0.9,"enable_fuzzing":false,"learning_steps_seconds":[60,600],"relearning_steps_seconds":[600],"implementation":"godot-port/1"}

func _init(save_path: String = "user://learning-journal.json") -> void:
	path = save_path
	fsrs_config["params_hash"] = JSON.stringify(FSRS.W).sha256_text()

static func uid() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6]&15)|64
	bytes[8] = (bytes[8]&63)|128
	var value := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [value.substr(0,8),value.substr(8,4),value.substr(12,4),value.substr(16,4),value.substr(20)]

static func stamp(t: float) -> String:
	return Time.get_datetime_string_from_unix_time(int(t))+".%03dZ" % int(fmod(t,1.0)*1000)

static func seconds(value: String) -> float:
	var main := value.trim_suffix("Z").split(".")
	return float(Time.get_unix_time_from_datetime_string(main[0]))+(float("0."+main[1]) if main.size()>1 else 0.0)

func event(type: String, data: Dictionary = {}) -> Dictionary:
	var record := {"type":type,"event_id":uid(),"session_id":session_id,"timestamp":stamp(clock.call()),"tz_offset_min":Time.get_time_zone_from_system().bias,"app_version":"godot-0.3.0","content_version":catalog.version,"grading_rules_version":"grading-rules/0.2","mastery_rules_version":"mastery-rules/0.2"}
	record.merge(data.duplicate(true),true)
	return record

func _read_snapshot(file_path: String):
	if not FileAccess.file_exists(file_path): return null
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file == null or file.get_length()>64*1024*1024: return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return null
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String: return null
	if envelope.get("sha256") != envelope.payload.sha256_text(): return null
	if parser.parse(envelope.payload) != OK: return null
	var data = parser.data
	if not validate(data): return null
	return data.events

func initialize() -> bool:
	error = ""
	load_failed = false
	disk_digest = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	if FileAccess.file_exists(path):
		var loaded = _read_snapshot(path)
		if loaded == null:
			loaded = _read_snapshot(path+".bak")
			if loaded == null:
				load_failed = true
				error = "Nie można odczytać dziennika ani kopii. Zachowano pliki. Przywróć poprawny eksport."
				return false
			recovery_notice = "Przywrócono ostatnią poprawną kopię dziennika."
		events = loaded
	elif FileAccess.file_exists(path+".bak"):
		var loaded = _read_snapshot(path+".bak")
		if loaded == null:
			load_failed = true
			error = "Kopia dziennika jest nieczytelna. Zachowano plik."
			return false
		events = loaded
		recovery_notice = "Przywrócono kopię dziennika."
	replay()
	var old = null
	for e in events:
		if e.type == "session_start": old = e.session_id
	if old != null:
		var ended := false
		var last := ""
		for e in events:
			if e.get("session_id") == old:
				last = e.timestamp
				if e.type == "session_end": ended = true
		if not ended and not commit([event("session_end",{"session_id":old,"reason":"previous_process_ended","last_activity_at":last})]): return false
	initialized = ensure_session()
	return initialized

func commit(batch: Array) -> bool:
	if load_failed: return false
	var candidate := events.duplicate(true)
	candidate.append_array(batch.duplicate(true))
	if not save_events(candidate): return false
	events = candidate
	replay()
	return true

func save_events(candidate: Array) -> bool:
	error = ""
	var current_digest := FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""
	if current_digest != disk_digest:
		error = "Postęp zmienił się w innym oknie gry. Uruchom grę ponownie, aby go wczytać."
		return false
	var payload := JSON.stringify({"schema":"kanayu-journal/1","events":candidate})
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		error = "Nie udało się zapisać postępu. Spróbuj ponownie."
		return false
	file.store_string(JSON.stringify({"payload":payload,"sha256":payload.sha256_text()}))
	file.flush()
	var result := file.get_error()
	file.close()
	if result != OK or _read_snapshot(path+".tmp") == null:
		error = "Nie udało się sprawdzić zapisu. Postęp nie został zmieniony."
		return false
	# Only replace the backup with a valid primary; never overwrite good recovery data.
	if _read_snapshot(path) != null:
		if DirAccess.copy_absolute(path,path+".bak.tmp") != OK or DirAccess.rename_absolute(path+".bak.tmp",path+".bak") != OK:
			error = "Nie udało się zapisać kopii bezpieczeństwa."
			return false
	if DirAccess.rename_absolute(path+".tmp",path) != OK:
		error = "Nie udało się zatwierdzić zapisu. Spróbuj ponownie."
		return false
	disk_digest = FileAccess.get_sha256(path)
	return true

func ensure_session() -> bool:
	if load_failed: return false
	var now: float = clock.call()
	if session_id != null and last_activity != null and now-last_activity>=1800:
		if not end_session("inactivity"): return false
	if session_id == null:
		var next_id := uid()
		if not commit([event("session_start",{"session_id":next_id})]): return false
		session_id = next_id
	last_activity = now
	return true

func touch() -> void:
	if last_activity != null and clock.call()-last_activity<1800: last_activity = clock.call()

func active_session():
	return session_id if last_activity != null and clock.call()-last_activity<1800 else null

func end_session(reason: String) -> bool:
	if session_id == null: return true
	if not commit([event("session_end",{"reason":reason,"last_activity_at":stamp(last_activity)})]): return false
	session_id = null
	last_activity = null
	return true

func expose(k: Dictionary, source: String = "lesson") -> bool:
	if not ensure_session(): return false
	return commit([event("exposure",{"content_item_id":k.id,"content_item_version":k.version,"task_source":source,"prompt_shown":["char","romaji_label","stroke_animation"],"lesson_introduction":source=="lesson"})])

func shown_this_session(id: String) -> bool:
	return exposed_in.get(active_session(),{}).has(id)

func due_for(skill: String) -> Array:
	return catalog.kana.filter(func(k):
		var key: String = k.id+"|"+skill
		return cards.has(key) and cards[key].due<=clock.call() and not applied_in.get(active_session(),{}).has(key) and not shown_this_session(k.id))

func introduced_kana() -> Array:
	return catalog.kana.filter(func(k): return introduced.has(k.id))

func status(id: String, skill: String = "kana_reading") -> String:
	return statuses.get(id+"|"+skill,"Poznany" if introduced.has(id) else "Nowy")

func lantern_unlocked() -> bool:
	return events.any(func(e): return e.type=="lesson_completed")

func complete_lesson() -> bool:
	if not ensure_session(): return false
	return commit([event("lesson_completed",{"lesson_id":"first-ten","reward_id":"first-lantern"})])

func measurement_day(id: String):
	var first = null
	for e in events:
		if e.type=="exposure" and e.get("content_item_id")==id and e.get("lesson_introduction",false):
			first = seconds(e.timestamp)
			break
	if first == null: return null
	var days := int((clock.call()-first)/86400.0)
	var day := 30 if days>=30 else 7
	if days<day: return null
	for e in events:
		if e.type=="attempt" and e.get("content_item_id")==id and e.get("measurement_day")==day: return null
	return day

func measurements_due() -> Array:
	return catalog.kana.filter(func(k): return measurement_day(k.id)!=null and not contact_in.get(active_session(),{}).has(k.id))

func answer(k: Dictionary, raw, shown_at: float, options: Dictionary = {}) -> Dictionary:
	if not ensure_session(): return {}
	var source: String = options.get("source","lesson")
	var skill: String = options.get("skill","kana_reading")
	var mode: String = options.get("mode","text")
	var grading: String = options.get("grading","automatic")
	var support: Array = options.get("support",[])
	var dont_know: bool = options.get("dont_know",false)
	var normalized = Catalog.normalize(raw) if raw is String else null
	var matched = null
	for accepted in k.accepted:
		if Catalog.normalize(accepted)==normalized: matched = accepted; break
	var correct: bool = not dont_know and (options.get("self_correct",false) if grading=="self" else matched!=null)
	var assistance := support.any(func(s): return s.type!="audio_replay" or skill=="kana_reading")
	var key: String = k.id+"|"+skill
	var duplicate: bool = applied_in.get(session_id,{}).has(key)
	var exposed: bool = exposed_in.get(session_id,{}).has(k.id)
	var contacted: bool = contact_in.get(session_id,{}).has(k.id)
	var recent_exposure: bool = exposed and cards.has(key)
	var eligible := skill in ["kana_reading","kana_writing"] and mode in ["text","drawing","spoken"] and source!="corrective"
	var applied := eligible and not duplicate and not recent_exposure
	var revealed_at = options.get("revealed_at")
	var now: float = clock.call()
	var record := event("corrective" if source=="corrective" else "attempt",{
		"attempt_id":options.get("attempt_id",uid()),"content_item_id":k.id,"content_item_version":k.version,"card_key":key,"skill":skill,"task_source":source,"response_mode":mode,"grading_mode":grading,"prompt_shown":options.get("prompt",["char"]),"support_used":support,"raw_response":{"dont_know":true,"response":raw} if dont_know else raw,"normalized_response":normalized,"matched_answer":matched,"first_attempt_result":"dont_know" if dont_know else ("correct" if correct else "incorrect"),"latency_ms":clampi(int(((revealed_at if revealed_at!=null else now)-shown_at)*1000),0,2147483648),"solution_revealed_at":stamp(revealed_at) if revealed_at!=null else null,
		"fsrs_decision":{"applied":applied,"rating":("Good" if correct and not assistance else "Again") if applied else null,"reason":"not_scheduled_recall" if not eligible else ("second_attempt_in_session" if duplicate else ("recent_exposure" if recent_exposure else ("assisted_recall" if assistance else "first_recall_in_session")))},"fsrs_config":fsrs_config,"exposed_in_session":exposed,"ms_since_last_exposure":int((now-last_exposure[k.id])*1000) if last_exposure.has(k.id) else null})
	if source=="measurement":
		record["measurement_day"] = measurement_day(k.id)
		record["measurement_clean"] = not contacted
	var batch := [record]
	if options.get("show_solution",false): batch.append(solution_event(k,record.attempt_id,["char","romaji_label"]))
	return record if commit(batch) else {}

func solution_event(k: Dictionary, attempt_id: String, prompt: Array) -> Dictionary:
	return event("solution_revealed",{"attempt_id":attempt_id,"content_item_id":k.id,"content_item_version":k.version,"prompt_shown":prompt})

func commit_drawing(k: Dictionary, id: String, strokes: Array, shown_at: float, source: String) -> bool:
	if not ensure_session(): return false
	return commit([event("response_committed",{"attempt_id":id,"content_item_id":k.id,"content_item_version":k.version,"raw_response":{"strokes":strokes,"coordinate_space":"normalized_0_1"},"skill":"kana_writing","task_source":source,"response_mode":"drawing","grading_mode":"self","latency_ms":int((clock.call()-shown_at)*1000)}),solution_event(k,id,["stroke_overlay","stroke_animation","drawing_replay"])])

func replay() -> void:
	cards.clear(); statuses.clear(); introduced.clear(); exposed_in.clear(); contact_in.clear(); applied_in.clear(); last_exposure.clear()
	var correct_sessions := {}
	var previous := {}
	var failed_at := {}
	var failed_session := {}
	for e in events:
		var session = e.get("session_id")
		var item = e.get("content_item_id")
		if session == null or item == null: continue
		var time := seconds(e.timestamp)
		if not exposed_in.has(session): exposed_in[session] = {}
		if not contact_in.has(session): contact_in[session] = {}
		if not applied_in.has(session): applied_in[session] = {}
		if e.type=="exposure":
			if e.get("lesson_introduction",false): introduced[item] = true
			last_exposure[item] = time
			exposed_in[session][item] = true
			contact_in[session][item] = true
			continue
		if e.type=="corrective": contact_in[session][item] = true
		if e.type!="attempt": continue
		var exposed_before: bool = exposed_in[session].has(item)
		contact_in[session][item] = true
		var key: String = e.card_key
		if e.fsrs_decision.applied:
			cards[key] = FSRS.review(cards.get(key,{}),3 if e.fsrs_decision.rating=="Good" else 1,time)
			applied_in[session][key] = true
		var writing: bool = e.skill=="kana_writing" and e.grading_mode=="self"
		var reading: bool = e.skill=="kana_reading" and e.grading_mode=="automatic" and e.response_mode=="text"
		if (not writing and not reading) or e.response_mode not in ["text","drawing"]: continue
		var clean: bool = e.first_attempt_result=="correct" and e.support_used.is_empty()
		var mastered := "Utrwalony (samoocena)" if writing else "Utrwalony w czytaniu"
		var before = statuses.get(key)
		if not statuses.has(key): statuses[key] = "Ćwiczony"
		if clean and exposed_before: continue
		if not clean and before in [mastered,"Do odświeżenia"]:
			statuses[key] = "Do odświeżenia"
			failed_at[key] = time
			failed_session[key] = session
		elif clean:
			if not correct_sessions.has(key): correct_sessions[key] = {}
			correct_sessions[key][session] = true
			if before=="Do odświeżenia":
				if session!=failed_session[key] and time-failed_at[key]>=86400: statuses[key] = mastered
			elif correct_sessions[key].size()>=3 and previous.has(key) and time-previous[key]>=7*86400:
				statuses[key] = mastered
		previous[key] = time

func export_json() -> String:
	return JSON.stringify({"schema":"kanayu-journal/1","exported_at":stamp(clock.call()),"events":events},"  ")

func validate(data) -> bool:
	if not data is Dictionary or data.get("schema")!="kanayu-journal/1" or not data.get("events") is Array: return false
	var ids := {}
	for e in data.events:
		if not e is Dictionary: return false
		for key in ["type","event_id","timestamp"]:
			if not e.get(key) is String or e[key].is_empty(): return false
		if e.get("session_id")!=null and not e.session_id is String: return false
		if e.type in ["exposure","solution_revealed","response_committed"] and not e.get("content_item_id") is String: return false
		if ids.has(e.event_id): return false
		ids[e.event_id] = true
		if e.timestamp.length()<19 or seconds(e.timestamp)<=0: return false
		if e.get("grading_rules_version","grading-rules/0.2")!="grading-rules/0.2": return false
		if e.get("mastery_rules_version","mastery-rules/0.2")!="mastery-rules/0.2": return false
		if e.has("content_item_id") and not catalog.by_id.has(e.content_item_id): return false
		if e.type in ["attempt","corrective"]:
			for key in ["card_key","skill","grading_mode","response_mode","first_attempt_result","content_item_id"]:
				if not e.get(key) is String: return false
			if not e.get("support_used") is Array or not e.get("fsrs_decision") is Dictionary: return false
			if not e.fsrs_decision.get("applied") is bool: return false
			if e.card_key!=e.content_item_id+"|"+e.skill: return false
			if e.fsrs_decision.applied:
				if e.fsrs_decision.get("rating") not in ["Good","Again"]: return false
				if not e.get("fsrs_config") is Dictionary: return false
				var config: Dictionary = e.fsrs_config
				var learning = config.get("learning_steps_seconds")
				var relearning = config.get("relearning_steps_seconds")
				if not learning is Array or not relearning is Array: return false
				if learning.size()!=2 or relearning.size()!=1: return false
				if learning[0]!=60 or learning[1]!=600 or relearning[0]!=600: return false
				if config.get("algorithm")!="FSRS-6" or config.get("enable_fuzzing",true) or config.get("desired_retention")!=0.9 or config.get("params_hash")!=fsrs_config.params_hash: return false
	return true

func import_json(text: String) -> bool:
	var parser := JSON.new()
	var data = parser.data if parser.parse(text)==OK else null
	if not validate(data):
		error = "Plik nie jest zgodnym dziennikiem KanaYu. Nic nie zmieniono."
		return false
	var merged := events.duplicate(true)
	var known := {}
	for e in events: known[e.event_id] = e
	for e in data.events:
		if known.has(e.event_id):
			if not same_json(known[e.event_id],e):
				error = "Konflikt wpisów dziennika. Nic nie zmieniono."
				return false
		else: merged.append(e)
	# Stable tie-break keeps original attempt-before-reveal ordering at equal timestamps.
	var indexed := []
	for i in merged.size(): indexed.append({"index":i,"event":merged[i]})
	indexed.sort_custom(func(a,b): return a.index<b.index if a.event.timestamp==b.event.timestamp else seconds(a.event.timestamp)<seconds(b.event.timestamp))
	merged = indexed.map(func(x): return x.event)
	if load_failed and FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path,path+".corrupt-"+str(Time.get_ticks_usec())) != OK:
			error = "Nie udało się zabezpieczyć uszkodzonego pliku. Import przerwany."
			return false
	if not save_events(merged): return false
	load_failed = false
	initialized = true
	events = merged
	replay()
	return true

static func same_json(a, b) -> bool:
	# JSON parses all numbers as floats; compare values, not Variant array types.
	if (a is int or a is float) and (b is int or b is float): return a==b
	if typeof(a)!=typeof(b): return false
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key in a:
			if not b.has(key) or not same_json(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for i in a.size():
			if not same_json(a[i],b[i]): return false
		return true
	return a==b
