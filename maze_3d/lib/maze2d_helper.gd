class_name Maze2DHelper

var maze :Maze
var map_scale :float = 20
var wall_thick :float = 2

func _to_string() -> String:
	return "Maze2DHelper %s" % maze

func posi_to_mappos(pos :Vector2i) -> Vector2:
	return pos * map_scale + Vector2(wall_thick,wall_thick)

func set_maze(mz :Maze) -> void:
	maze = mz

func get_width() -> float:
	return maze.width * map_scale

func get_height() -> float:
	return maze.height * map_scale

func update_size(sz :Vector2) -> void:
	map_scale = min( sz.x / maze.width , sz.y / maze.height )
	wall_thick = max(1, map_scale*0.1)
