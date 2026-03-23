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
var storey :Storey
var walllines_known :PackedVector2Array =[]
var walls_known : Array[PackedByteArray] # as bool array
var goal :Label
var start :Label
var player_serial :int

func _to_string() -> String:
	return "Minimap %s" % [minimapview2str(minimap_mode) ]

func init_storey(st :Storey) -> StoreyMiniMap:
	set_maze(st.maze3d.maze_cells)
	storey = st
	walls_known = []
	walls_known.resize(storey.maze3d.PreCalced.Grid2D.y*2+1)
	for cl in walls_known:
		cl.resize(storey.maze3d.PreCalced.Grid2D.x*2+1)
	goal = new_label(Color.RED, "Goal", 1)
	add_child(goal)
	start = new_label(Color.YELLOW, "Start", 1)
	add_child(start)
	apply_minimap_mode()
	return self

func add_chars(char_list :Array, playernum :int) -> StoreyMiniMap:
	player_serial = playernum
	for ch in char_list:
		if ch.crawler_num == player_serial:
			add_character(ch, 1)
		else:
			add_character(ch, 0)
	apply_minimap_mode()
	return self

func apply_minimap_mode() -> void:
	match minimap_mode:
		MiniMapView.Off:
			hide()
		MiniMapView.Known:
			show()
			for ch in $CharacterContainer.get_children():
				ch.visible = false
			$CharacterContainer.get_child(player_serial).visible = true
			queue_redraw()
		MiniMapView.Full:
			show()
			for ch in $CharacterContainer.get_children():
				ch.visible = true
			queue_redraw()

func update_size(rt :Rect2) -> void:
	super(rt)
	make_walllines_known()
	update_labels()

func add_character(achar :Crawler, outline :int) -> void:
	var ch := new_label(achar.color, "%d" %[achar.crawler_num] , outline)
	$CharacterContainer.add_child(ch)

func update_char_pos(ch :Crawler) -> void:
	$CharacterContainer.get_child(ch.crawler_num).position = pos2mapscale( ch.pos_src )
	if ch.crawler_num == player_serial:
		update_knonw_walls_by_pos(ch.pos_src.x, ch.pos_src.y)

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
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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

func update_labels() -> void:
	update_label_pos_size(goal,storey.goal_pos)
	update_label_pos_size(start,storey.start_pos)
	for ch in $CharacterContainer.get_children():
		update_label_pos_size(ch,storey.start_pos)

func update_label_pos_size(nd :Label, pos :Vector2i) -> void:
	nd.position = pos2mapscale(pos)
	nd.size = Vector2(map_scale-WallThick*2, map_scale-WallThick*2)
	nd.label_settings.font_size = map_scale/2.0 as int


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
