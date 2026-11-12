"""Read-only migration bridge from the original SQLite journal; no Flutter needed.
Usage: python3 scripts/export_legacy_journal.py /path/kanayu.sqlite /path/export.json
Then import the JSON in the native Godot school's journal screen.
"""
import datetime
import json
import pathlib
import sqlite3
import sys
import urllib.parse

source, target = map(pathlib.Path, sys.argv[1:3])
uri = 'file:' + urllib.parse.quote(str(source.resolve())) + '?mode=ro'
with sqlite3.connect(uri, uri=True) as connection:
    events = [json.loads(row[0]) for row in connection.execute('SELECT payload FROM events ORDER BY seq')]
target.write_text(json.dumps({'schema':'kanayu-journal/1', 'exported_at':datetime.datetime.now(datetime.timezone.utc).isoformat().replace('+00:00','Z'), 'events':events}, ensure_ascii=False, indent=2))
print(json.dumps({'events':len(events), 'lessons_completed':sum(e['type']=='lesson_completed' for e in events), 'export':str(target)}))
