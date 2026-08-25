#!/usr/bin/env python3
"""Naslovi svetova kao SVG — MY FARM / MY JUNGLE / MY OCEAN.

U igri postoje samo ta tri natpisa, pa je ceo font bio prevelik alat: ovako
slova nose stil igre (debeo zaobljen potez, tamna kontura) i ne vučemo licencu
ni jedan dodatni fajl.

Svako slovo je POTEZ, ne popunjen oblik: iscrta se dvaput — deblje tamnom
bojom pa tanje bojom sveta. Time se kontura i ispuna dobijaju iz iste putanje,
pa je debljina svuda ista bez ručnog crtanja obrisa.
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "game", "art", "svg")
INK = "#4A3F3A"

# Ćelija slova je 100×100; osnovna linija y=90, visina velikog slova od y=10.
GLYPHS = {
	"M": "M12,90 L12,14 L50,62 L88,14 L88,90",
	"Y": "M12,14 L50,52 L88,14 M50,52 L50,90",
	"F": "M18,90 L18,14 L84,14 M18,50 L68,50",
	"A": "M12,90 L50,14 L88,90 M28,62 L72,62",
	"R": "M18,90 L18,14 L58,14 A21,21 0 0 1 58,56 L18,56 M52,56 L86,90",
	"J": "M74,14 L74,62 A26,26 0 0 1 22,62",
	"U": "M14,14 L14,58 A36,34 0 0 0 86,58 L86,14",
	"N": "M14,90 L14,14 L86,90 L86,14",
	"G": "M84,32 A38,40 0 1 0 84,72 L84,56 L58,56",
	"L": "M20,14 L20,90 L84,90",
	"E": "M84,14 L20,14 L20,90 L84,90 M20,50 L70,50",
	"O": "M50,14 A36,38 0 1 0 50.1,14 Z",
	"C": "M84,30 A37,40 0 1 0 84,74",
}

ADV = {"M": 108, "N": 100, "O": 100, "G": 100, "U": 100, "Y": 96, "A": 100,
	"R": 96, "F": 92, "E": 96, "L": 92, "J": 88, "C": 98}
SPACE = 46


def word_svg(text: str, tint: str, path: str) -> None:
	x = 0.0
	parts = []
	for ch in text:
		if ch == " ":
			x += SPACE
			continue
		g = GLYPHS[ch]
		parts.append((x, g))
		x += ADV[ch]
	w = x
	h = 104
	pad = 22          # mesta za debelu konturu da se ne odseče

	def layer(width: int, color: str) -> str:
		out = []
		for ox, d in parts:
			out.append('<path d="%s" transform="translate(%.1f 0)" fill="none" '
				'stroke="%s" stroke-width="%d" stroke-linecap="round" '
				'stroke-linejoin="round"></path>' % (d, ox, color, width))
		return "\n  ".join(out)

	svg = (
		'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" '
		'viewBox="%d %d %d %d">\n  %s\n  %s\n</svg>\n'
		% (int(w + pad * 2), h + pad * 2, -pad, -pad, int(w + pad * 2), h + pad * 2,
			layer(30, INK), layer(18, tint))
	)
	with open(os.path.join(OUT, path), "w") as f:
		f.write(svg)
	print("  %-20s %d×%d" % (path, int(w + pad * 2), h + pad * 2))


print("naslovi ->", os.path.abspath(OUT))
word_svg("MY FARM", "#6FAE64", "title-farm.svg")      # zelena farme
word_svg("MY JUNGLE", "#4E8C48", "title-jungle.svg")  # zelena džungle
word_svg("MY OCEAN", "#3E8FB0", "title-ocean.svg")    # plava okeana
