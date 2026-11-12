extends SceneTree
func _initialize():
	var dir=get_script().resource_path.get_base_dir() + "/"
	var generated=Image.load_from_file(dir+"generated-interior.png")
	generated.resize(1300,2100,Image.INTERPOLATE_LANCZOS)
	generated.convert(Image.FORMAT_RGB8)
	var original=Image.load_from_file(dir+"original-entrance-patch.png")
	var mask=Image.create(1300,2100,false,Image.FORMAT_RGBA8)
	mask.fill(Color(0,0,0,0))
	var count=0
	for y in range(1500):
		for x in range(1300):
			if y>=int(700.0-float(x)*0.36):
				generated.set_pixel(x,y+600,original.get_pixel(x,y))
				mask.set_pixel(x,y+600,original.get_pixel(x,y))
				count+=1
	generated.save_png(dir+"../kigi-school-interior-menu-v6.png")
	mask.save_png(dir+"original-entrance-overlay.png")
	var saved=Image.load_from_file(dir+"../kigi-school-interior-menu-v6.png")
	for y in range(1500):
		for x in range(1300):
			if y>=int(700.0-float(x)*0.36):
				assert(saved.get_pixel(x,y+600)==original.get_pixel(x,y))
	print("PASS: ",count," original map pixels preserved exactly, unscaled; source rectangle 300,1000,1300,1500, offset 0,600")
	quit()
