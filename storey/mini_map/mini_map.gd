extends Node2D
class_name MiniMap

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
var map_scale :float = 20
var WallThick :float = 2
var storey :Storey
var walllines_all :PackedVector2Array =[]
var walllines_known :PackedVector2Array =[]
var walls_known : Array[PackedByteArray] # as bool array
var goal :Label
var start :Label
var player_serial :int

func _to_string() -> String:
	return "Minimap %s" % [minimapview2str(minimap_mode) ]

func init(st :Storey) -> MiniMap:
	#minimap_mode = viewmode
	storey = st
	walls_known = []
	walls_known.resize(storey.maze3d.PreCalced.Grid2D.y*2+1)
	for cl in walls_known:
		cl.resize(storey.maze3d.PreCalced.Grid2D.x*2+1)
	goal = new_label(Color.RED, "Goal", 8)
	add_child(goal)
	start = new_label(Color.YELLOW, "Start", 8)
	add_child(start)
	apply_minimap_mode()
	return self

func add_chars(char_list :Array, playernum :int) -> MiniMap:
	player_serial = playernum
	for ch in char_list:
		if ch.crawler_num == player_serial:
			add_character(ch, 8)
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

#func _ready() -> void:
	#update_size()

func update_size() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	map_scale = min( vp_size.x / storey.maze3d.PreCalced.Grid2D.x , vp_size.y / storey.maze3d.PreCalced.Grid2D.y )
	WallThick = map_scale*0.1
	if WallThick < 1 :
		WallThick = 1
	make_walllines_all()
	make_walllines_known()
	update_labels()
	position.y = (vp_size.y - get_height())/2
	position.x = (vp_size.x - get_width())/2

func add_character(achar :Crawler, outline :int) -> void:
	var ch := new_label(achar.color, "Char\n%d" %[achar.crawler_num] , outline)
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
	nd.label_settings.font_size = map_scale/5.0 as int

func pos2mapscale(pos :Vector2i) -> Vector2:
	return pos * map_scale + Vector2(WallThick,WallThick)

# make wallline by maze
func make_walllines_all() -> void:
	walllines_all = []
	var MazeSize :Vector2i= storey.maze3d.PreCalced.Grid2D
	for y in MazeSize.y:
		for x in MazeSize.x :
			if not storey.get_maze_cells().is_open_dir_at(x,y,EnumDir.Flag.North):
				add_wall_at_to_walllines( x , y , EnumDir.Dir.North, walllines_all)
			if not storey.get_maze_cells().is_open_dir_at(x,y,EnumDir.Flag.West):
				add_wall_at_to_walllines( x , y , EnumDir.Dir.West, walllines_all)

	for x in MazeSize.x :
		if not storey.get_maze_cells().is_open_dir_at(x,MazeSize.y-1,EnumDir.Flag.South):
			add_wall_at_to_walllines( x , MazeSize.y-1 , EnumDir.Dir.South, walllines_all)

	for y in MazeSize.y:
		if not storey.get_maze_cells().is_open_dir_at(MazeSize.x-1,y,EnumDir.Flag.East):
			add_wall_at_to_walllines( MazeSize.x-1 , y , EnumDir.Dir.East, walllines_all)

# make wallline by walls_known
func make_walllines_known() -> void:
	walllines_known = []
	var MazeSize :Vector2i= storey.maze3d.PreCalced.Grid2D
	for y in MazeSize.y:
		for x in MazeSize.x :
			if is_known_wall_at(x,y,EnumDir.Dir.North):
				add_wall_at_to_walllines( x , y , EnumDir.Dir.North, walllines_known)
			if is_known_wall_at(x,y,EnumDir.Dir.West):
				add_wall_at_to_walllines( x , y , EnumDir.Dir.West, walllines_known)

	for x in MazeSize.x :
		if is_known_wall_at(x,MazeSize.y-1,EnumDir.Dir.South):
			add_wall_at_to_walllines( x , MazeSize.y-1 , EnumDir.Dir.South, walllines_known)

	for y in MazeSize.y:
		if is_known_wall_at(MazeSize.x-1,y,EnumDir.Dir.East):
			add_wall_at_to_walllines( MazeSize.x-1 , y , EnumDir.Dir.East, walllines_known)

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :EnumDir.Dir) -> Vector2i:
	return Vector2i(x*2+1,y*2+1) + EnumDir.DirToVt2[dir]
func is_known_wall_at(x :int, y:int, dir :EnumDir.Dir) -> bool:
	var wpos := calc_wall_pos(x,y,dir)
	return walls_known[wpos.y][wpos.x] != 0
func set_known_wall_at(x :int, y:int, dir :EnumDir.Dir):
	var wpos := calc_wall_pos(x,y,dir)
	walls_known[wpos.y][wpos.x] = 1
func add_known_wall_at(x:int,y :int, dir :EnumDir.Dir) -> void:
	if is_known_wall_at(x,y,dir):
		return
	set_known_wall_at(x,y,dir)
	add_wall_at_to_walllines(x,y,dir,walllines_known)
	queue_redraw()
func update_knonw_walls_by_pos(x:int,y :int) -> void:
	var walldir := storey.get_maze_cells().get_wall_dir_at(x,y)
	for d in walldir:
		add_known_wall_at(x,y,EnumDir.FlagToDir[d])

func add_wall_at_to_walllines(x:int,y :int, dir :EnumDir.Dir,wl :PackedVector2Array ) -> void:
	match dir:
		EnumDir.Dir.North:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		EnumDir.Dir.West:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		EnumDir.Dir.South:
			wl.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		EnumDir.Dir.East:
			wl.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])

func get_width() -> float:
	return storey.maze3d.PreCalced.Grid2D.x * map_scale
func get_height() -> float:
	return storey.maze3d.PreCalced.Grid2D.y * map_scale

func _draw() -> void:
	match minimap_mode:
		MiniMapView.Full:
			draw_multiline(walllines_all,Color(Color.WHITE,0.5), WallThick)
		MiniMapView.Known:
			if walllines_known.size() == 0 :
				return
			draw_multiline(walllines_known,Color(Color.WHITE,0.5), WallThick)
