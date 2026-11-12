extends SceneTree
const Store = preload("res://scripts/learning/store.gd")
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=1:
		push_error("Pass one KanaYu JSON export path after --")
		quit(1)
		return
	var store := Store.new()
	if not store.initialize():
		push_error(store.error)
		quit(1)
		return
	var source = FileAccess.get_file_as_string(args[0])
	if not store.import_json(source):
		push_error(store.error)
		quit(1)
		return
	print("Imported journal: %d events, %d introduced kana, %d cards, lantern=%s" % [store.events.size(),store.introduced.size(),store.cards.size(),store.lantern_unlocked()])
	store.end_session("migration_complete")
	quit()
