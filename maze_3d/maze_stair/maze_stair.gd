extends WireNet
class_name MazeStair

func init_stair(unit_size :Vector3, dir :Maze.Dir, co :Color) -> MazeStair:
	super.init_wire_H(
		Vector2(unit_size.x*0.5, unit_size.z*0.9),
		Vector2i(2,6),
		unit_size.y/20,
		unit_size.y/5,
		co,
		false)
	init_wire_V(
		Vector2(unit_size.x*0.5, unit_size.z),
		Vector2i(2,6),
		unit_size.y/30,
		unit_size.y/30,
		co,
		false)
	wire_H_rotation_x = PI/4
	rotation.x = -PI/4
	rotation.y = Maze.DirToRadian(dir)
	return self
