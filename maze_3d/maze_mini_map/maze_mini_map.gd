extends Node2D
class_name MazeMiniMap

var maze2d_helper := Maze2DHelper.new()
var wall_lines_all := WallLines.new()
var line_color := Color(Color.WHITE,0.5)
func set_color(co :Color) -> void:
	line_color = co

func _to_string() -> String:
	return "MazeMiniMap %s" % maze2d_helper.maze

func set_maze(mz :Maze) -> void:
	maze2d_helper.set_maze(mz)
	wall_lines_all.set_helper(maze2d_helper)


func update_size(sz :Vector2) -> void:
	maze2d_helper.update_size(sz)
	wall_lines_all.make_all_walllines()

func _draw() -> void:
	draw_multiline(wall_lines_all.walllines, line_color, maze2d_helper.wall_thick)
