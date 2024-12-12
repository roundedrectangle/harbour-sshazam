from pyotherside import send as qsend
import sys, io, asyncio
import logging
from pathlib import Path
import json
import configparser
from datetime import datetime
from typing import Union, List

logging.basicConfig()

# Pyotherside waits for all components to be created before running module import callback

script_path = Path(__file__).absolute().parent # /usr/share/harbour-sshazam/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-sshazam/lib/deps

while True: # FIXME
    try:
        import shazamio
    except configparser.MissingSectionHeaderError:
        logging.info("Workarounding configparser.MissingSectionHeaderError...")
        continue
    break

import pasimple

from util import convert_proxy, convert_sections, qml_date, history_safe, is_history

shazam = shazamio.Shazam()
use_rust = 'recognize' in dir(shazam)

settings_set = False
duration = 10 # seconds
rate = 41000
history: Path
proxy = None


def set_settings(d, r, l, p, data):
    global settings_set, duration, rate, shazam, proxy, history
    duration, rate = d, r
    shazam.language = l
    proxy = convert_proxy(p)
    history = Path(data) / 'history.json'
    settings_set = True

def wait_for_settings():
    while not settings_set: pass

def load(out, new=False):
    if isinstance(out, str):
        out = json.loads(out)
    if new:
        out['__sshazam_date'] = qml_date(datetime.now())
    track = shazamio.Serialize.full_track(out).track
    if not track:
        return (False,)

    return (True, out, track.title, track.subtitle, convert_sections(track.sections), out.get('__sshazam_date', -1))

async def _recognize(path):
    if use_rust:
        out = await shazam.recognize(path, proxy)
    else:
        out = await shazam.recognize_song(path, proxy)
    qsend('recordingstate', 4)
    loaded = load(out, new=True)
    if loaded[0]:
        add_to_history(loaded[1]) # pyright: ignore[reportGeneralTypeIssues]
    return loaded

def recognize(path):
    return asyncio.run(_recognize(path))

def record():
    qsend('recordingstate', 2)
    f = io.BytesIO()
    pasimple.record_wav(f, duration, sample_rate=rate)
    qsend('recordingstate', 3)
    return asyncio.run(_recognize(f.getvalue()))

def _export_data(path: Union[Path, str], date_locale_str: str, backup) -> tuple:
    date_locale_str = date_locale_str.replace('/', '-').replace(' ', '-')
    path = Path(path) / f"sshazam-backup-{date_locale_str}.json"
    backup = json.dumps(backup)
    try:
        with open(path, 'w') as f:
            f.write(backup)
    except PermissionError: return (2,)
    except Exception as e: return (1, str(type(e)), str(e))
    return (0,)

def export_data(path: Union[Path, str], date_locale_str: str, backup: dict, add_history: bool) -> tuple:
    backup = backup or {}
    if add_history:
        history = get_history()
        if history is not None:
            _, content = history
            backup['history'] = content
    return _export_data(path, date_locale_str, backup)

def import_data(path: Union[Path, str]):
    try:
        with open(path, 'r') as f:
            backup = f.read()
        backup = json.loads(backup)
    except PermissionError: return (2,)
    except Exception as e: return (1, '', str(type(e)), str(e))
    return (0, backup)

def import_history(data: Union[str, list]):
    if isinstance(data, str):
        data = json.loads(data)
    modify_history(lambda _: data)

def migrate_history(legacy: str):
    with open(history, 'w') as f:
        f.write(legacy)

@history_safe
def create_history(force = False):
    """Returns if history was created, or None if an error occured."""
    if not history.exists() or force:
        with open(history, 'w') as f:
            f.write('[]')
        return True
    return False

@history_safe
def get_history():
    wait_for_settings()
    create = create_history()
    if create is None:
        return
    if create:
        return create, []
    with open(history) as f:
        content = f.read()
        if content.strip() == '':
            create_history(force=True)
            content = '[]'
    content = json.loads(content)
    if not is_history(content):
        return
    return create, content

@history_safe
def load_history():
    history = get_history()
    if history is None:
        return
    create, content = history
    if create:
        qsend('historyloaded')
        return

    for i, entry in enumerate(content):
        qsend('history', load(entry), i)

    qsend('historyloaded')

@history_safe
def modify_history(do):
    _history = get_history()
    if _history is None:
        return
    content: List[str]
    _, content = _history
    
    content = do(content)
    if content is None:
        return
    res = json.dumps(content)

    with open(history, 'w') as f:
        f.write(res)

add_to_history = lambda entry: modify_history(lambda h: [entry] + h)

def remove_from_history(index, length):
    try: index = int(index)
    except Exception as e:
        qsend('history_unknown', type(e).__name__, str(e))
        return
    def f(h):
        if len(h) != length:
            qsend('history_outdated', len(h), length)
            return
        del h[index]
        return h
    return modify_history(f)

# remove_from_history = lambda index: modify_history(lambda h: (h.pop(index), h)[1])

# we absolutely LOVE complicated stuff...
# though with line breaks it's pretty clear
rebuild_history = lambda: modify_history(lambda h: sorted(
    [json.loads(e) if isinstance(e, str) else e for e in h],
    key=lambda e: (e.get('__sshazam_date', None) is not None, e.get('__sshazam_date', None)),
    reverse=True
))