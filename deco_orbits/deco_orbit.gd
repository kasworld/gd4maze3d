extends Node3D

var WorldSize :Vector3
var orbitsphere_list :Array
func init(WorldSize_a :Vector3, count :int) -> void:
	WorldSize = WorldSize_a
	for i in count:
		add_orbitsphere(i, count)
func add_orbitsphere(i :int, count :int) -> void:
	var rate := float(i)/float(count-1) * 0.5 + 0.5
	var diagonal_length := WorldSize.length() * rate
	var a120 := PI*2/3
	var a30 := PI/6
	var axis1 := Vector3.UP.rotated(
		[Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK].pick_random(),
		a30)
	var 궤도mat1 := StandardMaterial3D.new()
	궤도mat1.albedo_color = random_color()
	var 구mat2
	match i:
		0,1,2:
			구mat2 = [
				preload("res://earthmoon/sun_mat.tres"),
				preload("res://earthmoon/earth_mat.tres"),
				preload("res://earthmoon/moon_mat.tres"),
				][i]
		_:
			구mat2 = StandardMaterial3D.new()
			구mat2.albedo_color = random_color()
	var os = preload("res://orbit_sphere/orbit_sphere.tscn").instantiate(
		).궤도설정(diagonal_length, diagonal_length/200, axis1, a120*[0,1,2].pick_random()
		).구설정(WorldSize.x/400*i+1, WorldSize.x/50, Vector3.UP
		).구재질설정(구mat2).궤도재질설정(궤도mat1)
	add_child(os)
	orbitsphere_list.append(os)

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for os in orbitsphere_list:
		os.animate_rotate(now, delta)

func random_color() -> Color:
	return NamedColors.random_color()
