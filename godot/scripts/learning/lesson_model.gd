extends RefCounted
var store
var tasks: Array = []
var index := 0
var correct := 0
var attempted := 0
var full_lesson := false
var feedback := false
var finished := false
var entered := false
var locked := false
var shown_at := 0.0
var revealed_at = null
var attempt_id := ""
var support: Array = []
var drawing: Array = []
var response := ""
var result := {}

func _init(learning_store) -> void:
	store = learning_store

func start(items: Array = [], source: String = "lesson", writing: bool = false) -> bool:
	tasks.clear(); index = 0; correct = 0; attempted = 0; finished = false
	full_lesson = source=="lesson" and not writing and items.is_empty()
	if full_lesson:
		for offset in [0,5]:
			for i in 5: tasks.append({"id":store.catalog.kana[offset+i].id,"kind":"exposure","source":"lesson"})
			for i in [2,0,4,1,3]: tasks.append({"id":store.catalog.kana[offset+i].id,"kind":"reading","source":"lesson"})
		for k in store.catalog.words: tasks.append({"id":k.id,"kind":"word","source":"lesson"})
	else:
		for k in items: tasks.append({"id":k.id,"kind":"writing" if writing else "reading","source":source})
	if tasks.is_empty(): return false
	reset_task()
	return enter()

func task() -> Dictionary:
	return tasks[index]

func item() -> Dictionary:
	return store.catalog.by_id[task().id]

func reset_task() -> void:
	feedback = false; entered = false; locked = false; revealed_at = null
	attempt_id = ""; support = []; drawing = []; response = ""; result = {}

func enter() -> bool:
	if entered: return true
	if not store.ensure_session(): return false
	if task().kind=="exposure" and not store.expose(item()): return false
	shown_at = store.clock.call()
	entered = true
	return true

func submit(dont_know: bool = false, self_correct: bool = false) -> bool:
	if feedback or finished or not entered: return false
	var writing: bool = task().kind=="writing"
	if writing and not locked: return false
	if not writing and not dont_know and response.strip_edges().is_empty(): return false
	var options := {"source":task().source,"skill":"word_reading" if task().kind=="word" else ("kana_writing" if writing else "kana_reading"),"mode":"drawing" if writing else "text","grading":"self" if writing else "automatic","self_correct":self_correct,"dont_know":dont_know,"support":support,"prompt":["romaji_prompt"] if writing else ["char"],"show_solution":not writing,"revealed_at":revealed_at}
	if writing: options["attempt_id"] = attempt_id
	result = store.answer(item(),{"strokes":drawing,"coordinate_space":"normalized_0_1","locked_at":store.stamp(revealed_at)} if writing else response,shown_at,options)
	if result.is_empty(): return false
	var clean: bool = result.first_attempt_result=="correct" and support.is_empty()
	if task().source!="corrective":
		attempted += 1
		if clean: correct += 1
	if not clean and task().kind=="reading" and task().source!="corrective":
		tasks.insert(mini(index+3,tasks.size()),{"id":task().id,"kind":"reading","source":"corrective"})
	feedback = true
	return true

func lock_drawing() -> bool:
	if locked: return true
	var id: String = store.uid()
	var time: float = store.clock.call()
	if not store.commit_drawing(item(),id,drawing,shown_at,task().source): return false
	attempt_id = id
	revealed_at = time
	locked = true
	return true

func next() -> bool:
	if finished or not entered or (task().kind!="exposure" and not feedback): return false
	if index==tasks.size()-1:
		if full_lesson and not store.complete_lesson(): return false
		finished = true
		return true
	index += 1
	reset_task()
	return enter()
