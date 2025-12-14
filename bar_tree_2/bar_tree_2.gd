extends MultiMeshShape

class_name BarTree2

func init_bar_with_color(color_from :Color, color_to:Color, bar_count :int) -> BarTree2:
	init_with_color(BoxMesh.new(), Color.WHITE, bar_count)
	set_gradient_color(color_from, color_to)
	return self

func init_bar_with_material(mat :Material, bar_count :int) -> BarTree2:
	init_with_material(BoxMesh.new(), mat, bar_count)
	return self

# also reset bar rotation
func init_bar_transform(
		tree_width: float,
		tree_height :float,
		bar_width :float,
		bar_shift_rate :float,
	) -> BarTree2:
	var count :int = get_visible_count()
	# Set the transform of the instances.
	var bar_height := tree_height/count
	for i in count:
		var rate := float(i)/(count-1)
		var rev_rate := 1 - rate
		var bar_position := Vector3(0, i *bar_height +bar_height/2, tree_width * rev_rate /2 * bar_shift_rate)
		var bar_size := Vector3(bar_width * rev_rate, bar_height, tree_width * rev_rate )
		var t := Transform3D(Basis(), bar_position)
		t = t.scaled_local( bar_size )
		multimesh.set_instance_transform(i,t )
	return self

func rotate_bar_y(bar_rotation :float) -> void:
	var count :int = get_visible_count()
	for i in count:
		var t :Transform3D = multimesh.get_instance_transform(i)
		var rate := float(i)/(count-1)
		var bar_rot := rate * bar_rotation
		t = t.rotated(Vector3(0,1,0), bar_rot)
		multimesh.set_instance_transform(i,t )
