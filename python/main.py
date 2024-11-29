from pyotherside import send as qsend
import sys, io, asyncio
import logging
from pathlib import Path
import json

# Pyotherside waits for all components to be created before running module import callback

script_path = Path(__file__).absolute().parent # /usr/share/harbour-saildiscord/python
sys.path.append(str(script_path.parent / 'lib/deps')) # /usr/share/harbour-saildiscord/lib/deps
import shazamio
# import soundfile as sf
# import sounddevice as sd
import pasimple

logging.basicConfig()

shazam = shazamio.Shazam()

def load(out):
    if isinstance(out, str):
        out = json.loads(out)
    track = shazamio.Serialize.full_track(out).track
    if not track:
        return (False,'','','')
    return (True, json.dumps(out), track.title, track.subtitle)

async def _recognize(path):
    out = await shazam.recognize(path)
    return load(out)

def recognize(path):
    # '/home/defaultuser/Music/Tobu - Higher.mp3'
    return asyncio.run(_recognize(path))

duration = 10 # seconds
rate = 44100

def record():
    f = io.BytesIO()
    pasimple.record_wav(f, 10)
    return asyncio.run(_recognize(f.getvalue()))