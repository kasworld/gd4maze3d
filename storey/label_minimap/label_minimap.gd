extends Node2D
class_name LabelMiniMap

## obj must has func get_posi() -> Vector2i:
var obj_to_label :Dictionary[Node,Label] = {}
var label_visible_in_known_map_view :Array[Label] = []

var maze2d_helper :Maze2DHelper
func set_helper(mh :Maze2DHelper) -> void:
	maze2d_helper = mh

func show_all(b :bool = true) -> void:
	for ch in $Container.get_children():
		ch.visible = b

func show_known() -> void:
	for lb in label_visible_in_known_map_view:
		lb.visible = true

func update_size() -> void:
	for nd in obj_to_label:
		var lb := obj_to_label[nd]
		var posi :Vector2i = nd.get_posi()
		update_label_pos_size(lb, posi)

func update_label_pos_size(lb :Label, posi :Vector2i) -> void:
	lb.position = maze2d_helper.posi_to_mappos(posi)
	lb.size = Vector2(maze2d_helper.map_scale - maze2d_helper.wall_thick*2, maze2d_helper.map_scale - maze2d_helper.wall_thick*2)
	lb.label_settings.font_size = max(1, maze2d_helper.map_scale/max(2,lb.text.length()) as int )

func add_obj(node :Node, txt :String, co :Color, outline :int, visible_in_known_map_view :bool = false) -> void:
	var lb := new_label(co, txt , outline)
	$Container.add_child(lb)
	obj_to_label[node] = lb
	if visible_in_known_map_view:
		label_visible_in_known_map_view.append(lb)

func update_obj_pos(node :Node) -> void:
	var posi :Vector2i = node.get_posi()
	obj_to_label[node].position = maze2d_helper.posi_to_mappos(posi)

func new_label(co:Color, text :String, outline :int) -> Label:
	var co_txt :Color
	var co_bdr :Color
	var lum := co.get_luminance()
	if lum > 0.5:
		co_txt = co.inverted().darkened(0.5)
	else:
		co_txt = co.inverted().lightened(0.5)
	co_bdr = co_txt

	var lb = Label.new()
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.label_settings = LabelSettings.new()
	lb.label_settings.font_color = Color(co_txt, 0.5)
	lb.text = text
	var stb := StyleBoxFlat.new()
	stb.bg_color = Color(co, 0.5)
	if outline != 0:
		stb.border_color = Color(co_bdr,0.5)
		#stb.border_blend = true
		stb.border_width_bottom = outline
		stb.border_width_left = outline
		stb.border_width_right = outline
		stb.border_width_top = outline
	lb.add_theme_stylebox_override("normal", stb)
	return lb
