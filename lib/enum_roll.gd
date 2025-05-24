class_name EnumRoll

enum Dir {Up,Right,Down,Left}
static func dir2str(vd :Dir) -> String:
	return Dir.keys()[vd]
static func dir2rad(d:Dir) -> float:
	return deg_to_rad(d*90.0)


static func roll_left(d:Dir) -> Dir:
	return (d+1)%4 as Dir
static func roll_right(d:Dir) -> Dir:
	return (d-1+4)%4 as Dir
static func roll_opposite(d:Dir) -> Dir:
	return (d+2)%4 as Dir
