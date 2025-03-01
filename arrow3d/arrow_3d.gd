extends Node3D
class_name Arrow3D

func init(l :float, co :Color, body_width :float, head_width :float, body_rate :float = 0.7) -> Arrow3D:
	var head_rate := 1.0 - body_rate
	var shift_rate := (head_rate-body_rate)/2

	var mat := StandardMaterial3D.new()
	mat.albedo_color = co

	# body
	var bodyMesh := CylinderMesh.new()
	bodyMesh.height = l *body_rate
	bodyMesh.bottom_radius = body_width
	bodyMesh.top_radius = body_width
	bodyMesh.radial_segments = clampi( int(body_width*2) , 64, 360)
	bodyMesh.material = mat
	$Body.mesh = bodyMesh
	$Body.position = Vector3(0,-l*body_rate/2-shift_rate*l,0)

	# head
	var headMesh := CylinderMesh.new()
	headMesh.height = l *head_rate
	headMesh.bottom_radius = head_width
	headMesh.top_radius = 0
	headMesh.radial_segments = clampi( int(head_width*2) , 64, 360)
	headMesh.material = mat
	$Head.mesh = headMesh
	$Head.position = Vector3(0,l*head_rate/2-shift_rate*l,0)

	return self
