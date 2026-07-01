extends MeshInstance3D
class_name MazeBall

var velocity :Vector3
var radius :float
var rot_vel :Vector3
var speed :float
var maze3d :Maze3D
func init(mz :Maze3D, r :float,spd :float, co :Color) -> MazeBall:
	maze3d = mz
	radius = r
	speed = spd
	mesh = BoxMesh.new()
	mesh.size = Vector3(radius*2,radius*2,radius/2)
	mesh.material = CSG.MakeColorMaterial(co)
	mesh.material.metallic = 1.0
	mesh.material.clearcoat_enabled = true
	mesh.material.refraction_enabled = true
	mesh.material.rim_enabled = true
	velocity = Vector3(randf()-0.5,randf()-0.5,randf()-0.5).normalized() * speed
	rot_vel = Vector3(randf()-0.5,randf()-0.5,randf()-0.5).normalized() / PI /2
	var pos3i := maze3d.calc_grid.rand_posi()
	position = maze3d.calc_grid.posi_to_lanepos(pos3i)
	return self

func bounce(delta :float) -> void:
	var oldpos :Vector3 = position
	var newpos :Vector3 = oldpos + velocity * delta
	var bn = maze3d.bounce_cell(oldpos, newpos, radius)
	for i in 3:
		# change vel on bounce
		if bn.bounced[i] != 0 :
			velocity[i] = -bn.bounced[i] * abs(velocity[i]) * (randf() +0.5)
	velocity = velocity.normalized() * speed
	position = bn.pos
	rotation += rot_vel
