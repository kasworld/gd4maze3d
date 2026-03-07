extends MeshInstance3D
class_name TextMark

var font = preload("res://font/HakgyoansimBareondotumR.ttf")

func init(fsize :float, fdepth :float, co:Color, text :String) -> TextMark:
	mesh = TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 16
	mesh.text = text
	mesh.material = StandardMaterial3D.new()
	mesh.material.albedo_color = co
	return self

func get_text() -> String:
	return mesh.text

var auto_rotate :bool = true
func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(delta)
