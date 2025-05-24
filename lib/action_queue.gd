class_name ActionQueue

const QueueLimit = 10
var queue :Array
var action_per_second := ClampedFloat.new(2,0.5,4.5) # sec

func init() -> ActionQueue:
	rand_act_speed()
	return self

func rand_act_speed() -> void:
	action_per_second.set_randfn()
	
func clear() -> void:
	queue.resize(0)
	
func is_empty() -> bool:
	return queue.size() == 0
	
func pop_front():
	return queue.pop_front()

func enqueue_action(a :EnumAction.Action, args :=[]) -> ActionQueue:
	queue.push_back([a,action_per_second.get_value(), args])
	crop_queue()
	return self
	
func enqueue_action_with_speed(a :EnumAction.Action,s :float, args :=[]) -> ActionQueue:
	queue.push_back([a,s, args])
	crop_queue()
	return self
	
func crop_queue() -> ActionQueue:
	if queue.size() > QueueLimit:
		queue = queue.slice(queue.size()-QueueLimit)
	return self

func _to_string() -> String:
	var rtn = "ActionQueue "
	for a in queue:
		rtn += "%s(%.1f)%s " % [ EnumAction.action2str(a[0]), a[1], a[2] ]
	return rtn
