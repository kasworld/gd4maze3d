class_name RandomColor

static func green_rate(rate :float=0.6) -> Color:
	return Color(randf_range(0,1-rate),randf_range(rate,1.0),randf_range(0,1-rate))
static func red_rate(rate :float=0.6) -> Color:
	return Color(randf_range(rate,1.0),randf_range(0,1-rate),randf_range(0,1-rate))
static func blue_rate(rate :float=0.6) -> Color:
	return Color(randf_range(0,1-rate),randf_range(0,1-rate),randf_range(rate,1.0))

static func green_pure() -> Color:
	return Color(0,randf(),0)
static func red_pure() -> Color:
	return Color(randf(),0,0)
static func blue_pure() -> Color:
	return Color(0,0,randf())

## all random color use rate_color([],0)
static func rate_color(high_index_list :Array, rate :float=0.6) -> Color:
	var rtn := Color(0,0,0)
	for i in high_index_list: # make high
		rtn[i] = randf_range(rate,1.0)
	for i in 3: # make low
		if rtn[i] == 0.0:
			rtn[i] = randf_range(0,1-rate)
	return rtn

static func pure_color(index_list :Array, begin :float = 0.0, end :float = 1.0) -> Color:
	var rtn := Color(0,0,0)
	var v := randf_range(begin, end)
	for i in index_list:
		rtn[i] = v
	return rtn
