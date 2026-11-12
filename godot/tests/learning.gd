extends SceneTree
const Store = preload("res://scripts/learning/store.gd")
const Model = preload("res://scripts/learning/lesson_model.gd")
const FSRS = preload("res://scripts/learning/fsrs.gd")
var failures := 0
var now := 1767225600.0
var prefix := "/private/tmp/kigi-learning-%d" % Time.get_ticks_usec()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func fresh(suffix: String):
	var store := Store.new(prefix+suffix+".json")
	store.clock = func(): return now
	check(store.initialize(),"Initialize "+suffix+": "+store.error)
	return store

func next_session(store, elapsed: float) -> void:
	check(store.end_session("test"),"End session")
	now += elapsed
	check(store.ensure_session(),"New session")

func compare_card(actual: Dictionary, expected: Dictionary, context: String) -> void:
	for key in ["state","step"]: check(actual[key]==expected[key],context+" "+key)
	for key in ["stability","difficulty"]: check(absf(actual[key]-expected[key])<0.0000001,context+" "+key)
	check(absf(actual.due-Store.seconds(expected.due))<0.001,context+" due")
	check(absf(actual.last_review-Store.seconds(expected.lastReview))<0.001,context+" lastReview")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/flutter-reference.json"))
	for case in fixture.fsrs:
		var card := {}
		for step in case.steps:
			card = FSRS.review(card,int(step.rating),step.time)
			compare_card(card,step.card,"FSRS oracle")
	var store = fresh("-rules")
	check(store.fsrs_config.params_hash==fixture.fsrs_config.params_hash,"Original parameter hash")
	check(Store.Catalog.normalize(" Ｋ Ａ\n")=="ka","Fullwidth normalization")
	check(Store.Catalog.normalize("ō")=="ō","Canonical normalization")
	check(Store.Catalog.normalize("A\ufeff")=="a","BOM whitespace normalization")
	check(Store.Catalog.normalize("o \u0304")=="o\u0304","Original NFC-before-whitespace order")
	check(Store.Catalog.normalize("oo")!=Store.Catalog.normalize("o"),"Long vowels preserved")
	var k: Dictionary = store.catalog.kana[0]
	check(store.expose(k),"Exposure saved")
	check(store.cards.is_empty(),"Exposure is not a review")
	var e: Dictionary = store.answer(k,"wrong",now,{"show_solution":true})
	check(e.fsrs_decision.rating=="Again","Wrong => Again")
	check(store.events[-1].type=="solution_revealed" and store.events[-1].attempt_id==e.attempt_id,"Atomic answer/reveal")
	var before: Dictionary = store.cards.duplicate(true)
	e = store.answer(k,"a",now)
	check(not e.fsrs_decision.applied,"Duplicate session excluded")
	e = store.answer(k,"a",now,{"source":"corrective"})
	check(e.type=="corrective" and not e.fsrs_decision.applied and store.cards==before,"Correction does not schedule")
	next_session(store,86400)
	store.expose(k,"minigame")
	e = store.answer(k,"a",now)
	check(e.fsrs_decision.reason=="recent_exposure" and not e.fsrs_decision.applied,"Previously seen excluded")
	check(store.due_for("kana_reading").is_empty(),"Exposed review excluded from due queue")
	next_session(store,86400)
	var support := [{"type":"mnemonic"}]
	e = store.answer(k,"a",now,{"support":support})
	support.clear()
	check(e.fsrs_decision.rating=="Again" and store.events[-1].support_used.size()==1,"Assisted correct and immutable evidence")
	store = fresh("-mastery")
	store.answer(k,"a",now)
	next_session(store,86400)
	store.answer(k,"a",now)
	next_session(store,7*86400)
	store.answer(k,"a",now)
	check(store.status(k.id)=="Utrwalony w czytaniu","Three sessions final 7-day gap")
	next_session(store,86400)
	store.expose(k,"minigame")
	store.answer(k,"wrong",now)
	check(store.status(k.id)=="Do odświeżenia","Failure after exposure still marks refresh")
	next_session(store,3600)
	store.answer(k,"a",now)
	check(store.status(k.id)=="Do odświeżenia","One hour cannot restore mastery")
	next_session(store,86400)
	store.answer(k,"a",now)
	check(store.status(k.id)=="Utrwalony w czytaniu","One day restores mastery")
	var session: String = store.session_id
	now += 29*60
	store.ensure_session()
	check(store.session_id==session,"29 minutes same session")
	now += 30*60
	store.ensure_session()
	check(store.session_id!=session,"30 minutes new session")
	store = fresh("-writing")
	var drawing := [[[0.1,0.2,0],[0.3,0.4,100]]]
	check(store.commit_drawing(k,"d1",drawing,now,"minigame"),"Commit drawing")
	check(store.cards.is_empty() and store.events[-2].type=="response_committed","Drawing before reveal, no rating")
	store.answer(k,{"strokes":drawing},now,{"skill":"kana_writing","mode":"drawing","grading":"self","self_correct":true,"attempt_id":"d1"})
	drawing.clear()
	check(store.events[-1].raw_response.strokes.size()==1,"Drawing deep copy")
	check(store.cards.has(k.id+"|kana_writing") and not store.cards.has(k.id+"|kana_reading"),"Separate writing card")
	next_session(store,30*86400)
	check(store.due_for("kana_writing").size()==1 and store.due_for("kana_reading").is_empty(),"Separate writing due queue")
	store.answer(store.catalog.words[0],"iie",now,{"skill":"word_reading"})
	check(store.cards.size()==1,"Word does not schedule kana")
	store = fresh("-measurement")
	store.expose(k)
	next_session(store,7*86400)
	check(store.measurement_day(k.id)==7 and store.measurements_due().size()==1,"Day 7 measurement")
	e = store.answer(k,"a",now,{"source":"measurement"})
	check(e.measurement_clean and e.measurement_day==7 and e.fsrs_decision.applied,"Clean measurement scheduled")
	next_session(store,23*86400)
	check(store.measurement_day(k.id)==30,"Day 30 replaces day 7")
	store.answer(k,"a",now,{"source":"minigame"})
	check(store.measurements_due().is_empty(),"Earlier contact excludes measurement")
	store = fresh("-lesson")
	var model := Model.new(store)
	check(model.start(),"Start lesson")
	check(model.tasks.size()==23,"23 original learning units")
	check(model.tasks[5].id==store.catalog.kana[2].id and model.tasks[15].id==store.catalog.kana[7].id,"Original reading order")
	var guard := 0
	while not model.finished and guard<100:
		guard += 1
		if model.task().kind!="exposure":
			model.response = "wrong"
			check(model.submit(true),"Dont-know accepted")
			check(not model.submit(true),"Double submit blocked")
		check(model.next(),"Advance after saved feedback")
	check(model.finished and store.lantern_unlocked(),"Lesson completable with all errors")
	check(model.attempted==13 and model.tasks.size()==33,"13 attempts + 10 delayed corrections")
	check(store.cards.size()==10,"Only ten reading cards")
	var state: Dictionary = store.cards.duplicate(true)
	var reopened := Store.new(store.path)
	reopened.clock = func(): return now
	check(reopened.initialize(),"Reopen journal")
	check(reopened.cards==state and reopened.lantern_unlocked(),"Replay restores exact state and reward")
	check(reopened.events.any(func(x): return x.type=="session_end" and x.get("reason")=="previous_process_ended"),"Killed session closed at restart")
	var imported = fresh("-import")
	check(imported.import_json(JSON.stringify(fixture.journal)),"Flutter journal import: "+imported.error)
	for key in fixture.cards: compare_card(imported.cards[key],fixture.cards[key],"Imported "+key)
	check(imported.statuses==fixture.statuses and imported.lantern_unlocked(),"Imported mastery/reward")
	var count: int = imported.events.size()
	check(imported.import_json(JSON.stringify(fixture.journal)) and imported.events.size()==count,"Idempotent import")
	check(not imported.import_json('{"schema":"bad"}') and imported.events.size()==count,"Invalid import unchanged")
	var native_export: String = imported.export_json()
	check(imported.import_json(native_export) and imported.events.size()==count,"Native export reimport tolerates JSON numeric representation")
	# A write failure must not reveal an answer or mutate live evidence.
	store = fresh("-write-failure")
	var evidence: Array = store.events.duplicate(true)
	store.path = prefix+"-missing/never.json"
	check(store.answer(k,"a",now,{"show_solution":true}).is_empty(),"Save failure returned")
	check(store.events==evidence and store.cards.is_empty(),"Save failure cannot advance state")
	# Recovery keeps the last valid backup, including when primary JSON is corrupt.
	store = fresh("-recovery")
	store.expose(k)
	store.answer(k,"a",now)
	var corrupt := FileAccess.open(store.path,FileAccess.WRITE)
	corrupt.store_string("broken"); corrupt.close()
	reopened = Store.new(store.path)
	reopened.clock = func(): return now
	check(reopened.initialize() and not reopened.recovery_notice.is_empty(),"Corrupt primary recovers backup")
	check(reopened.introduced.has(k.id),"Recovery preserves prior durable exposure")
	store = fresh("-concurrent")
	var other := Store.new(store.path)
	other.clock = func(): return now
	check(other.initialize(),"Second window opens")
	check(not store.expose(k),"Stale window cannot overwrite newer evidence")
	store = fresh("-double-corrupt")
	store.expose(k)
	for file_path in [store.path,store.path+".bak"]:
		var file := FileAccess.open(file_path,FileAccess.WRITE)
		file.store_string("broken"); file.close()
	var broken := Store.new(store.path)
	check(not broken.initialize(),"Double corruption is reported")
	check(not broken.expose(k) and FileAccess.get_file_as_string(store.path)=="broken","Corrupt journal never silently replaced")
	check(broken.import_json(JSON.stringify(fixture.journal)),"Explicit import can restore corrupt journal")
	check(broken.lantern_unlocked(),"Restored reward")
	print("NATIVE LEARNING: ","PASS (480 FSRS oracle reviews + domain, lesson, persistence, import checks)" if failures==0 else "FAIL %d" % failures)
	quit(failures)
