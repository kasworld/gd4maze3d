extends Node

func bounce3d(position :Vector3, velocity :Vector3, area :AABB, radius :float)->Dictionary:
	var bounced = Vector3i.ZERO
	for i in 3:
		if position[i] < area.position[i] + radius :
			position[i] = area.position[i] + radius
			velocity[i] = abs(velocity[i])
			bounced[i] = -1
		elif position[i] > area.end[i] - radius:
			position[i] = area.end[i] - radius
			velocity[i] = -abs(velocity[i])
			bounced[i] = 1
	return {
		bounced = bounced,
		position = position,
		velocity = velocity,
	}

func bounce2d(position :Vector2, velocity :Vector2, area :Rect2, radius :float)->Dictionary:
	var bounced = Vector2i.ZERO
	for i in 2:
		if position[i] < area.position[i] + radius :
			position[i] = area.position[i] + radius
			velocity[i] = abs(velocity[i])
			bounced[i] = -1
		elif position[i] > area.end[i] - radius:
			position[i] = area.end[i] - radius
			velocity[i] = -abs(velocity[i])
			bounced[i] = 1
	return {
		bounced = bounced,
		position = position,
		velocity = velocity,
	}
