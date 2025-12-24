extends MultiMeshShape
class_name BarTree

func init_bartree_with_color(color_from :Color, color_to:Color, bar_count :int) -> BarTree:
	init_with_alpha(BoxMesh.new(), bar_count, 1.0)
	set_gradient_color_all(color_from, color_to)
	return self

func init_bartree_with_material(mat :Material, bar_count :int) -> BarTree:
	init_with_material(BoxMesh.new(), mat, bar_count)
	return self

# also reset bar rotation
# x : width , y : height , z :depth
func init_bartree_transform(tree_size: Vector3, bar_shift_rate :float) -> BarTree:
	var count :int = get_visible_count()
	# Set the transform of the instances.
	var bar_height := tree_size.y/count
	for i in count:
		var rate := float(i)/(count-1)
		var rev_rate := 1 - rate
		var bar_position := Vector3(0, i *bar_height +bar_height/2, tree_size.x * rev_rate /2 * bar_shift_rate)
		var bar_size := Vector3(tree_size.z * rev_rate, bar_height, tree_size.x * rev_rate )
		var t := Transform3D(Basis(), bar_position)
		t = t.scaled_local( bar_size )
		multimesh.set_instance_transform(i,t )
	return self

func rotate_tree_bar_y(bar_rotation :float) -> void:
	var count :int = get_visible_count()
	for i in count:
		var t :Transform3D = multimesh.get_instance_transform(i)
		var rate := float(i)/(count-1)
		var bar_rot := rate * bar_rotation
		t = t.rotated(Vector3(0,1,0), bar_rot)
		multimesh.set_instance_transform(i,t )
