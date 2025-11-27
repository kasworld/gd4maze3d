extends Node3D
class_name AxisArrow3D

var arrow_list :Array
var colors := [Color.RED, Color.GREEN, Color.BLUE]
var label_list :Array
var label_text := ["X", "Y", "Z"]
func _ready() -> void:
	for i in 3:
		var ar :Arrow3D = preload("res://arrow3d/arrow_3d.tscn").instantiate()
		ar.set_color(colors[i])
		arrow_list.append(ar)
		add_child(ar)

		var lb := Label3D.new()
		lb.text = label_text[i]
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label_list.append(lb)
		add_child(lb)

	arrow_list[0].rotation.z = -PI/2
	#arrow_list[1].rotation.y = PI/2
	arrow_list[2].rotation.x = PI/2

func set_size(l :float) -> AxisArrow3D:
	for i in 3:
		arrow_list[i].set_size(l, l/50, l/20, 0.9)
		arrow_list[i].position[i] = l/2
		label_list[i].position[i] = l/2
		label_list[i].font_size = l * 50
	return self
