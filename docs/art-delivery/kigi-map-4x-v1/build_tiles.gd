extends SceneTree

func _initialize():
	var dest = get_script().resource_path.get_base_dir()
	var source = Image.load_from_file(dest.path_join("../../../godot/assets/village.png").simplify_path())
	source.convert(Image.FORMAT_RGBA8)
	source.resize(4096,6144,Image.INTERPOLATE_LANCZOS)
	assert(source.save_png(dest+"/map-master-4096x6144.png") == OK)
	DirAccess.make_dir_recursive_absolute(dest+"/tiles")
	var entries = []
	var scene = "[gd_scene load_steps=25 format=3]\n\n"
	for y in range(6):
		for x in range(4):
			var name = "tile_%02d_%02d.png" % [y,x]
			var left = maxi(0,x*1024-4)
			var top = maxi(0,y*1024-4)
			var right = mini(4096,(x+1)*1024+4)
			var bottom = mini(6144,(y+1)*1024+4)
			var rect = Rect2i(left,top,right-left,bottom-top)
			var tile = source.get_region(rect)
			assert(tile.save_png(dest+"/tiles/"+name) == OK)
			var check_tile = Image.load_from_file(dest+"/tiles/"+name)
			check_tile.convert(Image.FORMAT_RGBA8)
			assert(check_tile.get_data() == tile.get_data())
			entries.append({"file":"tiles/"+name,"source_rect_px":[left,top,right-left,bottom-top],"world_position":[left/4.0,top/4.0],"scale":0.25,"core_rect_px":[x*1024,y*1024,1024,1024]})
			scene += '[ext_resource type="Texture2D" path="tiles/%s" id="%d"]\n' % [name,y*4+x+1]
	scene += '\n[node name="KigiMap4x" type="Node2D"]\ntexture_filter = 2\n'
	for i in range(entries.size()):
		var e=entries[i]
		scene += '\n[node name="Tile%02d" type="Sprite2D" parent="."]\nposition = Vector2(%s, %s)\nscale = Vector2(0.25, 0.25)\ntexture = ExtResource("%d")\ncentered = false\n' % [i,str(e.world_position[0]),str(e.world_position[1]),i+1]
	FileAccess.open(dest+"/map.tscn",FileAccess.WRITE).store_string(scene)
	var manifest={"source_resolution":[1024,1536],"export_resolution":[4096,6144],"world_size":[1024,1536],"method":"Lanczos 4x interpolation of original; NOT native AI super-resolution","tile_grid":[4,6],"core_tile_size":1024,"gutter_px":4,"tiles":entries,"verification":"Every saved tile pixel-equal to master region; shared overlaps derive from same master."}
	FileAccess.open(dest+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	print("PASS: 24 tiles verified pixel-exact against 4096x6144 master; original world 1024x1536 preserved")
	quit()
