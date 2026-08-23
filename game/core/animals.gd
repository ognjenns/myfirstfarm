class_name Animals
## Sav "sadržaj" igre na jednom mestu — reskin = zameni ovaj fajl + sfx + AnimalFaces.

## Žirafa i nilski konj namerno nemaju snimljeno glasanje — prava rika bi
## plašila decu. Njihov "glas" je mirno žvakanje, što ima smisla dok jedu,
## ali NE u pogađalici zvukova ni kao reakcija na kupanje.
const SILENT := ["giraffe", "hippo"]

const LIST := [
	{"id": "cow",     "food": "grass"},
	{"id": "pig",     "food": "apple"},
	{"id": "chicken", "food": "corn"},
	{"id": "goat",    "food": "clover"},
	{"id": "horse",   "food": "carrot"},
	{"id": "duck",    "food": "bread"},
]

const JUNGLE := [
	{"id": "monkey",   "food": "banana"},
	{"id": "elephant", "food": "peanut"},
	{"id": "giraffe",  "food": "leaves"},
	{"id": "lion",     "food": "meat"},
	{"id": "parrot",   "food": "seeds"},
	{"id": "hippo",    "food": "watermelon"},
]

static func by_id(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}

static func by_id_jungle(id: String) -> Dictionary:
	for a in JUNGLE:
		if a.id == id:
			return a
	return {}

static func random_set(count: int, from_list := LIST) -> Array:
	var pool := from_list.duplicate()
	pool.shuffle()
	return pool.slice(0, count)
