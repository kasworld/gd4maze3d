extends Node3D
class_name TextMark

var font = preload("res://HakgyoansimBareondotumR.ttf")
var text :String

func init(fsize :float, fdepth :float, co:Color, atext :String) -> TextMark:
	text = atext
	var mat = StandardMaterial3D.new()
	mat.albedo_color = co
	var mesh = TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 100
	mesh.font_size = fsize
	mesh.text = text
	mesh.material = mat
	var sp = MeshInstance3D.new()
	sp.mesh = mesh
	add_child(sp)
	return self

func get_text() -> String:
	return text
