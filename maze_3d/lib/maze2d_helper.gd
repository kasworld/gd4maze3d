class_name Maze2DHelper

var maze :Maze
var map_scale :float = 20
var wall_thick :float = 2

func _to_string() -> String:
	return "Maze2DHelper %s" % maze

## init function, must call update_size after this
func set_maze(mz :Maze) -> void:
	maze = mz

## 2nd init function, call set_maze before this
func update_size(sz :Vector2) -> void:
	map_scale = min( sz.x / maze.width , sz.y / maze.height )
	wall_thick = max(1, map_scale*0.1)

## start point, NOT center
func posi_to_mappos(pos :Vector2i) -> Vector2:
	return pos * map_scale + Vector2(wall_thick,wall_thick)/2

## exclude wall_thick
func get_cell_size() -> Vector2:
	return Vector2(map_scale - wall_thick, map_scale - wall_thick)

## exclude wall_thick
func get_width() -> float:
	return maze.width * map_scale

## exclude wall_thick
func get_height() -> float:
	return maze.height * map_scale

## exclude wall_thick
func get_size() -> Vector2:
	return Vector2(get_width(),get_height())
