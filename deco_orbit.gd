extends Node3D

static var redcolor := NamedColorList.make_red_color_list()
static var greencolor := NamedColorList.make_green_color_list()
static var bluecolor := NamedColorList.make_blue_color_list()

var orbitsphere_scene = preload("res://orbit_sphere/orbit_sphere.tscn")
var diagonal_length :float
func init(dl :float) -> void:
	diagonal_length = dl
	var a120 := PI*2/3
	var a30 := PI/6
	var axis1 := Vector3.UP.rotated(Vector3.RIGHT, a30)
	var axis2 := Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120), a30)
	var axis3 := Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120*2), a30)
	$Sun.궤도설정(diagonal_length*1.1, 1.0/3, axis1, a120*2
		).구설정(5, 1, Vector3.UP
		).구재질설정( preload("res://sun_mat.tres")
		#).구재질설정( get_color_mat( redcolor.pick_random()[0])
		).궤도재질설정( get_color_mat(redcolor.pick_random()[0]) )
	$Earth.궤도설정(diagonal_length, 1.0/2, axis2, 0
		).구설정(4, 1, Vector3.UP
		).구재질설정( preload("res://earth_mat.tres")
		#).구재질설정( get_color_mat(bluecolor.pick_random()[0])
		).궤도재질설정( get_color_mat(Color.RED) )
	$Moon.궤도설정(diagonal_length*0.9, 1.0/1, axis3, a120
		).구설정(3, 1, Vector3.UP
		).구재질설정( preload("res://moon_mat.tres")
		#).구재질설정( get_color_mat(greencolor.pick_random()[0])
		).궤도재질설정( get_color_mat(Color.YELLOW))

func get_color_mat(co: Color)->Material:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = co
	#mat.metallic = 1
	#mat.clearcoat = true
	return mat
