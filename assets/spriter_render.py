#!/usr/bin/env python3
"""Mali renderer za Spriter (.scml) fajlove iz gamedeveloperstudio paketa.

Sklapa sličice animacija od PNG delova, sa mogućnošću da se pojedini delovi
ZAMENE (npr. obrve lava — kupljene su namrštene, mi hoćemo blage). Kupljeni
keyframe-ovi su već "spljošteni", pa se bez ovoga izraz lica ne može menjati.

Podržano: kosti sa roditeljima, objekti sa pivotom, skaliranje (i negativno =
ogledanje), providnost, linearna interpolacija sa spin-om, petlja. Krive
(bezier i sl.) nisu — paketi ih ne koriste.

Koordinate u Spriter-u su y-NAGORE, uglovi u stepenima, suprotno od kazaljke.
"""
import math, os, sys
import xml.etree.ElementTree as ET
from PIL import Image, ImageChops, ImageMath


def _f(el, name, default):
    v = el.get(name)
    return float(v) if v is not None else default


class Spriter:
    def __init__(self, scml_path, parts_dir=None, overrides=None, adjust=None):
        self.dir = parts_dir or os.path.dirname(scml_path)
        self.overrides = overrides or {}   # ime fajla dela -> putanja do zamene
        # ime fajla dela -> {"angle": stepeni, "dx"/"dy": pomak u svetu, "hide": True}
        self.adjust = adjust or {}
        root = ET.parse(scml_path).getroot()
        self.files = {}
        for folder in root.findall('folder'):
            fid = int(folder.get('id'))
            for f in folder.findall('file'):
                self.files[(fid, int(f.get('id')))] = {
                    'name': f.get('name'), 'w': float(f.get('width')), 'h': float(f.get('height')),
                    'px': _f(f, 'pivot_x', 0.0), 'py': _f(f, 'pivot_y', 1.0)}
        self.entities = {}
        for ent in root.findall('entity'):
            anims = {}
            for an in ent.findall('animation'):
                timelines = {}
                for tl in an.findall('timeline'):
                    keys = []
                    for k in tl.findall('key'):
                        node = k.find('bone')
                        if node is None:
                            node = k.find('object')
                        keys.append({'time': _f(k, 'time', 0.0), 'spin': int(k.get('spin', '1')), 'n': node})
                    timelines[int(tl.get('id'))] = {'name': tl.get('name'), 'keys': keys}
                mkeys = []
                for k in an.find('mainline').findall('key'):
                    mkeys.append({
                        'time': _f(k, 'time', 0.0),
                        'bones': [dict(id=int(b.get('id')), parent=b.get('parent'), tl=int(b.get('timeline')), key=int(b.get('key'))) for b in k.findall('bone_ref')],
                        'objects': [dict(id=int(o.get('id')), parent=o.get('parent'), tl=int(o.get('timeline')), key=int(o.get('key')), z=int(o.get('z_index', '0'))) for o in k.findall('object_ref')],
                    })
                anims[an.get('name')] = {'length': float(an.get('length')), 'interval': float(an.get('interval', '100')),
                                         'looping': an.get('looping', 'true') != 'false', 'mainline': mkeys, 'timelines': timelines}
            self.entities[ent.get('name')] = anims
        self._cache = {}

    # ---- interpolacija -------------------------------------------------
    def _interp(self, tl, key_id, t, length, looping):
        keys = tl['keys']
        k = keys[key_id]
        n = k['n']
        if len(keys) == 1:
            return self._vals(n, n, 0.0, 1)
        if key_id + 1 < len(keys):
            k2 = keys[key_id + 1]
            t2 = k2['time']
        elif looping:
            k2 = keys[0]
            t2 = length
        else:
            return self._vals(n, n, 0.0, 1)
        span = t2 - k['time']
        f = 0.0 if span <= 0 else max(0.0, min(1.0, (t - k['time']) / span))
        return self._vals(n, k2['n'], f, k['spin'])

    @staticmethod
    def _vals(a, b, f, spin):
        def lerp(name, d):
            va, vb = _f(a, name, d), _f(b, name, d)
            return va + (vb - va) * f
        aa, ab = _f(a, 'angle', 0.0), _f(b, 'angle', 0.0)
        if spin > 0 and ab < aa:
            ab += 360.0
        elif spin < 0 and ab > aa:
            ab -= 360.0
        ang = aa + (ab - aa) * f if spin != 0 else aa
        v = {'x': lerp('x', 0.0), 'y': lerp('y', 0.0), 'angle': ang % 360.0,
             'sx': lerp('scale_x', 1.0), 'sy': lerp('scale_y', 1.0), 'a': lerp('a', 1.0)}
        if a.get('folder') is not None:
            v['file'] = (int(a.get('folder')), int(a.get('file')))
            v['px'] = _f(a, 'pivot_x', None) if a.get('pivot_x') is not None else None
            v['py'] = _f(a, 'pivot_y', None) if a.get('pivot_y') is not None else None
        return v

    @staticmethod
    def _apply_parent(c, p):
        px, py = p['sx'] * c['x'], p['sy'] * c['y']
        r = math.radians(p['angle'])
        s, co = math.sin(r), math.cos(r)
        sign = 1.0 if p['sx'] * p['sy'] >= 0 else -1.0
        return {**c, 'x': px * co - py * s + p['x'], 'y': px * s + py * co + p['y'],
                'sx': c['sx'] * p['sx'], 'sy': c['sy'] * p['sy'], 'angle': (p['angle'] + sign * c['angle']) % 360.0}

    def pose(self, entity, anim, t):
        """Svi objekti u svetskim koordinatama u trenutku t (ms), sortirani po z."""
        an = self.entities[entity][anim]
        length, looping = an['length'], an['looping']
        if looping:
            t = t % length
        mk = an['mainline'][0]
        for k in an['mainline']:
            if k['time'] <= t:
                mk = k
        bones = {}
        pending = list(mk['bones'])
        while pending:
            b = pending.pop(0)
            v = self._interp(an['timelines'][b['tl']], b['key'], t, length, looping)
            if b['parent'] is not None:
                pid = int(b['parent'])
                if pid not in bones:
                    pending.append(b)
                    continue
                v = self._apply_parent(v, bones[pid])
            bones[b['id']] = v
        out = []
        for o in mk['objects']:
            v = self._interp(an['timelines'][o['tl']], o['key'], t, length, looping)
            if o['parent'] is not None:
                v = self._apply_parent(v, bones[int(o['parent'])])
            fi = self.files[v['file']]
            v['w'], v['h'] = fi['w'], fi['h']
            v['px'] = fi['px'] if v.get('px') is None else v['px']
            v['py'] = fi['py'] if v.get('py') is None else v['py']
            v['name'] = fi['name']
            v['z'] = o['z']
            adj = self.adjust.get(fi['name'])
            if adj:
                if adj.get('hide'):
                    continue
                v['angle'] = (v['angle'] + adj.get('angle', 0.0)) % 360.0
                v['x'] += adj.get('dx', 0.0)
                v['y'] += adj.get('dy', 0.0)
            out.append(v)
        out.sort(key=lambda v: v['z'])
        return out

    # ---- geometrija ---------------------------------------------------
    @staticmethod
    def _matrix(v, scale, cx, cy):
        """Afina mapa piksel (u,v) crteža -> ekran (X,Y) sa y-nadole."""
        r = math.radians(v['angle'])
        s, c = math.sin(r), math.cos(r)
        sx, sy = v['sx'], v['sy']
        pxw = v['px'] * v['w']
        hh = v['h'] - v['py'] * v['h']
        # svet (y-nagore)
        A, B, C = c * sx, s * sy, -c * sx * pxw - s * sy * hh + v['x']
        D, E, F = s * sx, -c * sy, -s * sx * pxw + c * sy * hh + v['y']
        # ekran: X = scale*wx + cx ; Y = -scale*wy + cy
        return (scale * A, scale * B, scale * C + cx, -scale * D, -scale * E, -scale * F + cy)

    def bounds(self, entity, anims, scale, times=None):
        """Okvir (x0,y0,x1,y1) na ekranu, bez pomaka, preko svih sličica."""
        bb = None
        for anim in anims:
            an = self.entities[entity][anim]
            ts = times[anim] if times else self.frame_times(entity, anim)
            for t in ts:
                for v in self.pose(entity, anim, t):
                    if v['a'] <= 0.0:
                        continue
                    m = self._matrix(v, scale, 0.0, 0.0)
                    for (u, w) in ((0, 0), (v['w'], 0), (0, v['h']), (v['w'], v['h'])):
                        X = m[0] * u + m[1] * w + m[2]
                        Y = m[3] * u + m[4] * w + m[5]
                        bb = (X, Y, X, Y) if bb is None else (min(bb[0], X), min(bb[1], Y), max(bb[2], X), max(bb[3], Y))
        return bb

    def frame_times(self, entity, anim):
        an = self.entities[entity][anim]
        n = int(round(an['length'] / an['interval']))
        return [i * an['interval'] for i in range(n)]

    # ---- rasterizacija ------------------------------------------------
    def _part(self, name):
        if name in self._cache:
            return self._cache[name]
        path = self.overrides.get(name) or os.path.join(self.dir, name)
        im = Image.open(path).convert('RGBA')
        r, g, b, a = im.split()
        # premultiplikovano: bez svetlih rubova oko crnih kontura pri skaliranju
        pm = Image.merge('RGBA', (ImageChops.multiply(r, a), ImageChops.multiply(g, a), ImageChops.multiply(b, a), a))
        self._cache[name] = pm
        return pm

    def render(self, entity, anim, t, scale, size, offset):
        W, H = size
        ch = [Image.new('L', size, 0) for _ in range(4)]
        for v in self.pose(entity, anim, t):
            if v['a'] <= 0.0:
                continue
            part = self._part(v['name'])
            if part.size != (int(v['w']), int(v['h'])):
                part = part.resize((int(v['w']), int(v['h'])), Image.LANCZOS)
            m = self._matrix(v, scale, offset[0], offset[1])
            det = m[0] * m[4] - m[1] * m[3]
            if abs(det) < 1e-9:
                continue
            # inverzna mapa (PIL traži ekran -> crtež)
            ia, ib = m[4] / det, -m[1] / det
            ic_, id_ = -m[3] / det, m[0] / det
            ie = -(ia * m[2] + ib * m[5])
            iff = -(ic_ * m[2] + id_ * m[5])
            layer = part.transform(size, Image.AFFINE, (ia, ib, ie, ic_, id_, iff), resample=Image.BICUBIC)
            if v['a'] < 1.0:
                layer = layer.point(lambda p, a=v['a']: int(p * a))
            lr, lg, lb, la = layer.split()
            inv = ImageChops.invert(la)
            ch = [ImageChops.add(ImageChops.multiply(ch[0], inv), lr),
                  ImageChops.add(ImageChops.multiply(ch[1], inv), lg),
                  ImageChops.add(ImageChops.multiply(ch[2], inv), lb),
                  ImageChops.add(ImageChops.multiply(ch[3], inv), la)]
        a = ch[3]
        out = []
        for c in ch[:3]:
            out.append(ImageMath.unsafe_eval("convert(min(c * 255 / max(a, 1), 255), 'L')", c=c, a=a) if hasattr(ImageMath, 'unsafe_eval')
                       else ImageMath.eval("convert(min(c * 255 / max(a, 1), 255), 'L')", c=c, a=a))
        return Image.merge('RGBA', (out[0], out[1], out[2], a))


def render_animations(scml, entity, anims, scale, out_dir, prefix, overrides=None, adjust=None, pad=6):
    sp = Spriter(scml, overrides=overrides, adjust=adjust)
    bb = sp.bounds(entity, anims, scale)
    W = int(math.ceil(bb[2] - bb[0])) + 2 * pad
    H = int(math.ceil(bb[3] - bb[1])) + 2 * pad
    off = (pad - bb[0], pad - bb[1])
    os.makedirs(out_dir, exist_ok=True)
    for anim in anims:
        for i, t in enumerate(sp.frame_times(entity, anim)):
            im = sp.render(entity, anim, t, scale, (W, H), off)
            im.save(os.path.join(out_dir, '%s-%s-%d.png' % (prefix, anim, i + 1)))
        print(anim, len(sp.frame_times(entity, anim)), 'frames', (W, H))
    return (W, H)


if __name__ == '__main__':
    scml, entity, out = sys.argv[1], sys.argv[2], sys.argv[3]
    anims = sys.argv[4].split(',')
    scale = float(sys.argv[5]) if len(sys.argv) > 5 else 0.45
    render_animations(scml, entity, anims, scale, out, entity)
