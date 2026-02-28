extends MeshInstance3D
class_name MazeBall

var velocity :Vector3
var radius :float
var rot_vel :Vector3
var speed_min :float
var speed_max :float
var maze3d :Maze3D
func init(co :Color, mz :Maze3D) -> MazeBall:
	maze3d = mz
	speed_min = maze3d.maze3d_setting.LaneW
	speed_max = speed_min * 2
	radius = maze3d.maze3d_setting.LaneW / 10
	mesh = BoxMesh.new()
	mesh.size = Vector3(radius*2,radius*2,radius/2)
	mesh.material = MultiMeshShape.make_color_material()
	mesh.material.albedo_color = co
	mesh.material.metallic = 1.0
	mesh.material.clearcoat_enabled = true
	mesh.material.refraction_enabled = true
	mesh.material.rim_enabled = true
	velocity = Vector3(randf()-0.5,randf()-0.5,randf()-0.5).normalized() * maze3d.maze3d_setting.LaneW
	rot_vel = Vector3(randf()-0.5,randf()-0.5,randf()-0.5).normalized() / PI /2
	var pos2d := maze3d.maze3d_setting.rand_pos_2i()
	position = maze3d.maze3d_setting.mazepos2storeypos(pos2d, maze3d.maze3d_setting.StoryH/2)
	return self

func bounce(delta :float) -> void:
	var oldpos :Vector3 = position
	var newpos :Vector3 = oldpos + velocity * delta
	var bn = maze3d.bounce_cell(oldpos, newpos, radius)
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			velocity[i] = -bn.bounced[i] * abs(velocity[i]) * (randf() +0.5)
	velocity = velocity.normalized() * speed_max
	position = bn.pos
	rotation += rot_vel
