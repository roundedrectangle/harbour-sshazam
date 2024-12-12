from typing import List, Optional, Union, Callable
import urllib.parse
from datetime import datetime
import functools
from pyotherside import send as qsend
import json

from shazamio.schemas.models import (
    SongSection, VideoSection, LyricsSection, RelatedSection, ArtistSection,
)

def convert_sections(sections: Optional[List[Union[SongSection, VideoSection, LyricsSection, RelatedSection, ArtistSection]]]):
    if not sections:
        return []
    res = []
    for s in sections:
        if isinstance(s, SongSection):
            res.append({
                'type': 'song',
                'tab': s.tab_name,
                'meta': [{'title': m.title, 'text': m.text} for m in s.metadata or ()],
                'pages': [{'image': p.image, 'caption': p.caption} for p in s.meta_pages or ()],
            })
    return res

def convert_proxy(proxy):
    if not proxy:
        return

    p = urllib.parse.urlparse(proxy, 'http') # https://stackoverflow.com/a/21659195
    netloc = p.netloc or p.path
    path = p.path if p.netloc else ''
    p = urllib.parse.ParseResult('http', netloc, path, *p[3:])

    return p.geturl()

def qml_date(date: datetime):
    """Convert to UTC Unix timestamp using milliseconds"""
    return date.timestamp()*1000

def exception_decorator(*exceptions: Exception):
    """Generates a decorator for handling exceptions in `exceptions`. Calls `pyotherside.send` on error. Preserves __doc__, __name__ and other attributes."""
    def decorator(func: Callable):
        @functools.wraps(func)
        def f(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except exceptions as e: # pyright: ignore[reportGeneralTypeIssues]
                qsend(f"An error occured while running function '{func.__name__}': {type(e).__name__}: {e}")

        return f
    return decorator

def history_safe(func: Callable):
    @functools.wraps(func)
    def f(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except PermissionError as e:
            qsend('history_perms', str(e))
            return
        except json.JSONDecodeError as e:
            qsend('history_json', str(e))
            return
        except Exception as e:
            qsend('history_unknown', type(e).__name__, str(e))
            return
    return f

def is_history(obj):
    if not isinstance(obj, (list, tuple)):
        qsend('history_notlist')
        return False
    return True