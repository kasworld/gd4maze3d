class_name Tarot

const MajorArcana = [
	["0", "The Fool"],
	["I", "The Magician"],
	["II", "The High Priestess"],
	["III", "The Empress"],
	["IV", "The Emperor"],
	["V", "The Hierophant"],
	["VI", "The Lovers"],
	["VII", "The Chariot"],
	["VIII", "Strength"],
	["IX", "The Hermit"],
	["X", "Wheel of Fortune"],
	["XI", "Justice"],
	["XII", "The Hanged Man"],
	["XIII", "Death"],
	["XIV", "Temperance"],
	["XV", "The Devil"],
	["XVI", "The Tower"],
	["XVII", "The Star"],
	["XVIII", "The Moon"],
	["XIX", "The Sun"],
	["XX", "Judgement"],
	["XXI", "The World"],
]

const MinorArcanaSuits = ["Wands", "Cups", "Swords", "Pentacles"]
const MinorArcanaNumbers = ["A","2","3","4","5","6","7","8","9","10","P","K","Q","K"]
const MinorArcanaNames = ["Ace","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Page","Knight","Queen","King"]

static func make_MinorArcana_number_deck() -> Array:
	var rtn := []
	for s in MinorArcanaSuits:
		for n in MinorArcanaNumbers:
			rtn.append("%s %s" %[n,s])
	return rtn

static func make_MinorArcana_name_deck() -> Array:
	var rtn := []
	for s in MinorArcanaSuits:
		for n in MinorArcanaNames:
			rtn.append("%s of %s" %[n,s])
	return rtn

static func make_MajorArcana_deck() -> Array:
	var rtn := []
	for c in MajorArcana:
		rtn.append("%s - %s" %[c[0],c[1]])
	return rtn

static func make_MajorArcana_number_deck() -> Array:
	var rtn := []
	for c in MajorArcana:
		rtn.append("%s" %c[0])
	return rtn

static func make_MajorArcana_name_deck() -> Array:
	var rtn := []
	for c in MajorArcana:
		rtn.append("%s" %c[1])
	return rtn

static func make_full_deck() -> Array:
	var rtn := make_MinorArcana_name_deck()
	rtn.append_array(make_MajorArcana_deck())
	return rtn

static func make_full_name_deck() -> Array:
	var rtn := make_MinorArcana_name_deck()
	rtn.append_array(make_MajorArcana_name_deck())
	return rtn

static func make_full_number_deck() -> Array:
	var rtn := make_MinorArcana_number_deck()
	rtn.append_array(make_MajorArcana_number_deck())
	return rtn
