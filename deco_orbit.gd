extends Node3D

var orbitsphere_scene = preload("res://orbit_sphere/orbit_sphere.tscn")
var tower_setting :TowerSetting

func init(ts :TowerSetting) -> void:
	tower_setting = ts
	var a120 = PI*2/3
	var a30 = PI/6
	var axis1 = Vector3.UP.rotated(Vector3.RIGHT, a30)
	var axis2 = Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120), a30)
	var axis3 = Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,a120*2), a30)
	$Sun.궤도설정(tower_setting.TotalDiagonal*1.1, 1.0/3, axis1, a120*2).구설정(5, 1, Vector3.UP).구재질설정(preload("res://sun_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.GREEN))
	$Earth.궤도설정(tower_setting.TotalDiagonal, 1.0/2, axis2, 0).구설정(4, 1, Vector3.UP).구재질설정(preload("res://earth_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.RED))
	$Moon.궤도설정(tower_setting.TotalDiagonal*0.9, 1.0/1, axis3, a120).구설정(3, 1, Vector3.UP).구재질설정(preload("res://moon_mat.tres")).궤도재질설정(Global3d.get_color_mat(Color.YELLOW))
	#many_orbit_sphere(3)

var orbsph_list :Array =[]
func many_orbit_sphere(n :int) -> void:
	var orbit_r = tower_setting.TotalDiagonal/2 *1.5
	for i in n:
		var ob_r = orbit_r #+ orbit_r/n*i
		var sp_r = orbit_r / 50
		var axis = Vector3.UP.rotated(Vector3.RIGHT.rotated(Vector3.UP,2*PI/n*i), PI/6 )
		var orsp = orbitsphere_scene.instantiate(
			).궤도설정(ob_r, 1, axis, 2*PI/n*i
			).구설정(sp_r, 0, Vector3.UP
			).구재질설정(Global3d.get_color_mat(NamedColorList.color_list.pick_random()[0])
			).궤도재질설정(Global3d.get_color_mat(NamedColorList.color_list.pick_random()[0])
		)
		orbsph_list.append(orsp)
		add_child(orsp)

func orbit_pos(center_pos:Vector3, cur_storey_index :int) -> void:
	#var cp = calc_center()
	$Sun.position = center_pos
	$Earth.position = center_pos
	$Moon.position = center_pos
	center_pos.y = tower_setting.calc_storey_mid_y_pos(cur_storey_index+1)
	for n in orbsph_list:
		n.position = center_pos
