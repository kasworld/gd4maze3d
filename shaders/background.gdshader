shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = vec4( sin((UV.x)*4.0+TIME/3.0)/2.0+0.5, sin((UV.y)*3.0+TIME/1.0)/2.0+0.5, sin((UV.y+UV.y)+TIME/2.0)/2.0+0.5, 1.0);
	// COLOR = vec4( sin((UV.x)*4.0+TIME/3.0)/2.0+0.5, sin((UV.y)*3.0+TIME/1.0)/2.0+0.5, sin((UV.y+UV.y)+TIME/2.0)/2.0+0.5, 1.0)*0.5 + COLOR*0.5;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
