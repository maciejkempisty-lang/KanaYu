extends SceneTree

const W=2560
const H=3840
const TW=800
const TH=1440
const OVER=160
var folder: String

func color_cost(a: Color,b: Color) -> float:
	return pow(a.r-b.r,2)+pow(a.g-b.g,2)+pow(a.b-b.b,2)

# Minimum-error paths keep the transition on similar pixels instead of
# blurring the entire overlap. Only a narrow 8-pixel seam is feathered.
func seam(canvas: Image,tile: Image,origin: Vector2i,vertical: bool) -> PackedInt32Array:
	var length=TH if vertical else TW
	var prev=PackedFloat64Array()
	prev.resize(OVER)
	var back=PackedInt32Array()
	back.resize(length*OVER)
	for step in range(length):
		var curr=PackedFloat64Array()
		curr.resize(OVER)
		for cross in range(OVER):
			var local=Vector2i(cross,step) if vertical else Vector2i(step,cross)
			var pos=origin+local
			var cost=0.0
			if pos.x>=0 and pos.y>=0 and pos.x<W and pos.y<H:
				cost=color_cost(canvas.get_pixelv(pos),tile.get_pixelv(local))
			cost+=0.002*pow((cross-80.0)/80.0,2)
			if cross<8 or cross>=OVER-8: cost+=1000
			var chosen=cross
			if step>0:
				for k in range(maxi(0,cross-1),mini(OVER,cross+2)):
					if prev[k]<prev[chosen]: chosen=k
				cost+=prev[chosen]
			curr[cross]=cost
			back[step*OVER+cross]=chosen
		prev=curr
	var best=0
	for x in range(OVER):
		if prev[x]<prev[best]: best=x
	var result=PackedInt32Array()
	result.resize(length)
	for step in range(length-1,-1,-1):
		result[step]=best
		best=back[step*OVER+best]
	return result

func _initialize():
	folder=get_script().resource_path.get_base_dir()
	var canvas=Image.create(W,H,false,Image.FORMAT_RGB8)
	var provenance=[]
	for row in range(3):
		for col in range(4):
			var path="generated/tile_%d_%d.png"%[row,col]
			var tile=Image.load_from_file(folder.path_join(path))
			assert(tile!=null)
			provenance.append({"file":path,"native_size":[tile.get_width(),tile.get_height()],"reference_rect_world":[col*256-32,row*512-32,320,576]})
			# Downsample individually generated high-detail art to a common density.
			tile.resize(TW,TH,Image.INTERPOLATE_LANCZOS)
			var origin=Vector2i(col*640-80,row*1280-80)
			var vs=seam(canvas,tile,origin,true) if col>0 else PackedInt32Array()
			var hs=seam(canvas,tile,origin,false) if row>0 else PackedInt32Array()
			for y in range(TH):
				var gy=y+origin.y
				if gy<0 or gy>=H: continue
				for x in range(TW):
					var gx=x+origin.x
					if gx<0 or gx>=W: continue
					var weight=1.0
					if col>0 and x<OVER: weight=minf(weight,smoothstep(-4,4,float(x-vs[y])))
					if row>0 and y<OVER: weight=minf(weight,smoothstep(-4,4,float(y-hs[x])))
					if weight>0:
						canvas.set_pixel(gx,gy,canvas.get_pixel(gx,gy).lerp(tile.get_pixel(x,y),weight))
			print("Assembled ",row,"/",col)
	assert(canvas.save_png(folder+"/map-master-2560x3840.png")==OK)
	var preview=canvas.duplicate()
	preview.resize(1024,1536,Image.INTERPOLATE_LANCZOS)
	preview.save_png(folder+"/map-preview.png")
	DirAccess.make_dir_recursive_absolute(folder+"/tiles")
	var entries=[]
	var scene="[gd_scene load_steps=13 format=3]\n\n"
	var reconstructed=Image.create(W,H,false,Image.FORMAT_RGB8)
	for row in range(3):
		for col in range(4):
			var left=maxi(0,col*640-4)
			var top=maxi(0,row*1280-4)
			var right=mini(W,(col+1)*640+4)
			var bottom=mini(H,(row+1)*1280+4)
			var rect=Rect2i(left,top,right-left,bottom-top)
			var tile=canvas.get_region(rect)
			var path="tiles/tile_%d_%d.png"%[row,col]
			assert(tile.save_png(folder+"/"+path)==OK)
			var readback=Image.load_from_file(folder+"/"+path)
			readback.convert(Image.FORMAT_RGB8)
			assert(readback.get_data()==tile.get_data())
			reconstructed.blit_rect(readback,Rect2i(col*640-left,row*1280-top,640,1280),Vector2i(col*640,row*1280))
			entries.append({"file":path,"source_rect_px":[left,top,right-left,bottom-top],"world_position":[left/2.5,top/2.5],"scale":0.4,"core_rect_px":[col*640,row*1280,640,1280]})
			scene+='[ext_resource type="Texture2D" path="%s" id="%d"]\n'%[path,row*4+col+1]
	assert(reconstructed.get_data()==canvas.get_data())
	scene+='\n[node name="KigiDetailedMap" type="Node2D"]\ntexture_filter = 2\n'
	for i in range(entries.size()):
		var e=entries[i]
		scene+='\n[node name="Tile%02d" type="Sprite2D" parent="."]\nposition = Vector2(%s, %s)\nscale = Vector2(0.4, 0.4)\ntexture = ExtResource("%d")\ncentered = false\n'%[i,str(e.world_position[0]),str(e.world_position[1]),i+1]
	FileAccess.open(folder+"/map.tscn",FileAccess.WRITE).store_string(scene)
	var manifest={"world_size":[1024,1536],"master_size":[W,H],"density":2.5,"method":"12 independently generated detailed image edits, downsampled to common density, minimum-error overlap seam assembly, then shared-master tile export","generation_overlap_world":64,"runtime_gutter_px":4,"generated_sources":provenance,"tiles":entries,"checks":{"saved_tiles_match_master":true,"reassembled_cores_equal_master":true},"geometry":"Generative reinterpretation; check collision and foreground masks before deployment."}
	FileAccess.open(folder+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"\t"))
	# Close camera crops at native output density; no enlargement.
	canvas.get_region(Rect2i(650,2690,700,1000)).save_png(folder+"/detail-postbox.png")
	canvas.get_region(Rect2i(680,1240,700,1000)).save_png(folder+"/detail-school.png")
	canvas.get_region(Rect2i(1430,1840,700,1000)).save_png(folder+"/detail-bridge.png")
	# Compare the same postbox crop at identical display scale.
	var original=Image.load_from_file(folder+"/../../../godot/assets/village.png")
	if original!=null:
		original.resize(W,H,Image.INTERPOLATE_LANCZOS)
		var comparison=Image.create(1400,1000,false,Image.FORMAT_RGB8)
		comparison.blit_rect(original,Rect2i(650,2690,700,1000),Vector2i.ZERO)
		comparison.blit_rect(canvas,Rect2i(650,2690,700,1000),Vector2i(700,0))
		comparison.save_png(folder+"/comparison-old-left-new-right.png")
	print("PASS: 12 final tiles reconstruct master exactly, 2560x3840, world scale unchanged")
	quit()
