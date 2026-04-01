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

func set_size(l :float) -> AxisArrow3D:
	for i in 3:
		$Arrows.get_child(i).set_size(l, l/50, l/20, 0.9)
		$Arrows.get_child(i).position[i] = l/2
		$Labels.get_child(i).position[i] = l/2
		$Labels.get_child(i).font_size = l * 50
	return self
