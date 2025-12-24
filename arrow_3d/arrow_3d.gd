extends Node3D
class_name Arrow3D

func set_size(l :float, body_width :float, head_width :float, body_rate :float = 0.7) -> Arrow3D:
	var head_rate := 1.0 - body_rate
	var shift_rate := (head_rate-body_rate)/2

	# body
	$Body.mesh.height = l *body_rate
	$Body.mesh.bottom_radius = body_width
	$Body.mesh.top_radius = body_width
	$Body.mesh.radial_segments = clampi( int(body_width*2) , 64, 360)
	$Body.position = Vector3(0,-l*body_rate/2-shift_rate*l,0)

	# head
	$Head.mesh.height = l *head_rate
	$Head.mesh.bottom_radius = head_width
	$Head.mesh.top_radius = 0
	$Head.mesh.radial_segments = clampi( int(head_width*2) , 64, 360)
	$Head.position = Vector3(0,l*head_rate/2-shift_rate*l,0)

	return self

func set_color(co :Color) -> Arrow3D:
	$Body.mesh.material.albedo_color = co
	$Head.mesh.material.albedo_color = co
	return self
