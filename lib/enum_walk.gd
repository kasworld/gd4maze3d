class_name EnumWalk

enum Walk {Off, RightFirst, LeftFirst}
static func walk2str(a :Walk) -> String:
	return Walk.keys()[a]

static func next(a :Walk) -> Walk:
	return (a +1) % Walk.keys().size() as Walk
