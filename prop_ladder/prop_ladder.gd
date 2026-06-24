extends WireNet
class_name PropLadder

func init_ladder(unit_size :Vector3, dir :Maze.Dir, co :Color) -> PropLadder:
	init_wire_H(
		Vector2(unit_size.x*0.5, unit_size.y*0.8),
		Vector2i(0,6),
		unit_size.y/30,
		unit_size.y/30,
		co,
		false)
	init_wire_V(
		Vector2(unit_size.x*0.5, unit_size.y),
		Vector2i(2,6),
		unit_size.y/30,
		unit_size.y/30,
		co,
		false)
	rotation.y = Maze.DirToRadian(dir)
	return self
