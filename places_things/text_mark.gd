extends MeshInstance3D
class_name TextMark

var font = preload("res://font/HakgyoansimBareondotumR.ttf")

var minimap_posi :Vector2i
func get_minimap_posi() -> Vector2i:
	return minimap_posi
func set_minimap_posi(posi :Vector2i) -> TextMark:
	minimap_posi = posi
	return self

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

func get_color() -> Color:
	return mesh.material.albedo_color

var auto_rotate :bool = true
func _process(delta: float) -> void:
	if auto_rotate:
		rotate_y(delta)
