extends MeshInstance3D
class_name TextMark

var font = preload("res://font/HakgyoansimBareondotumR.ttf")

var posi :Vector2i
func get_posi() -> Vector2i:
	return posi

func init(fsize :float, fdepth :float, co:Color, text :String, posi_a :Vector2i) -> TextMark:
	posi = posi_a
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

func get_color() -> Color:
	return mesh.material.albedo_color

var auto_rotate :bool = true
func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(delta)
