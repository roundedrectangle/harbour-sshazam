import shazamio
import asyncio

shazam = shazamio.Shazam()
async def main():
    out = await shazam.recognize('/home/koza/Музыка/Tobu & Syndec - Dusk (Radio Edit).mp3')
    # track_id = shazamio.Serialize.full_track(out).tag_id
    # about = await shazam.track_about(53982678)
    # track = shazamio.Serialize.track(data=about)
    info = shazamio.Serialize.full_track(out)
    print(out)

asyncio.run(main())