extends MazeCrawl

class_name Character

var serial :int
var color :Color

func init_char(auto :bool, n :int, LaneW:float,co :Color) -> Character:
	super.init(auto)
	var mi3d = Global3d.new_cylinder2( 0.2*LaneW, 0.01*LaneW, 0.07*LaneW, 5,
		Global3d.get_color_mat(co),
		)
	mi3d.rotation.x = -PI/2
	mi3d.scale.x = 0.5
	add_child(mi3d)
	serial = n
	color = co
	return self
