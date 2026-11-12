"""Sample existing KanjiVG cubic paths for the native Godot drawing view."""
import json, pathlib, re
root = pathlib.Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'assets/content/hiragana.json').read_text())
result = {}
for item in catalog['items']:
    strokes = []
    for path in item['strokes']:
        tokens = re.findall(r'[A-Za-z]|[-+]?(?:\d*\.\d+|\d+)', path)
        i, command, point, points = 0, None, (0, 0), []
        while i < len(tokens):
            if tokens[i].isalpha():
                command = tokens[i]
                i += 1
            count = 2 if command == 'M' else 6
            values = list(map(float, tokens[i:i+count]))
            i += count
            if command == 'M':
                point = tuple(values)
                points.append(list(point))
            elif command in ('c', 'C'):
                controls = [tuple(values[n:n+2]) for n in (0, 2, 4)]
                if command == 'c':
                    controls = [(x+point[0], y+point[1]) for x, y in controls]
                a, b, end = controls
                for n in range(1, 25):
                    t = n/24
                    points.append([(1-t)**3*point[d]+3*(1-t)**2*t*a[d]+3*(1-t)*t*t*b[d]+t**3*end[d] for d in (0, 1)])
                point = end
            else:
                raise ValueError(command)
        strokes.append([[round(x/109, 6), round(y/109, 6)] for x, y in points])
    result[item['id']] = strokes
(root / 'godot/assets/content/stroke-points.json').write_text(json.dumps(result, separators=(',', ':')))
