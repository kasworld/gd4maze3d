extends Node2D
class_name MazeMiniMap

var maze2d_helper := Maze2DHelper.new()
var wall_lines_all := WallLines.new()

func _to_string() -> String:
	return "MazeMiniMap %s" % maze2d_helper.maze

func set_maze(mz :Maze) -> void:
	maze2d_helper.set_maze(mz)
	wall_lines_all.set_helper(maze2d_helper)

func update_size(rt :Rect2) -> void:
	maze2d_helper.update_size(rt)
	wall_lines_all.make_all_walllines()
	position = rt.position

func _draw() -> void:
	draw_multiline(wall_lines_all.walllines, Color(Color.WHITE,0.5), maze2d_helper.wall_thick)
