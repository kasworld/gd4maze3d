extends Node2D

class_name MiniMap

var map_scale :float = 20
var WallThick :float = 2
var storey :Storey
var walllines_all :PackedVector2Array =[]
var walllines_known :PackedVector2Array =[]
var walls_known : Array[PackedByteArray] # as bool array
var map_mode_full :bool

var goal :Label
var start :Label
func init(st :Storey, sc :float)->void:
	map_mode_full = false
	storey = st

	walls_known = []
	walls_known.resize(Settings.MazeSize.y*2+1)
	for cl in walls_known:
		cl.resize(Settings.MazeSize.x*2+1)
	goal = new_label(Color.RED, "Goal", 8)
	add_child(goal)
	start = new_label(Color.YELLOW, "Start", 8)
	add_child(start)

	change_scale(sc)

func add_character(char :Character, pos :Vector2, outline :int)->void:
	var ch = new_label(char.color, "Char\n%d" %[char.serial] , outline)
	$CharacterContainer.add_child(ch)
	update_label_pos_size(ch,pos)

func move_character(n :int, pos :Vector2)->void:
	$CharacterContainer.get_child(n).position = pos2mapscale( pos )

func new_label(co:Color, text :String, outline :int)->Label:
	var co_txt :Color
	var co_bdr :Color
	var lum = co.get_luminance()
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
	var stb = StyleBoxFlat.new()
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

# call scale changed
func change_scale(sc :float)->void:
	map_scale = sc
	WallThick = map_scale*0.1
	if WallThick < 1 :
		WallThick = 1
	make_walllines_all()
	make_walllines_known()
	update_labels()

func update_labels()->void:
	update_label_pos_size(goal,storey.goal_pos)
	update_label_pos_size(start,storey.start_pos)
	for ch in $CharacterContainer.get_children():
		update_label_pos_size(ch,storey.start_pos)

func update_label_pos_size(nd :Label, pos :Vector2)->void:
	nd.position = pos2mapscale(pos)
	nd.size = Vector2(map_scale-WallThick*2, map_scale-WallThick*2)
	nd.label_settings.font_size = map_scale/5

func pos2mapscale(pos :Vector2)->Vector2:
	return pos * map_scale + Vector2(WallThick,WallThick)

# make wallline by maze
func make_walllines_all()->void:
	walllines_all = []
	var MazeSize = Settings.MazeSize
	for y in MazeSize.y:
		for x in MazeSize.x :
			if not storey.maze_cells.is_open_dir_at(x,y,DirLib.Flag.North):
				add_wall_at_raw( x , y , DirLib.Dir.North, walllines_all)
			if not storey.maze_cells.is_open_dir_at(x,y,DirLib.Flag.West):
				add_wall_at_raw( x , y , DirLib.Dir.West, walllines_all)

	for x in MazeSize.x :
		if not storey.maze_cells.is_open_dir_at(x,MazeSize.y-1,DirLib.Flag.South):
			add_wall_at_raw( x , MazeSize.y-1 , DirLib.Dir.South, walllines_all)

	for y in MazeSize.y:
		if not storey.maze_cells.is_open_dir_at(MazeSize.x-1,y,DirLib.Flag.East):
			add_wall_at_raw( MazeSize.x-1 , y , DirLib.Dir.East, walllines_all)

# make wallline by walls_known
func make_walllines_known()->void:
	walllines_known = []
	var MazeSize = Settings.MazeSize
	for y in MazeSize.y:
		for x in MazeSize.x :
			if is_wall_at(x,y,DirLib.Dir.North):
				add_wall_at_raw( x , y , DirLib.Dir.North, walllines_known)
			if is_wall_at(x,y,DirLib.Dir.West):
				add_wall_at_raw( x , y , DirLib.Dir.West, walllines_known)

	for x in MazeSize.x :
		if is_wall_at(x,MazeSize.y-1,DirLib.Dir.South):
			add_wall_at_raw( x , MazeSize.y-1 , DirLib.Dir.South, walllines_known)

	for y in MazeSize.y:
		if is_wall_at(MazeSize.x-1,y,DirLib.Dir.East):
			add_wall_at_raw( MazeSize.x-1 , y , DirLib.Dir.East, walllines_known)

func get_width()->float:
	return Settings.MazeSize.x * map_scale
func get_height()->float:
	return Settings.MazeSize.y * map_scale

func view_full_map()->void:
	for ch in $CharacterContainer.get_children():
		ch.visible = true
	map_mode_full = true
	queue_redraw()

func view_known_map(playernum :int)->void:
	for ch in $CharacterContainer.get_children():
		ch.visible = false
	$CharacterContainer.get_child(playernum).visible = true
	map_mode_full = false
	queue_redraw()

# cell wall[y*2+1][x*2+1]
# wall wall[y*2][x*2]
func calc_wall_pos(x :int, y:int, dir :DirLib.Dir)->Vector2i:
	return Vector2i(x*2+1,y*2+1) + DirLib.Dir2Vt[dir]
func is_wall_at(x :int, y:int, dir :DirLib.Dir)->bool:
	var wpos = calc_wall_pos(x,y,dir)
	return walls_known[wpos.y][wpos.x] != 0
func set_wall_at(x :int, y:int, dir :DirLib.Dir):
	var wpos = calc_wall_pos(x,y,dir)
	walls_known[wpos.y][wpos.x] = 1


func _draw() -> void:
	if map_mode_full:
		draw_multiline(walllines_all,Color(Color.WHITE,0.5), WallThick)
	else:
		if walllines_known.size() == 0 :
			return
		draw_multiline(walllines_known,Color(Color.WHITE,0.5), WallThick)

func add_wall_at_raw(x:int,y :int, dir :DirLib.Dir,wl :PackedVector2Array )->void:
	match dir:
		DirLib.Dir.North:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		DirLib.Dir.West:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		DirLib.Dir.South:
			wl.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		DirLib.Dir.East:
			wl.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])

func add_wall_at(x:int,y :int, dir :DirLib.Dir)->void:
	if is_wall_at(x,y,dir):
		return
	set_wall_at(x,y,dir)
	add_wall_at_raw(x,y,dir,walllines_known)
	queue_redraw()

func update_walls_by_pos(x:int,y :int)->void:
	var walldir = storey.maze_cells.get_wall_dir_at(x,y)
	for d in walldir:
		add_wall_at(x,y,DirLib.Flag2Dir[d])
