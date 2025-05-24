class_name EnumDir

enum Dir {
	North = 0,
	West = 1,
	South = 2,
	East = 3,
}
const DirList = [Dir.North,Dir.West,Dir.South,Dir.East]

const DirToStr = {
	Dir.North : "North",
	Dir.West : "West",
	Dir.South : "South",
	Dir.East : "East",
}
const DirOpppsite = {
	Dir.North : Dir.South,
	Dir.West : Dir.East,
	Dir.South : Dir.North,
	Dir.East : Dir.West,
}
const DirTurnLeft = {
	Dir.North : Dir.West,
	Dir.West : Dir.South,
	Dir.South : Dir.East,
	Dir.East : Dir.North,
}
const DirTurnRight = {
	Dir.North : Dir.East,
	Dir.East : Dir.South,
	Dir.South : Dir.West,
	Dir.West : Dir.North,
}

const Dir2Vt = {
	Dir.North : Vector2i(0,-1),
	Dir.West : Vector2i(-1,0),
	Dir.South : Vector2i(0, 1),
	Dir.East : Vector2i(1,0),
}

static func dir2rad(d:Dir) -> float:
	return deg_to_rad(d *90.0)

enum Flag {
	North = 1 << Dir.North,
	West = 1 << Dir.West,
	South = 1 << Dir.South,
	East = 1 << Dir.East,
}
const FlagList = [Flag.North,Flag.West,Flag.South,Flag.East]

const Flag2Dir = {
	Flag.North : Dir.North,
	Flag.West : Dir.West,
	Flag.South : Dir.South,
	Flag.East : Dir.East,
}
const Dir2Flag = {
	Dir.North : Flag.North,
	Dir.West : Flag.West,
	Dir.South : Flag.South,
	Dir.East : Flag.East,
}
const Flag2Str = {
	Flag.North : "North",
	Flag.West : "West",
	Flag.South : "South",
	Flag.East : "East",
}

const FlagOpppsite = {
	Flag.North : Flag.South,
	Flag.West : Flag.East,
	Flag.South : Flag.North,
	Flag.East : Flag.West,
}
const FlagTurnLeft = {
	Flag.North : Flag.West,
	Flag.West : Flag.South,
	Flag.South : Flag.East,
	Flag.East : Flag.North,
}
const FlagTurnRight = {
	Flag.North : Flag.East,
	Flag.East : Flag.South,
	Flag.South : Flag.West,
	Flag.West : Flag.North,
}
const Flag2Vt = {
	Flag.North : Vector2i(0,-1),
	Flag.West : Vector2i(-1,0),
	Flag.South : Vector2i(0, 1),
	Flag.East : Vector2i(1,0),
}
