class_name FlyNode3D

# for free fly camera

const Key2Info := {
	KEY_UP: ["rotation", "x", PI/180],
	KEY_DOWN: ["rotation", "x", -PI/180],
	KEY_LEFT: ["rotation", "y", PI/180],
	KEY_RIGHT: ["rotation", "y", -PI/180],
	KEY_A: ["position", "x", -1],
	KEY_D: ["position", "x", 1],
	KEY_W: ["position", "z", -1],
	KEY_S: ["position", "z", 1],
	KEY_Q: ["position", "y", -1],
	KEY_E: ["position", "y", 1],
}

# flyinfo : [node3d field, axis, amount]
static func fly_node3d(nd :Node3D, flyinfo :Array) -> void:
	var field :String = flyinfo[0]
	var axis :int = {
		"x" :0,
		"y" :1,
		"z" :2,
	} [flyinfo[1]]
	match field:
		"position":
			var mv := Vector3.ZERO
			mv[axis] += flyinfo[2]
			nd.transform = nd.transform.translated_local(mv)
		"rotation":
			nd.rotation[axis] += flyinfo[2]
		"scale":
			nd.scale[axis] += flyinfo[2]
