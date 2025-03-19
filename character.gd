extends MazeCrawl

class_name Character

var serial :int
var color :Color

func init_char(walk_type :AILib.Walk, n :int, LaneW:float,co :Color) -> Character:
	super.init(walk_type)
	serial = n
	color = co

	var mat = StandardMaterial3D.new()
	mat.albedo_color = co

	var mesh = CylinderMesh.new()
	mesh.height = 0.2*LaneW
	mesh.top_radius = 0.01*LaneW
	mesh.bottom_radius = 0.07*LaneW
	mesh.radial_segments = 5
	mesh.material = mat

	var mi3d = MeshInstance3D.new()
	mi3d.mesh = mesh
	mi3d.rotation.x = -PI/2
	mi3d.scale.x = 0.5
	mi3d.position.x = LaneW*0.2
	add_child(mi3d)

	return self
