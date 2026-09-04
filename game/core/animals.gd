class_name Animals
## Sav "sadržaj" igre na jednom mestu — reskin = zameni ovaj fajl + sfx + AnimalFaces.

## Žirafa i nilski konj namerno nemaju snimljeno glasanje — prava rika bi
## plašila decu. Njihov "glas" je mirno žvakanje, što ima smisla dok jedu,
## ali NE u pogađalici zvukova ni kao reakcija na kupanje.
const SILENT := ["giraffe", "hippo"]

const LIST := [
	# Hrana su kupljeni crteži povrća (art/food/<food>.png), 03.09.2026.
	{"id": "cow",     "food": "lettuce"},
	{"id": "pig",     "food": "pumpkin"},
	{"id": "chicken", "food": "sweetcorn"},
	{"id": "goat",    "food": "broccoli"},
	{"id": "horse",   "food": "carrots"},
	{"id": "duck",    "food": "peas"},
]

## Hrana džungle su kupljeni crteži (art/food/): banana, jabuka, list iz
## džungla-paketa, kukuruz, lubenica. Samo meso za lava je još naš crtež.
const JUNGLE := [
	{"id": "monkey",   "food": "banana"},
	{"id": "elephant", "food": "apple"},
	{"id": "giraffe",  "food": "leaves"},
	{"id": "lion",     "food": "meat"},
	{"id": "parrot",   "food": "sweetcorn"},
	{"id": "hippo",    "food": "watermelon"},
]

## OKEAN — treći svet. Šest bića sa jasno različitim siluetama, da ih dete
## razlikuje i kad su mala na ekranu. "food" stoji radi jednoobraznosti sa
## ostalim svetovima; okean za sada nema igru hranjenja.
const OCEAN := [
	{"id": "fish",     "food": "flakes"},
	{"id": "octopus",  "food": "shrimp"},
	{"id": "turtle",   "food": "kelp"},
	{"id": "crab",     "food": "algae"},
	{"id": "dolphin",  "food": "sardine"},
	{"id": "seahorse", "food": "plankton"},
]

## DINOSAURUSI — četvrti svet. Siluete se razlikuju i kad su sitne: velika
## glava sa kratkim rukama, dug vrat, rogovi i kragna, pločice na leđima,
## krila, kugla na repu. "food" stoji radi jednoobraznosti — dino svet, kao
## ni okean, nema igru hranjenja.
const DINO := [
	{"id": "trex",   "food": "meat"},
	{"id": "bronto", "food": "leaves"},
	{"id": "trike",  "food": "fern"},
	{"id": "stego",  "food": "moss"},
	{"id": "ptero",  "food": "berries"},
	{"id": "anky",   "food": "roots"},
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

static func by_id_ocean(id: String) -> Dictionary:
	for a in OCEAN:
		if a.id == id:
			return a
	return {}

static func by_id_dino(id: String) -> Dictionary:
	for a in DINO:
		if a.id == id:
			return a
	return {}


static func random_set(count: int, from_list := LIST) -> Array:
	var pool := from_list.duplicate()
	pool.shuffle()
	return pool.slice(0, count)
