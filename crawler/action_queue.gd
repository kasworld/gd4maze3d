class_name ActionQueue

enum Action {EnterStorey, Forward, TurnRight, TurnLeft, TurnRight2, TurnLeft2, RollRight, RollLeft, RollRight2, RollLeft2}
static func action2str(a :Action) -> String:
	return Action.keys()[a]

# action stats == Dictionary
static func new_stats() -> Dictionary:
	var rtn := {}
	for k in Action.values():
		rtn[k]=0
	return rtn
static func stats2str(d:Dictionary) -> String:
	var rtn := ""
	for i in Action.values():
		rtn += " %s:%d" % [action2str(i), d[i]]
	return rtn

static func make_action_dictionary(a :Action,s :float, args :={}) -> Dictionary:
	return {
		"Action":a,
		"APS":s,
		"Args":args,
	}

const QueueLimit = 10
var queue :Array
var action_per_second :ClampedFloat

## aps :action_per_second = ClampedFloat.new(aps,aps/range_mod,aps*range_mod)
func _init(aps :float = 1.0, range_mod :float = 2.0) -> void:
	action_per_second = ClampedFloat.new(aps,aps/range_mod,aps*range_mod)

func rand_act_speed() -> void:
	action_per_second.rand_clamp()

func clear() -> void:
	queue.resize(0)

func is_empty() -> bool:
	return queue.is_empty()

func pop_front() -> Dictionary:
	return queue.pop_front()

func enqueue(a :Action, args :={}) -> ActionQueue:
	return enqueue_with_speed(a, action_per_second.get_value(), args)

func enqueue_with_speed(a :Action,s :float, args :={}) -> ActionQueue:
	queue.push_back(make_action_dictionary(a,s,args))
	return crop()

func crop() -> ActionQueue:
	if queue.size() > QueueLimit:
		queue = queue.slice(queue.size()-QueueLimit)
	return self

func _to_string() -> String:
	var rtn := "ActionQueue["
	for a in queue:
		rtn += "%s(%.1f)%s " % [ action2str(a.Action), a.APS, a.Args ]
	rtn += "]"
	return rtn
