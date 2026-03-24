extends Node2D
class_name StoreyMiniMap

func get_label_minimap() -> LabelMiniMap:
	return $LabelMiniMap

enum MiniMapView {Off, Known, Full}
static func minimapview2str(vd :MiniMapView) -> String:
	return MiniMapView.keys()[vd]
static func minimapview_next(a :MiniMapView) -> MiniMapView:
	return (a +1) % MiniMapView.keys().size() as MiniMapView

func mode_next() -> void:
	minimap_mode = minimapview_next(minimap_mode)
	apply_minimap_mode()

func set_minimap_mod(m :MiniMapView) -> void:
	minimap_mode = m
	apply_minimap_mode()

var minimap_mode :MiniMapView = MiniMapView.Off
var maze2d_helper := Maze2DHelper.new()
var wall_lines_all := WallLines.new()
var wall_lines_known := WallLines.new()

func _to_string() -> String:
	return "StoreyMiniMap %s" % [minimapview2str(minimap_mode) ]

func init(mz :Maze) -> StoreyMiniMap:
	maze2d_helper.set_maze(mz)
	wall_lines_all.set_helper(maze2d_helper)
	wall_lines_known.set_helper(maze2d_helper)
	$LabelMiniMap.set_helper(maze2d_helper)
	wall_lines_known.init_walls()
	apply_minimap_mode()
	return self

func apply_minimap_mode() -> void:
	match minimap_mode:
		MiniMapView.Off:
			hide()
		MiniMapView.Known:
			show()
			$LabelMiniMap.show_all(false)
			$LabelMiniMap.show_known()
			queue_redraw()
		MiniMapView.Full:
			show()
			$LabelMiniMap.show_all()
			queue_redraw()

func update_size(sz :Vector2) -> void:
	maze2d_helper.update_size(sz)
	wall_lines_all.make_all_walllines()
	wall_lines_known.make_walllines_known()
	$LabelMiniMap.update_size()

func add_obj(node :Node, txt :String, co :Color, outline :int, visible_in_known_map_view :bool = false) -> void:
	$LabelMiniMap.add_obj(node,txt,co,outline,visible_in_known_map_view)

func update_obj_pos(node :Node, update_know_wall :bool = false) -> void:
	$LabelMiniMap.update_obj_pos(node)
	var posi :Vector2i = node.get_posi()
	if update_know_wall:
		if wall_lines_known.update_walls_by_pos(posi.x, posi.y):
			queue_redraw()

func _draw() -> void:
	match minimap_mode:
		MiniMapView.Full:
			draw_multiline(wall_lines_all.walllines, Color(Color.WHITE,0.5), maze2d_helper.wall_thick)
		MiniMapView.Known:
			if wall_lines_known.walllines.size() == 0 :
				return
			draw_multiline(wall_lines_known.walllines, Color(Color.WHITE,0.5), maze2d_helper.wall_thick)
