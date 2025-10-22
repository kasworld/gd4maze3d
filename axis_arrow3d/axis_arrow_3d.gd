extends Node3D
class_name AxisArrow3D

func _ready() -> void:
	$ArrowX.set_color(Color.RED)
	$ArrowY.set_color(Color.GREEN)
	$ArrowZ.set_color(Color.BLUE)

func set_size(l :float) -> AxisArrow3D:
	$ArrowX.set_size(l, l/50, l/20, 0.9)
	$ArrowY.set_size(l, l/50, l/20, 0.9)
	$ArrowZ.set_size(l, l/50, l/20, 0.9)
	$ArrowX.position.x = l/2
	$ArrowY.position.y = l/2
	$ArrowZ.position.z = l/2
	$LabelX.position.x = l/2
	$LabelY.position.y = l/2
	$LabelZ.position.z = l/2
	$LabelX.font_size = l * 50
	$LabelY.font_size = l * 50
	$LabelZ.font_size = l * 50
	return self
