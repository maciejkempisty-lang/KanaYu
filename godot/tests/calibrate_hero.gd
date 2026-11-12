extends SceneTree
# Asset inspection only: derives constant pivots from alpha bounds, leaves PNGs intact.
func _initialize() -> void:
	var metrics := {}
	var source := "res://assets/hero/v2/"
	for direction in ["right","southeast","down","southwest","left","northwest","up","northeast"]:
		for state in ["idle","walk"]:
			var name: String = state+"_"+direction
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source+name+".json"))
			var sheet := Image.load_from_file(source+name+".png")
			var heights := []; var feet := []; var centers := []
			for frame in data.frames.values():
				var rect := sheet.get_region(Rect2i(frame.x,frame.y,frame.w,frame.h)).get_used_rect()
				heights.append(rect.size.y); feet.append(rect.end.y); centers.append(rect.position.x+rect.size.x/2.0)
			heights.sort(); feet.sort(); centers.sort()
			metrics[name] = {"height":heights[12],"feet_y":feet[12],"center_x":centers[12]}
	var file := FileAccess.open(source+"metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"  "))
	print("CALIBRATED 16 ATLAS PIVOTS: ",metrics)
	quit()
