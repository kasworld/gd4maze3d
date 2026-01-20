class_name PlayingCard

# ♠♡♣♤♥♧◆◇♩♪♬
const Symbols := ["♠","♥","♦","♣"]
const Numbers := ["A","2","3","4","5","6","7","8","9","10","J","Q","K"]
const Joker := ["★","☆"] # ["☺","☻"]

static func make_deck() -> Array:
	var rtn := []
	for s in Symbols:
		for n in Numbers:
			rtn.append("%s%s" %[s,n])
	return rtn

static func make_deck_with_joker() -> Array:
	var rtn := make_deck()
	rtn.append_array(Joker)
	return rtn
