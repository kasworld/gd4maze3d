extends Node

const make_line2d_wall_rate = 1.0/40.0
const make_sub_wall_rate = 1.0/20.0
const make_clockcal_wall_rate = 1.0/70.0
const make_donut_capsult_rate = 1.0/2.0
const make_tree_rate = 1.0/40.0

const VisibleStoreyUp :int = 3
const VisibleStoreyDown :int = 3
const maze_size = Vector2i(16*1,9*1)
const storey_h :float = 3.0
const lane_w :float = 4.0
const wall_thick :float = lane_w *0.05
const BallTrailCount = 14
