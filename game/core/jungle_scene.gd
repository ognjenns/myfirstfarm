class_name JungleScene
## Scenografija džungle iz kupljenog paketa (Mega jungle scene construction,
## gamedeveloperstudio; art/jungle/). Gotova pozadina nosi nebo, izmaglicu i
## siluete daleke šume; preko nje krošnja uz gornju ivicu, debla uz bočne
## ivice, lijane sa vrha i žbunje uz donju ivicu. Sve što je "na tlu" ima
## oslonac na DNU crteža i koren ispod ivice ekrana — ništa ne lebdi.
##
## Sve mere su frakcije ekrana: x/y položaj, i veličina kao deo ŠIRINE
## (by_height=false) ili VISINE (by_height=true) ekrana — visoke stvari
## (debla, lijane) prate visinu, široke (krošnja, žbunje) širinu.

## Od koje visine ekrana počinje smeđa traka tla — životinje stoje na njoj.
const GROUND_Y := 0.84

## Nebo-gradijent iz paketa sa sjajem + smeđa traka tla po dnu (kao na promo
## slici paketa). Traka se crta ovde, a ne u slici, da bi na svakom odnosu
## strana počinjala na istoj visini ekrana; bez nje životinje "lebde".
static func background(parent: Node2D, ground := true) -> void:
	var s := UI.vs(parent)
	var bg := Sprite2D.new()
	bg.texture = load("res://art/jungle/bg.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	parent.add_child(bg)
	if not ground:
		return
	var top := s.y * GROUND_Y
	UI.poly(parent, PackedVector2Array([Vector2(0, top), Vector2(s.x, top), Vector2(s.x, s.y), Vector2(0, s.y)]), Color("#8B5E34"), Vector2.ZERO, -56)
	UI.poly(parent, PackedVector2Array([Vector2(0, top), Vector2(s.x, top), Vector2(s.x, top + 14.0), Vector2(0, top + 14.0)]), Color("#6B4526"), Vector2.ZERO, -55)


## Postavi crtež: anchor (0..1) kaže koja tačka crteža stoji na pos —
## (0.5, 1) je dno-sredina (stoji na tlu), (0.5, 0) vrh-sredina (visi).
static func place(parent: Node2D, art: String, pos: Vector2, size: float, by_height: bool, z: int, anchor := Vector2(0.5, 1.0), flip := false) -> Sprite2D:
	var s := UI.vs(parent)
	var sp := Sprite2D.new()
	sp.texture = load("res://art/jungle/%s.png" % art)
	var tex := sp.texture.get_size()
	var sc: float = (s.y * size) / tex.y if by_height else (s.x * size) / tex.x
	sp.scale = Vector2(-sc if flip else sc, sc)
	sp.offset = Vector2((0.5 - anchor.x) * tex.x * (-1.0 if flip else 1.0), (0.5 - anchor.y) * tex.y)
	sp.position = Vector2(s.x * pos.x, s.y * pos.y)
	sp.z_index = z
	parent.add_child(sp)
	return sp


## Okvir scene: krošnja, debla i lijane — isti na svim ekranima džungle, da
## dete oseti da je u istom svetu. Donja ivica se puni po ekranu posebno
## (hub gusto, igre retko — sredina mora da ostane slobodna za igru).
## Namerno malo: krošnja, deblo sa granom i lijanom levo, deblo desno.
## Prva verzija sa još dva debla, granom i drugom lijanom bila je prenatrpana.
static func frame(parent: Node2D) -> void:
	place(parent, "canopy-1", Vector2(0.50, -0.01), 1.08, false, -45, Vector2(0.5, 0.0))
	place(parent, "trunk-1", Vector2(0.06, 1.02), 1.15, true, -44)
	place(parent, "vine-hang", Vector2(0.84, -0.005), 0.30, true, -42, Vector2(0.5, 0.0))
	place(parent, "trunk-2", Vector2(0.955, 1.02), 1.08, true, -44, Vector2(0.5, 1.0), true)


## Donja ivica za mini-igre: samo žbun u uglovima — sredina prazna.
static func edge_light(parent: Node2D) -> void:
	place(parent, "bush-1", Vector2(0.03, 1.03), 0.13, false, 12)
	place(parent, "bush-3", Vector2(0.97, 1.03), 0.12, false, 12, Vector2(0.5, 1.0), true)
