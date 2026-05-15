extends MultiMeshShape
class_name Plot3D

static func MakeCalcGrid(total_size :Vector3, cell_count :Vector3i) -> CalcGrid3D:
	return CalcGrid3D.new(
		CalcGrid3D.SizeToAABB(total_size),
		cell_count,
	)

var calc_grid :CalcGrid3D
## posi to instance index
var plotted :Dictionary[Vector3i,int] = {}

func init_plot3d_by_texture2d_face_z(total_size: Vector3, texture2d :Texture2D, cell_scale :float = 1.0) -> Plot3D:
	var image := texture2d.get_image()
	if image.is_compressed():
		image.decompress()
	var image_size := image.get_size()
	var cell_count := Vector3i(image_size.x, image_size.y, 1)
	var image_scale :float = min(total_size.x/image_size.x, total_size.y/image_size.y)
	var prop_size := Vector3(image_size.x*image_scale, image_size.y*image_scale, total_size.z)
	init_plot3d_box(prop_size, cell_count, cell_scale, true)
	draw_texture2d_face_z(Vector3i.ZERO, texture2d)
	return self

func init_plot3d_box(total_size: Vector3, cell_count :Vector3i, cell_scale :float = 1.0, transparent :bool = false) -> Plot3D:
	var cg = MakeCalcGrid(total_size, cell_count)
	var mesh := BoxMesh.new()
	mesh.size = cg.unit_size * cell_scale
	mesh.material = MultiMeshShape.MakeMultiMeshColorMaterial(transparent)
	return init_plot3d_mesh_calcgrid(mesh, cg)

func init_plot3d_plane(total_size: Vector3, cell_count :Vector3i, cell_scale :float = 1.0, transparent :bool = false) -> Plot3D:
	var cg = MakeCalcGrid(total_size, cell_count)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(cg.unit_size.x,cg.unit_size.y) *cell_scale
	mesh.material = MakeMultiMeshColorMaterial(transparent)
	return init_plot3d_mesh_calcgrid(mesh, cg)

func init_plot3d_cylinder(total_size: Vector3, cell_count :Vector3i, cell_scale :float = 1.0, radial_segments :int = 64, transparent :bool = false) -> Plot3D:
	var cg = MakeCalcGrid(total_size, cell_count)
	var mesh := CylinderMesh.new()
	var v2 := Vector2(cg.unit_size.x, cg.unit_size.y)
	mesh.top_radius = v2.length() / 2 * cell_scale
	mesh.bottom_radius = v2.length() / 2 * cell_scale
	mesh.height = cg.unit_size.z
	mesh.radial_segments = radial_segments
	mesh.material = MakeMultiMeshColorMaterial(transparent)
	return init_plot3d_mesh_calcgrid(mesh, cg)

func init_plot3d_sphere(total_size: Vector3, cell_count :Vector3i, cell_scale :float = 1.0, transparent :bool = false) -> Plot3D:
	var cg = MakeCalcGrid(total_size, cell_count)
	var mesh := SphereMesh.new()
	mesh.radius = cg.unit_size.x *cell_scale /2
	mesh.height = cg.unit_size.y *cell_scale
	mesh.radial_segments = 4
	mesh.rings = 1
	mesh.material = MakeMultiMeshColorMaterial(transparent)
	return init_plot3d_mesh_calcgrid(mesh, cg)

func init_plot3d_mesh_calcgrid(mesh :Mesh, cg :CalcGrid3D) -> Plot3D:
	calc_grid = cg
	init_with_color_mesh(mesh, calc_grid.get_grid_count(), false)
	set_visible_count(0)
	return self

func clear() -> void:
	set_visible_count(0)
	plotted.clear()

func fill_all(co :Color) -> Plot3D:
	for i in calc_grid.get_grid_count():
		var posi := calc_grid.get_n_th_posi(i)
		plot_at(posi, co)
	return self

func plot_at(posi :Vector3i, co :Color) -> void:
	if co.a <= 0.0 :
		return
	var pos := calc_grid.posi_to_lanepos(posi)
	var index := plotted.size()
	if plotted.has(posi):
		index = plotted[posi]
	plotted[posi] = index
	var t := Transform3D(Basis(), pos)
	multimesh.set_instance_transform(index,t)
	multimesh.set_instance_color(index, co)
	set_visible_count(plotted.size())

