extends MultiMeshShape
class_name TileGrid

## for animation
var tile_rotation_x :float:
	set(rad):
		for i in calc_grid.get_grid_count():
			set_inst_rotation(i, Vector3.RIGHT, rad)

var tile_rotation_y :float:
	set(rad):
		for i in calc_grid.get_grid_count():
			set_inst_rotation(i, Vector3.UP, rad)

var tile_rotation_z :float:
	set(rad):
		for i in calc_grid.get_grid_count():
			set_inst_rotation(i, Vector3.FORWARD, rad)

func make_ani_tile_rotate(aniname :String, axis :int, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(
		aniname, self,
		["tile_rotation_x", "tile_rotation_y", "tile_rotation_z"][axis],
		from , to, dur_sec
	)

func make_ani_tile_rotate_x(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "tile_rotation_x", from , to, dur_sec)

func make_ani_tile_rotate_y(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "tile_rotation_y", from , to, dur_sec)

func make_ani_tile_rotate_z(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "tile_rotation_z", from , to, dur_sec)

var calc_grid :CalcGrid3D
var pos_list :Array

func get_index_by_xy(x :int, y :int) -> int:
	return calc_grid.get_index_by_posi_xyz(x,y)

func set_tile_color_all(color_list :Array[Color]) -> void:
	for i in get_visible_count():
		multimesh.set_instance_color(i,color_list[i%color_list.size()])

func set_tile_color_8way(color_list :Array[Color], way :int) -> void:
	match way % 8:
		0:
			set_tile_color_x(color_list, false)
		1:
			set_tile_color_xy(color_list, false, false)
		2:
			set_tile_color_y(color_list, false)
		3:
			set_tile_color_xy(color_list, true, false)
		4:
			set_tile_color_x(color_list, true)
		5:
			set_tile_color_xy(color_list, true, true)
		6:
			set_tile_color_y(color_list, true)
		7:
			set_tile_color_xy(color_list, false, true)

func set_tile_color_x(color_list :Array[Color], reverse :bool=false) -> void:
	for x in calc_grid.grid_size.x:
		for y in calc_grid.grid_size.y:
			var effx := x
			if reverse:
				effx = calc_grid.grid_size.x-x-1
			var i := calc_grid.get_index_by_posi_xyz(effx,y)
			multimesh.set_instance_color(i, color_list[x % color_list.size()])

func set_tile_color_y(color_list :Array[Color], reverse :bool=false) -> void:
	for x in calc_grid.grid_size.x:
		for y in calc_grid.grid_size.y:
			var effy := y
			if reverse:
				effy = calc_grid.grid_size.y-y-1
			var i := calc_grid.get_index_by_posi_xyz(x,effy)
			multimesh.set_instance_color(i, color_list[y % color_list.size()])

func set_tile_color_xy(color_list :Array[Color], reverse_x :bool=false, reverse_y :bool=false) -> void:
	for x in calc_grid.grid_size.x:
		for y in calc_grid.grid_size.y:
			var effx := x
			if reverse_x:
				effx = calc_grid.grid_size.x-x-1
			var effy := y
			if reverse_y:
				effy = calc_grid.grid_size.y-y-1
			var i := calc_grid.get_index_by_posi_xyz(effx,effy)
			multimesh.set_instance_color(i, color_list[ (x+y) % color_list.size() ])


func init_tile_grid_with_box(sz :Vector3, grid_count :Vector2i, gap_rate :float, co :Color) -> TileGrid:
	var calc_grid_a := CalcGrid3D.new(
		CalcGrid3D.SizeToAABB(sz),
		CalcGrid3D.xy_Vector2iToVector3i(grid_count,1),
	)
	var mesh := BoxMesh.new()
	mesh.size = calc_grid_a.unit_size *gap_rate
	mesh.material = make_color_material(co.a)
	init_tile_grid_with_mesh(mesh, calc_grid_a, co)
	return self

func init_tile_grid_with_plane(sz :Vector3, grid_count :Vector2i, gap_rate :float, co :Color) -> TileGrid:
	var calc_grid_a := CalcGrid3D.new(
		CalcGrid3D.SizeToAABB(sz),
		CalcGrid3D.xy_Vector2iToVector3i(grid_count,1),
	)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(calc_grid_a.unit_size.x,calc_grid_a.unit_size.y) *gap_rate
	mesh.material = make_color_material(co.a)
	init_tile_grid_with_mesh(mesh, calc_grid_a, co)
	return self

func init_tile_grid_with_sphere(sz :Vector3, grid_count :Vector2i, gap_rate :float, co :Color) -> TileGrid:
	var calc_grid_a := CalcGrid3D.new(
		CalcGrid3D.SizeToAABB(sz),
		CalcGrid3D.xy_Vector2iToVector3i(grid_count,1),
	)
	var mesh := SphereMesh.new()
	mesh.radius = calc_grid_a.unit_size.x *gap_rate /2
	mesh.height = calc_grid_a.unit_size.y *gap_rate
	mesh.material = make_color_material(co.a)
	init_tile_grid_with_mesh(mesh, calc_grid_a, co)
	return self

func init_tile_grid_with_mesh(mesh :Mesh, calc_grid_a :CalcGrid3D, co :Color) -> TileGrid:
	calc_grid = calc_grid_a
	pos_list = []
	for i in calc_grid.get_grid_count():
		pos_list.append(calc_grid.get_n_th_lanepos(i))
	init_with_color_mesh(mesh, pos_list.size(), false)
	set_color_all(co)
	for i in pos_list.size():
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos_list[i]))
	return self
