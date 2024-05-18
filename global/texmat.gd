extends Node

var wall_tex_dict = {
	brownbrick = preload("res://image/brownbrick50.png"),
	bluestone = preload("res://image/bluestone50.png"),
	drymud = preload("res://image/drymud50.png"),
	graystone = preload("res://image/graystone50.png"),
	pinkstone = preload("res://image/pinkstone50.png"),
	greenstone = preload("res://image/greenstone50.png"),
	ice50 = preload("res://image/ice50.png")
}

var tree_tex_dict = {
	floorwood = preload("res://image/floorwood.jpg"),
	darkwood = preload("res://image/Dark-brown-fine-wood-texture.jpg"),
	leaf = preload("res://image/leaf.png"),
}

var wall_mat_dict = {
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

var floor_mat_dict = wall_mat_dict
var ceiling_mat_dict = wall_mat_dict
var interfloor_mat = preload("res://image/net.png")
