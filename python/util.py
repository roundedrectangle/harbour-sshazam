from re import L
from typing import List, Optional, Union

import shazamio
from shazamio.schemas.models import (
    SongSection, VideoSection, LyricsSection, RelatedSection, ArtistSection,
    SongMetadata, SongMetaPages
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