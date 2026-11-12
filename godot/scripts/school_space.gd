extends RefCounted
var data: Dictionary
var scale_factor: float
var size: Vector2
var floor: PackedVector2Array
var obstacles: Array[PackedVector2Array]=[]
var stations: Array[Dictionary]=[]
func _init(source: String = "res://assets/school/layout.json") -> void:
	data=preload("res://scripts/editor/scene_layout_data.gd").load_layout(source)
	scale_factor=data.world_units_per_pixel
	size=point(data.source_size)
	floor=polygon(data.floor)
	for item in data.obstacles: obstacles.append(polygon(item.polygon))
	for item in data.stations:
		stations.append({"id":item.id,"name":item.name,"point":point(item.point),"radius":float(item.radius_world)})
func point(p: Array) -> Vector2: return Vector2(p[0],p[1])*scale_factor
func polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points: result.append(point(p))
	return result
func can_stand(p: Vector2) -> bool:
	for offset in [Vector2.ZERO,Vector2(-5,0),Vector2(5,0),Vector2(0,-3),Vector2(0,3)]:
		var q: Vector2=p+offset
		if not Geometry2D.is_point_in_polygon(q,floor): return false
		for obstacle in obstacles:
			if Geometry2D.is_point_in_polygon(q,obstacle): return false
	return true
func move(start: Vector2, displacement: Vector2) -> Vector2:
	var p := start
	var steps := maxi(1,ceili(displacement.length()/2))
	var step := displacement/steps
	for i in steps:
		if can_stand(p+step): p+=step
		elif can_stand(p+Vector2(step.x,0)): p.x+=step.x
		elif can_stand(p+Vector2(0,step.y)): p.y+=step.y
	return p
func station_at(p: Vector2) -> String:
	var result := ""
	var nearest := INF
	for station in stations:
		var distance: float=p.distance_to(station.point)
		if distance<station.radius and distance<nearest: result=station.id; nearest=distance
	return result

func nearest_walkable(p: Vector2) -> Vector2:
	if can_stand(p): return p
	var best:=point(data.spawn)
	var distance:=p.distance_squared_to(best)
	var bounds:=Rect2(floor[0],Vector2.ZERO)
	for q in floor: bounds=bounds.expand(q)
	for y in range(int(bounds.position.y),int(bounds.end.y)+1,2):
		for x in range(int(bounds.position.x),int(bounds.end.x)+1,2):
			var q:=Vector2(x,y)
			if q.distance_squared_to(p)<distance and can_stand(q): best=q; distance=q.distance_squared_to(p)
	return best
