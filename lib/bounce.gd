class_name Bounce

# wall [axis:3][2]bool : [ [-x,+x], [-y,+y], [-z,+z] ]
static func v3f_wall(pos :Vector3, area :AABB, wall :Array, radius :float)->Dictionary:
	var bounced := Vector3i.ZERO
	for i in 3:
		if wall[i][0] && pos[i] < area.position[i] + radius :
			pos[i] = area.position[i] + radius
			bounced[i] = -1
		elif wall[i][1] && pos[i] > area.end[i] - radius:
			pos[i] = area.end[i] - radius
			bounced[i] = 1
	return {
		bounced = bounced,
		pos = pos,
	}

static func v3f(pos :Vector3, area :AABB, radius :float)->Dictionary:
	var bounced := Vector3i.ZERO
	for i in 3:
		if pos[i] < area.position[i] + radius :
			pos[i] = area.position[i] + radius
			bounced[i] = -1
		elif pos[i] > area.end[i] - radius:
			pos[i] = area.end[i] - radius
			bounced[i] = 1
	return {
		bounced = bounced,
		pos = pos,
	}

static func v2f(pos :Vector2, area :Rect2, radius :float)->Dictionary:
	var bounced := Vector2i.ZERO
	for i in 2:
		if pos[i] < area.position[i] + radius :
			pos[i] = area.position[i] + radius
			bounced[i] = -1
		elif pos[i] > area.end[i] - radius:
			pos[i] = area.end[i] - radius
			bounced[i] = 1
	return {
		bounced = bounced,
		pos = pos,
	}
