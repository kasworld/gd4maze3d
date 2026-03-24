extends Node2D
class_name MazeMiniMap

var wall_lines_all := WallLines.new()

func _to_string() -> String:
	return "Minimap %s" % wall_lines_all

func set_maze(mz :Maze) -> void:
	wall_lines_all.set_maze(mz)

func update_size(rt :Rect2) -> void:
	wall_lines_all.update_size(rt)
	wall_lines_all.make_all_walllines()
	position = rt.position

func _draw() -> void:
	draw_multiline(wall_lines_all.walllines,Color(Color.WHITE,0.5),wall_lines_all.WallThick)
