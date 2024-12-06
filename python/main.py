from pyotherside import send as qsend
import sys, io, asyncio
import logging
from pathlib import Path
import json
import configparser
from datetime import datetime
from typing import Union

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

from util import convert_proxy, convert_sections, qml_date

shazam = shazamio.Shazam()
use_rust = 'recognize' in dir(shazam)

duration = 10 # seconds
rate = 41000
proxy = None

def set_settings(d, r, l, p):
    global duration, rate, shazam, proxy
    duration, rate = d, r
    shazam.language = l
    proxy = convert_proxy(p)

def load(out, new=False):
    if isinstance(out, str):
        out = json.loads(out)
    if new:
        out['__sshazam_date'] = qml_date(datetime.now())
    track = shazamio.Serialize.full_track(out).track
    if not track:
        return (False,)

    return (True, json.dumps(out), track.title, track.subtitle, convert_sections(track.sections), out.get('__sshazam_date', -1))

async def _recognize(path):
    if use_rust:
        out = await shazam.recognize(path, proxy)
    else:
        out = await shazam.recognize_song(path, proxy)
    qsend('recordingstate', 4)
    return load(out, new=True)

def recognize(path):
    return asyncio.run(_recognize(path))

def record():
    qsend('recordingstate', 2)
    f = io.BytesIO()
    pasimple.record_wav(f, duration, sample_rate=rate)
    qsend('recordingstate', 3)
    return asyncio.run(_recognize(f.getvalue()))

def export_history(path: Union[Path, str], dateLocaleString: str, backup) -> tuple:
    dateLocaleString = dateLocaleString.replace('/', '-').replace(' ', '-')
    path = Path(path) / f"sshazam-backup-{dateLocaleString}.sussybaka"
    backup = json.dumps(backup)
    try:
        with open(path, 'w') as f:
            f.write(backup)
    except PermissionError: return (2,)
    except Exception as e: return (1, str(type(e)), str(e))
    return (0,)

def import_history(path: Union[Path, str]):
    try:
        with open(path, 'r') as f:
            backup = f.read()
        backup = json.loads(backup)
    except PermissionError: return (2,)
    except Exception as e: return (1, '', str(type(e)), str(e))
    return (0, backup)