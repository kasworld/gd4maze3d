extends Node2D

class_name MiniMap

var map_scale :float = 20
var wall_thick :float = 2
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
	walls_known.resize(storey.maze_size.y*2+1)
	for cl in walls_known:
		cl.resize(storey.maze_size.x*2+1)
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
	wall_thick = map_scale*0.1
	if wall_thick < 1 :
		wall_thick = 1
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
	nd.size = Vector2(map_scale-wall_thick*2, map_scale-wall_thick*2)
	nd.label_settings.font_size = map_scale/5

func pos2mapscale(pos :Vector2)->Vector2:
	return pos * map_scale + Vector2(wall_thick,wall_thick)

# make wallline by maze
func make_walllines_all()->void:
	walllines_all = []
	var maze_size = storey.maze_size
	for y in maze_size.y:
		for x in maze_size.x :
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.North):
				add_wall_at_raw( x , y , Storey.Dir.North, walllines_all)
			if not storey.maze_cells.is_open_dir_at(x,y,Maze.Dir.West):
				add_wall_at_raw( x , y , Storey.Dir.West, walllines_all)

	for x in maze_size.x :
		if not storey.maze_cells.is_open_dir_at(x,maze_size.y-1,Maze.Dir.South):
			add_wall_at_raw( x , maze_size.y-1 , Storey.Dir.South, walllines_all)

	for y in maze_size.y:
		if not storey.maze_cells.is_open_dir_at(maze_size.x-1,y,Maze.Dir.East):
			add_wall_at_raw( maze_size.x-1 , y , Storey.Dir.East, walllines_all)

# make wallline by walls_known
func make_walllines_known()->void:
	walllines_known = []
	var maze_size = storey.maze_size
	for y in maze_size.y:
		for x in maze_size.x :
			if is_wall_at(x,y,Storey.Dir.North):
				add_wall_at_raw( x , y , Storey.Dir.North, walllines_known)
			if is_wall_at(x,y,Storey.Dir.West):
				add_wall_at_raw( x , y , Storey.Dir.West, walllines_known)

	for x in maze_size.x :
		if is_wall_at(x,maze_size.y-1,Storey.Dir.South):
			add_wall_at_raw( x , maze_size.y-1 , Storey.Dir.South, walllines_known)

	for y in maze_size.y:
		if is_wall_at(maze_size.x-1,y,Storey.Dir.East):
			add_wall_at_raw( maze_size.x-1 , y , Storey.Dir.East, walllines_known)

func get_width()->float:
	return storey.maze_size.x * map_scale
func get_height()->float:
	return storey.maze_size.y * map_scale

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
func calc_wall_pos(x :int, y:int, dir :Storey.Dir)->Vector2i:
	return Vector2i(x*2+1,y*2+1) + Storey.Dir2Vt[dir]
func is_wall_at(x :int, y:int, dir :Storey.Dir)->bool:
	var wpos = calc_wall_pos(x,y,dir)
	return walls_known[wpos.y][wpos.x] != 0
func set_wall_at(x :int, y:int, dir :Storey.Dir):
	var wpos = calc_wall_pos(x,y,dir)
	walls_known[wpos.y][wpos.x] = 1


func _draw() -> void:
	if map_mode_full:
		draw_multiline(walllines_all,Color(Color.WHITE,0.5), wall_thick)
	else:
		if walllines_known.size() == 0 :
			return
		draw_multiline(walllines_known,Color(Color.WHITE,0.5), wall_thick)

func add_wall_at_raw(x:int,y :int, dir :Storey.Dir,wl :PackedVector2Array )->void:
	match dir:
		Storey.Dir.North:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x+1,y)*map_scale])
		Storey.Dir.West:
			wl.append_array([Vector2(x,y)*map_scale,Vector2(x,y+1)*map_scale])
		Storey.Dir.South:
			wl.append_array([Vector2(x,y+1)*map_scale,Vector2(x+1,y+1)*map_scale])
		Storey.Dir.East:
			wl.append_array([Vector2(x+1,y)*map_scale,Vector2(x+1,y+1)*map_scale])

func add_wall_at(x:int,y :int, dir :Storey.Dir)->void:
	if is_wall_at(x,y,dir):
		return
	set_wall_at(x,y,dir)
	add_wall_at_raw(x,y,dir,walllines_known)
	queue_redraw()

func update_walls_by_pos(x:int,y :int)->void:
	var walldir = storey.maze_cells.get_wall_dir_at(x,y)
	for d in walldir:
		add_wall_at(x,y,Storey.MazeDir2Dir[d])
