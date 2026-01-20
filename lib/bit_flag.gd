class_name BitFlag

static func ByPos(pos :int) -> int:
	return 1 << pos

static func SetByPos(pos :int, flags :int) -> int:
	return flags | (1 << pos)

static func ClearByPos(pos :int, flags :int) -> int:
	return flags & ~(1 << pos)

static func TestByPos(pos :int, flags :int) -> bool:
	return flags & (1 << pos)

## 0b101 -> [0,2]
static func MakePosList(flags :int) -> Array[int]:
	var rtn :Array[int] = []
	var pos := 0
	while flags > 0:
		if flags % 2 == 1:
			rtn.append(pos)
		flags >>= 1
		pos += 1
	return rtn

## [0,2] -> 0b101
static func FromPosList(pos_list :Array) -> int:
	var rtn := 0
	for pos in pos_list:
		rtn += (1 << pos)
	return rtn

static func MakeFilledPosList(bit_len :int) -> Array[int]:
	var rtn :Array[int] = []
	for i in bit_len:
		rtn.append(1 << i)
	return rtn

static func MakeFilledFlags(bit_len :int) -> int:
	return (1 << bit_len+1) -1
