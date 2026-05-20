extends Node3D
class_name AxisArrow3D

var colors := [Color.RED, Color.GREEN, Color.BLUE]
var label_text := ["X", "Y", "Z"]
func set_colors(colist :Array = colors) -> AxisArrow3D:
	for i in 3:
		$Arrows.get_child(i).set_material( make_color_material(colist[i]) )
	return self

func make_color_material(co :Color) -> StandardMaterial3D:
	var mat := MultiMeshShape.MakeMultiMeshColorMaterial()
	mat.metallic = 1.0
	mat.clearcoat_enabled = true
	mat.refraction_enabled = true
	mat.rim_enabled = true
	mat.albedo_color = co
	mat.emission_enabled = true
	mat.emission = co
	return mat

func set_label_text(text_list :Array = label_text) -> AxisArrow3D:
	for i in 3:
		$Labels.get_child(i).text = text_list[i]
	return self

func set_size(l :float, body_width :float = 0, head_width :float = 0, body_rate :float = 0) -> AxisArrow3D:
	if body_width == 0:
		body_width = l/ 50
	if head_width == 0:
		head_width = l/ 20
	if body_rate == 0:
		body_rate = 0.9
	for i in 3:
		$Arrows.get_child(i).set_size(l, body_width, head_width, body_rate)
		$Arrows.get_child(i).position[i] = l/2
	set_label(body_width*4 , 0.5)
	return self

func set_label(font_size :float, label_pos_rate :float) -> AxisArrow3D:
	var l :float = $Arrows/ArrowX.get_length()
	for i in 3:
		$Labels.get_child(i).position[i] = l * label_pos_rate
		$Labels.get_child(i).pixel_size = font_size / 16
	return self
