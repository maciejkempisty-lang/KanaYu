extends SceneTree
func boundary(x: int) -> int:
	return int(700.0-float(x)*0.36)
func _initialize():
	var dir: String = get_script().resource_path.get_base_dir()
	var src=Image.load_from_file(dir.path_join("../../art-delivery/kigi-map-detail-v2/map-master-2560x3840.png").simplify_path())
	var patch=src.get_region(Rect2i(300,1000,1300,1500))
	var guide=Image.create(1300,2100,false,Image.FORMAT_RGB8)
	guide.fill(Color("d9c5a6"))
	for y in range(1500):
		for x in range(1300):
			if y>=boundary(x): guide.set_pixel(x,y+600,patch.get_pixel(x,y))
	guide.save_png(dir.path_join("layout-guide.png"))
	patch.save_png(dir.path_join("original-entrance-patch.png"))
	quit()
