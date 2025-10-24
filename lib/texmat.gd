class_name TexMat

static var wall_tex_dict = {
	brownbrick = preload("res://image/brownbrick50.png"),
	bluestone = preload("res://image/bluestone50.png"),
	drymud = preload("res://image/drymud50.png"),
	graystone = preload("res://image/graystone50.png"),
	pinkstone = preload("res://image/pinkstone50.png"),
	greenstone = preload("res://image/greenstone50.png"),
	ice50 = preload("res://image/ice50.png")
}
static func make_subwall_mat() -> StandardMaterial3D:
	var tex_keys = wall_tex_dict.keys()
	tex_keys.shuffle()
	var tex_name = tex_keys[0]
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = wall_tex_dict[tex_name]
	mat.transparency = BaseMaterial3D.Transparency.TRANSPARENCY_ALPHA
	mat.uv1_scale = Vector3(3, 2, 1)
	#mat.uv1_scale = Vector3(maze3d_setting.LaneW/2, maze3d_setting.StoryH/2, 1)
	return mat
	
static var wall_mat_dict = {
	aluminium = preload("res://test_materials/aluminium.tres"),
	#blue = preload("res://test_materials/blue.tres"),
	brick = preload("res://test_materials/brick.tres"),
	cheese = preload("res://test_materials/cheese.tres"),
	darkwood = preload("res://test_materials/dark_wood.tres"),
	#gray = preload("res://test_materials/gray.tres"),
	#ice = preload("res://test_materials/ice.tres"),
	marble = preload("res://test_materials/marble.tres"),
	#mirror = preload("res://test_materials/mirror.tres"),
	rock = preload("res://test_materials/rock.tres"),
	stones = preload("res://test_materials/stones.tres"),
	#toon = preload("res://test_materials/toon.tres"),
	wetsand = preload("res://test_materials/wet_sand.tres"),
	#white = preload("res://test_materials/white.tres"),
	#whiteplastic = preload("res://test_materials/white_plastic.tres"),
	wool = preload("res://test_materials/wool.tres"),
}
static func make_mainwall_mat() -> StandardMaterial3D:
	var mat_keys = wall_mat_dict.keys()
	mat_keys.shuffle()
	var mat_name = mat_keys[0]
	var mat = wall_mat_dict[mat_name]
	mat.uv1_scale = Vector3(3, 2, 1)
	#mat.uv1_scale = Vector3(maze3d_setting.LaneW/2, maze3d_setting.StoryH/2, 1)
	return mat
