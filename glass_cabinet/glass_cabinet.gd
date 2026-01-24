extends Node3D
class_name GlassCabinet

var focus_mode :bool
signal focus_mode_changed(me :GlassCabinet, mode :bool)
func set_focus_mode(b :bool) -> void:
	focus_mode = b
	focus_mode_changed.emit(self, focus_mode)
func get_focus_mode() -> bool:
	return focus_mode

## axis : x:0, y:1, z:2, axis_sign : 1,0,-1
static func MakeSubgroupFlagsByPos(axis :int, axis_sign :int) -> int:
	var pos_list := PlatonicSolids.CubePoints
	var rtn := 0
	for i in pos_list.size():
		if sign(pos_list[i][axis]) == sign(axis_sign) :
			rtn = BitFlag.SetByPos(i,rtn)
	return rtn

static var SideSubgroupFlags :Dictionary[String,int] = {
		"x+" : MakeSubgroupFlagsByPos(0,+1),
		"x-" : MakeSubgroupFlagsByPos(0,-1),
		"y+" : MakeSubgroupFlagsByPos(1,+1),
		"y-" : MakeSubgroupFlagsByPos(1,-1),
		"z+" : MakeSubgroupFlagsByPos(2,+1),
		"z-" : MakeSubgroupFlagsByPos(2,-1),
	}

static func _static_init():
	pass

var lights :SpotLightGroup
var cabinet_size :Vector3
func calc_pos_by_grid(x :int, y :int, x_grid:int, y_grid:int) -> Vector3:
	var xunit := cabinet_size.x/x_grid
	var yunit := cabinet_size.y/y_grid
	var posadj := Vector3(+xunit/2 - cabinet_size.x/2, +yunit/2-cabinet_size.y/2, 0)
	var pos := Vector3(xunit * x  , yunit * y , 0) + posadj
	return pos

func calc_fill_h_len_by_fov() -> float:
	var hfov :float = $FixedCameraLight.camera_fov.get_value()
	return cabinet_size.y/2 / tan(deg_to_rad(hfov/2)) + cabinet_size.z/2

func init(cabinet_size_a :Vector3) -> GlassCabinet:
	cabinet_size = cabinet_size_a
	$WallBox.mesh.size = cabinet_size
	$FixedCameraLight.set_center_pos_far(Vector3.ZERO, 	Vector3(0, 0, calc_fill_h_len_by_fov()), cabinet_size.length()*2)
	$AxisArrow3D.set_size(cabinet_size.length()/10).set_colors()
	$Title.pixel_size = cabinet_size.y/300
	$Title.position = Vector3(-cabinet_size.x/2,cabinet_size.y/2,cabinet_size.z/2)
	$Description.pixel_size = cabinet_size.y/600
	$Description.position = Vector3(cabinet_size.x/2,-cabinet_size.y/2,cabinet_size.z/2)
	$WireBox.init_wire_box( cabinet_size, cabinet_size.length()/200, Color.WHITE)
	$Points.init_spheres_by_point_list(
		PlatonicSolids.MultiplyPointList(PlatonicSolids.CubePoints, cabinet_size/2),
		cabinet_size.length()/200, Color.WHITE,
	)
	add_spot_lights()
	lights = SpotLightGroup.new($LightContainer)
	return self

func add_spot_lights() -> GlassCabinet:
	var points := PlatonicSolids.MultiplyPointList(PlatonicSolids.CubePoints, cabinet_size/2 )
	for pos in points:
		var sl := SpotLight3D.new()
		$LightContainer.add_child(sl)
		sl.spot_range = cabinet_size.length()
		sl.position = pos
		sl.look_at_from_position(pos, Vector3.ZERO)
		sl.light_energy = 100
		#sl.shadow_enabled = true
		#sl.light_color = Color.RED
	return self

#const CubePoints := [
	#Vector3(1,1,1),
	#Vector3(-1,1,1),
	#Vector3(1,-1,1),
	#Vector3(-1,-1,1),
	#Vector3(1,1,-1),
	#Vector3(-1,1,-1),
	#Vector3(1,-1,-1),
	#Vector3(-1,-1,-1),
#]

func show_axis_arrow(b :bool = true) -> GlassCabinet:
	$AxisArrow3D.visible = b
	return self

func show_wall_box(b :bool = true) -> GlassCabinet:
	$WallBox.visible = b
	return self
func set_wall_box_color(co :Color) -> GlassCabinet:
	$WallBox.mesh.material.albedo_color = co
	return self

func show_wire_box(b :bool = true) -> GlassCabinet:
	$WireBox.visible = b
	return self
func set_wire_box_color(co :Color) -> GlassCabinet:
	$WireBox.set_color_all(co)
	return self

func show_points(b :bool = true) -> GlassCabinet:
	$Points.visible = b
	return self
func set_points_color(co :Color) -> GlassCabinet:
	$Points.set_color_all(co)
	return self

func get_title_text() -> String:
	return $Title.text
func show_title(b :bool = true) -> GlassCabinet:
	$Title.visible = b
	return self
func set_title_text(t :String) -> GlassCabinet:
	$Title.text = t
	return self
func set_title_pixel_size(sz :float) -> GlassCabinet:
	$Title.pixel_size = sz
	return self

func get_description_text() -> String:
	return $Description.text
func show_description(b :bool = true) -> GlassCabinet:
	$Description.visible = b
	return self
func set_description_text(t :String) -> GlassCabinet:
	$Description.text = t
	return self
func set_description_pixel_size(sz :float) -> GlassCabinet:
	$Description.pixel_size = sz
	return self


func get_camera_light() -> MovingCameraLight:
	return $FixedCameraLight

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if $FixedCameraLight.is_current_camera():
			var fi = FlyNode3D.Key2Info.get(event.keycode)
			if fi != null:
				FlyNode3D.fly_node3d($FixedCameraLight, fi)
