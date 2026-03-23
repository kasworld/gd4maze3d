extends MazeMiniMap
class_name StoreyMiniMap

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

var walllines_known :PackedVector2Array =[]
var walls_known : Array[PackedByteArray] # as bool array


## obj must has func get_posi() -> Vector2i:
var obj_to_label :Dictionary[Node,Label] = {}
var label_visible_in_known_map_view :Array[Label] = []
func _to_string() -> String:
	return "Minimap %s" % [minimapview2str(minimap_mode) ]

func init_storey(mz :Maze) -> StoreyMiniMap:
	set_maze(mz)
	walls_known = []
	walls_known.resize(maze.height*2+1)
	for cl in walls_known:
		cl.resize(maze.width*2+1)
	apply_minimap_mode()
	return self

func apply_minimap_mode() -> void:
	match minimap_mode:
		MiniMapView.Off:
			hide()
		MiniMapView.Known:
			show()
			for ch in $Container.get_children():
				ch.visible = false
			for lb in label_visible_in_known_map_view:
				lb.visible = true
			queue_redraw()
		MiniMapView.Full:
			show()
			for ch in $Container.get_children():
				ch.visible = true
			queue_redraw()

func update_size(rt :Rect2) -> void:
	super(rt)
	make_walllines_known()
	for nd in obj_to_label:
		var lb := obj_to_label[nd]
		var posi :Vector2i = nd.get_posi()
		update_label_pos_size(lb, posi)

func update_label_pos_size(lb :Label, posi :Vector2i) -> void:
	lb.position = posi_to_mappos(posi)
	lb.size = Vector2(map_scale-WallThick*2, map_scale-WallThick*2)
	lb.label_settings.font_size = map_scale/2.0 as int

func add_obj(node :Node, txt :String, co :Color, outline :int, visible_in_known_map_view :bool = false) -> void:
	var lb := new_label(co, txt , outline)
	$Container.add_child(lb)
	obj_to_label[node] = lb
	if visible_in_known_map_view:
		label_visible_in_known_map_view.append(lb)

func update_obj_pos(node :Node, update_know_wall :bool = false) -> void:
	var posi :Vector2i = node.get_posi()
	obj_to_label[node].position = posi_to_mappos(posi)
	if update_know_wall:
		update_knonw_walls_by_pos(posi.x, posi.y)

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


# make wallline by walls_known
func make_walllines_known() -> void:
	walllines_known = []
	for y in maze.height:
		for x in maze.width:
			if is_known_wall_at(x, y, Maze.Dir.North):
				add_wall_at_to_walllines(x, y, Maze.Dir.North, walllines_known)
			if is_known_wall_at(x, y, Maze.Dir.West):
				add_wall_at_to_walllines(x, y, Maze.Dir.West, walllines_known)

	for x in maze.width :
		if is_known_wall_at(x, maze.height-1, Maze.Dir.South):
			add_wall_at_to_walllines(x, maze.height-1, Maze.Dir.South, walllines_known)

	for y in maze.height:
		if is_known_wall_at(maze.width-1, y, Maze.Dir.East):
			add_wall_at_to_walllines(maze.width-1, y, Maze.Dir.East, walllines_known)

func is_known_wall_at(x :int, y:int, dir :Maze.Dir) -> bool:
	var wpos := calc_wall_pos(x,y,dir)
	return walls_known[wpos.y][wpos.x] != 0
func set_known_wall_at(x :int, y:int, dir :Maze.Dir):
	var wpos := calc_wall_pos(x,y,dir)
	walls_known[wpos.y][wpos.x] = 1
func add_known_wall_at(x:int,y :int, dir :Maze.Dir) -> void:
	if is_known_wall_at(x,y,dir):
		return
	set_known_wall_at(x,y,dir)
	add_wall_at_to_walllines(x,y,dir,walllines_known)
	queue_redraw()
func update_knonw_walls_by_pos(x:int,y :int) -> void:
	var walldir := maze.get_wall_flag_at(x,y)
	for d in walldir:
		add_known_wall_at(x,y,Maze.FlagToDir[d])

func _draw() -> void:
	match minimap_mode:
		MiniMapView.Full:
			draw_multiline(walllines_all,Color(Color.WHITE,0.5), WallThick)
		MiniMapView.Known:
			if walllines_known.size() == 0 :
				return
			draw_multiline(walllines_known,Color(Color.WHITE,0.5), WallThick)
