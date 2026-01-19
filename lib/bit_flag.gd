class_name BitFlag

static func ByPos(pos :int) -> int:
	return 1 << pos

static func SetByPos(pos :int, v :int) -> int:
	return v | (1 << pos)

static func ClearByPos(pos :int, v :int) -> int:
	return v & ~(1 << pos)

static func TestByPos(pos :int, v :int) -> bool:
	return v & (1 << pos)

## 0b101 -> [0,2]
static func MakePosList(v :int) -> Array[int]:
	var rtn :Array[int] = []
	var pos := 0
	while v > 0:
		if v % 2 == 1:
			rtn.append(pos)
		v >>= 1
		pos += 1
	return rtn

## [0,2] -> 0b101
static func FromPosList(pos_list :Array) -> int:
	var rtn := 0
	for pos in pos_list:
		rtn += (1 << pos)
	return rtn