## return success or fail
func del_at(posi :Vector3i) -> bool:
	if not plotted.has(posi):
		return false
	var todel_index := plotted[posi]
	plotted.erase(posi)
	set_visible_count(plotted.size())
	if plotted.size() == 0:
		return true
	var last_index := plotted.size()
	copy_instance(last_index, todel_index)
	return true

func copy_instance(from:int, to:int) -> void:
	var from_tr := multimesh.get_instance_transform(from)
	multimesh.set_instance_transform(to, from_tr)
	var from_co := multimesh.get_instance_color(from)
	multimesh.set_instance_color(to, from_co)

## include x2
func draw_x_line(x1 :int, x2 :int, y :int, z :int, co :Color):
	if x1 > x2 :
		var t := x1
		x1 = x2
		x2 = t
	for x in range(x1,x2+1):
		plot_at(Vector3i(x,y,z), co)

## include y2
func draw_y_line(x :int, y1 :int, y2 :int, z :int, co :Color):
	if y1 > y2 :
		var t := y1
		y1 = y2
		y2 = t
	for y in range(y1,y2+1):
		plot_at(Vector3i(x,y,z), co)

## include z2
func draw_z_line(x :int, y :int, z1 :int, z2 :int, co :Color):
	if z1 > z2 :
		var t := z1
		z1 = z2
		z2 = t
	for z in range(z1,z2+1):
		plot_at(Vector3i(x,y,z), co)

func draw_wave(now :float, period :Vector2 = Vector2.ONE) -> void:
	var wavelen := Vector2.ONE * 2*PI / period
	for xi in calc_grid.grid_size.x:
		for zi in calc_grid.grid_size.z:
			var xrate :float= calc_grid.rate_xi(xi)
			var zrate :float= calc_grid.rate_yi(zi)
			var yrate :=  ( sin( xrate*wavelen.x +now) + cos( zrate*wavelen.y +now) ) / 4 + 0.5
			var posi := Vector3i(xi, calc_grid.yi_by_rate(yrate) , zi)
			var co := Color(xrate,yrate,zrate)
			plot_at(posi, co)

func draw_texture2d_face_z(posi :Vector3i, texture2d :Texture2D) -> void:
	var image := texture2d.get_image()
	if image.is_compressed():
		image.decompress()
	var image_size := image.get_size()
	for xi in image_size.x:
		for yi in image_size.y:
			var co :Color = image.get_pixel(xi,yi)
			plot_at(Vector3i(xi,image_size.y-yi-1,0) + posi ,co)

func draw_texture2d_face_y(posi :Vector3i, texture2d :Texture2D) -> void:
	var image := texture2d.get_image()
	if image.is_compressed():
		image.decompress()
	var image_size := image.get_size()
	for xi in image_size.x:
		for yi in image_size.y:
			var co :Color = image.get_pixel(xi,yi)
			plot_at(Vector3i(xi,0,image_size.y-yi-1) + posi ,co)

func draw_texture2d_face_x(posi :Vector3i, texture2d :Texture2D) -> void:
	var image := texture2d.get_image()
	if image.is_compressed():
		image.decompress()
	var image_size := image.get_size()
	for xi in image_size.x:
		for yi in image_size.y:
			var co :Color = image.get_pixel(xi,yi)
			plot_at(Vector3i(0,xi,image_size.y-yi-1) + posi ,co)

## for animation
var cell_rotation_x :float:
	set(rad):
		for i in plotted.size():
			set_inst_rotation(i, Vector3.RIGHT, rad)

var cell_rotation_y :float:
	set(rad):
		for i in plotted.size():
			set_inst_rotation(i, Vector3.UP, rad)

var cell_rotation_z :float:
	set(rad):
		for i in plotted.size():
			set_inst_rotation(i, Vector3.FORWARD, rad)

func make_ani_cell_rotate(aniname :String, axis :int, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(
		aniname, self,
		["cell_rotation_x", "cell_rotation_y", "cell_rotation_z"][axis],
		from , to, dur_sec
	)

func make_ani_cell_rotate_x(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "cell_rotation_x", from , to, dur_sec)

func make_ani_cell_rotate_y(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "cell_rotation_y", from , to, dur_sec)

func make_ani_cell_rotate_z(aniname :String, from :float, to :float, dur_sec :float) -> Dictionary:
	return SimpleAnimation.MakeAnimation(aniname, self, "cell_rotation_z", from , to, dur_sec)
