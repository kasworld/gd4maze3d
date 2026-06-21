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
		"Second":s,
		"Args":args,
	}

const QueueLimit = 10
var queue :Array
var action_second :ClampedFloat

## second :action_second = ClampedFloat.new(second,second/range_mod,second*range_mod)
func _init(second :float = 1.0, range_mod :float = 2.0) -> void:
	action_second = ClampedFloat.new(second,second/range_mod,second*range_mod)

func rand_action_second() -> void:
	action_second.rand_clamp()

func clear() -> void:
	queue.resize(0)

func is_empty() -> bool:
	return queue.is_empty()

func pop_front() -> Dictionary:
	return queue.pop_front()

func enqueue(a :Action, args :={}) -> ActionQueue:
	return enqueue_with_second(a, action_second.get_value(), args)

func enqueue_with_second(a :Action,s :float, args :={}) -> ActionQueue:
	queue.push_back(make_action_dictionary(a,s,args))
	return crop()

func crop() -> ActionQueue:
	if queue.size() > QueueLimit:
		queue = queue.slice(queue.size()-QueueLimit)
	return self

func _to_string() -> String:
	var rtn := "ActionQueue["
	for a in queue:
		rtn += "%s(%.1f)%s " % [ action2str(a.Action), a.Second, a.Args ]
	rtn += "]"
	return rtn
