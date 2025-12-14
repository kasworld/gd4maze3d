extends Node3D
class_name BarGauge

signal max_reached( b :BarGauge)
signal zero_reached( b :BarGauge)

var max_value :int
var current_value :int

func init(count :int, sz :Vector3, co1 :Color, co2 :Color, alpha :float = 1.0 , gaprate :float = 0.1) -> BarGauge:
	max_value = count
	current_value = max_value

	var mesh := BoxMesh.new()
	mesh.size = Vector3(sz.x, sz.y / count * (1-gaprate) , sz.z)

	$MultiMeshShape.init_with_color(mesh, Color(Color.WHITE, alpha), count)
	for i in count:
		var rate := (i as float) / (count as float)
		var pos3d := Vector3(0,rate*sz.y,0) # grow upward
		$MultiMeshShape.set_inst_pos(i, pos3d)
		$MultiMeshShape.set_inst_color(i, lerp(co1, co2, rate) )
	return self

func normalize_current_value() -> void:
	if current_value <= 0:
		current_value = 0
		zero_reached.emit(self)
	elif current_value >= max_value:
		current_value = max_value
		max_reached.emit(self)

func set_current_value( i :int) -> void:
	current_value = i
	normalize_current_value()
	$MultiMeshShape.set_visible_count(current_value)

func inc_current_value( n :int = 1 ) -> void:
	current_value += n
	normalize_current_value()
	$MultiMeshShape.set_visible_count(current_value)

func dec_current_value( n :int = 1 ) -> void:
	current_value -= n
	normalize_current_value()
	$MultiMeshShape.set_visible_count(current_value)

func set_current_rate( v :float) -> void:
	current_value = int(v * max_value)
	normalize_current_value()
	$MultiMeshShape.set_visible_count(current_value)

func calc_current_rate() -> float:
	return float(current_value) / float(max_value)
