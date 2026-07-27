class_name Animals
## Sav "sadržaj" igre na jednom mestu — reskin = zameni ovaj fajl + sfx + AnimalFaces.

const LIST := [
	{"id": "cow",     "food": "grass"},
	{"id": "pig",     "food": "apple"},
	{"id": "chicken", "food": "corn"},
	{"id": "goat",    "food": "clover"},
	{"id": "horse",   "food": "carrot"},
	{"id": "duck",    "food": "bread"},
]

static func by_id(id: String) -> Dictionary:
	for a in LIST:
		if a.id == id:
			return a
	return {}

static func random_set(count: int) -> Array:
	var pool := LIST.duplicate()
	pool.shuffle()
	return pool.slice(0, count)
