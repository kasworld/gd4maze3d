extends Node2D
class_name StoreyMiniMap

var maze2d_helper := Maze2DHelper.new()
#func set_helper(mh :Maze2DHelper) -> void:
	#maze2d_helper = mh


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

var wall_lines_all := WallLines.new()
var wall_lines_known := WallLines.new()

## obj must has func get_posi() -> Vector2i:
#var obj_to_label :Dictionary[Node,Label] = {}
#var label_visible_in_known_map_view :Array[Label] = []

func _to_string() -> String:
	return "Minimap %s" % [minimapview2str(minimap_mode) ]

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
			#for ch in $Container.get_children():
				#ch.visible = false
			$LabelMiniMap.show_known()
			#for lb in label_visible_in_known_map_view:
				#lb.visible = true
			queue_redraw()
		MiniMapView.Full:
			show()
			$LabelMiniMap.show_all()
			#for ch in $Container.get_children():
				#ch.visible = true
			queue_redraw()

func update_size(rt :Rect2) -> void:
	maze2d_helper.update_size(rt)
	#wall_lines_all.update_size(rt)
	wall_lines_all.make_all_walllines()
	#wall_lines_known.update_size(rt)
	wall_lines_known.make_walllines_known()
	position = rt.position
	$LabelMiniMap.update_size(rt)
	#for nd in obj_to_label:
		#var lb := obj_to_label[nd]
		#var posi :Vector2i = nd.get_posi()
		#update_label_pos_size(lb, posi)
#
#func update_label_pos_size(lb :Label, posi :Vector2i) -> void:
	#lb.position = wall_lines_all.posi_to_mappos(posi)
	#lb.size = Vector2(wall_lines_all.map_scale - wall_lines_all.wall_thick*2, wall_lines_all.map_scale - wall_lines_all.wall_thick*2)
	#lb.label_settings.font_size = max(1, wall_lines_all.map_scale/max(2,lb.text.length()) as int )
#
func add_obj(node :Node, txt :String, co :Color, outline :int, visible_in_known_map_view :bool = false) -> void:
	$LabelMiniMap.add_obj(node,txt,co,outline,visible_in_known_map_view)
#func add_obj(node :Node, txt :String, co :Color, outline :int, visible_in_known_map_view :bool = false) -> void:
	#var lb := new_label(co, txt , outline)
	#$Container.add_child(lb)
	#obj_to_label[node] = lb
	#if visible_in_known_map_view:
		#label_visible_in_known_map_view.append(lb)
#
func update_obj_pos(node :Node, update_know_wall :bool = false) -> void:
	$LabelMiniMap.update_obj_pos(node)
#func update_obj_pos(node :Node, update_know_wall :bool = false) -> void:
	var posi :Vector2i = node.get_posi()
	#obj_to_label[node].position = wall_lines_all.posi_to_mappos(posi)
	if update_know_wall:
		if wall_lines_known.update_walls_by_pos(posi.x, posi.y):
			queue_redraw()
#
#func new_label(co:Color, text :String, outline :int) -> Label:
	#var co_txt :Color
	#var co_bdr :Color
	#var lum := co.get_luminance()
	#if lum > 0.5:
		#co_txt = co.inverted().darkened(0.5)
	#else:
		#co_txt = co.inverted().lightened(0.5)
	#co_bdr = co_txt
#
	#var lb = Label.new()
	#lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	#lb.label_settings = LabelSettings.new()
	#lb.label_settings.font_color = Color(co_txt, 0.5)
	#lb.text = text
	#var stb := StyleBoxFlat.new()
	#stb.bg_color = Color(co, 0.5)
	#if outline != 0:
		#stb.border_color = Color(co_bdr,0.5)
		##stb.border_blend = true
		#stb.border_width_bottom = outline
		#stb.border_width_left = outline
		#stb.border_width_right = outline
		#stb.border_width_top = outline
	#lb.add_theme_stylebox_override("normal", stb)
	#return lb

func _draw() -> void:
	match minimap_mode:
		MiniMapView.Full:
			draw_multiline(wall_lines_all.walllines, Color(Color.WHITE,0.5), maze2d_helper.wall_thick)
		MiniMapView.Known:
			if wall_lines_known.walllines.size() == 0 :
				return
			draw_multiline(wall_lines_known.walllines, Color(Color.WHITE,0.5), maze2d_helper.wall_thick)
