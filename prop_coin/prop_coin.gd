extends Node3D
class_name PropCoin

const RRate := 0.95

## face Z+
func init(radius :float, thick :float, co :Color, side :int = 64, front :String ="", back :String="") -> PropCoin:
	var wall := MakeCoinMesh(radius, thick, MakeColorMaterial(co), side, front, back)
	bake.call_deferred(wall)
	return self

func bake(csg :CSGShape3D) -> void:
	$MeshInstance3D.mesh = csg.bake_static_mesh()

static func make_cylinder(raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64) -> CSGShape3D:
	var csg := CSGCylinder3D.new()
	csg.radius = raidus
	csg.height = thick
	csg.sides = side
	csg.material = mat
	return csg

## face Z+
static func MakeCoinMesh(raidus :float, thick :float, mat :StandardMaterial3D, side :int = 64, front :String ="", back :String="") -> CSGShape3D:
	var csg_main := make_cylinder(raidus, thick, mat, side)

	var csg_front := make_cylinder(raidus* RRate, thick/2, mat, side)
	csg_front.position.y = thick /2
	csg_front.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_main.add_child(csg_front)

	var csg_back := make_cylinder(raidus* RRate, thick/2, mat, side)
	csg_back.position.y = -thick /2
	csg_back.operation = CSGShape3D.OPERATION_SUBTRACTION
	csg_main.add_child(csg_back)

	if not front.is_empty():
		var front_text := CSGMesh3D.new()
		front_text.mesh = make_text_mesh(raidus*1.5/back.length(), thick/4, mat, front)
		front_text.material = mat
		front_text.operation = CSGShape3D.OPERATION_UNION
		front_text.rotate_x(-PI/2)
		front_text.position.y = thick /2
		csg_main.add_child(front_text)

	if not back.is_empty():
		var back_text := CSGMesh3D.new()
		back_text.mesh = make_text_mesh(raidus*1.5/back.length(), thick/4, mat, back)
		back_text.material = mat
		back_text.operation = CSGShape3D.OPERATION_UNION
		back_text.rotate_x(PI/2)
		back_text.position.y = -thick /2
		csg_main.add_child(back_text)

	csg_main.rotate_x(PI/2)
	return csg_main

static var font := preload("res://font/HakgyoansimBareondotumR.ttf")
static func make_text_mesh(fsize :float, fdepth :float, mat :Material, text :String) -> Mesh:
	var mesh := TextMesh.new()
	mesh.font = font
	mesh.depth = fdepth
	mesh.pixel_size = fsize / 16
	mesh.text = text
	mesh.material = mat
	return mesh

static func MakeColorMaterial(co :Color, transparent :bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = co
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if transparent else BaseMaterial3D.TRANSPARENCY_DISABLED
	return material
