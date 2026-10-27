#!/usr/bin/env python3
"""Builds the sample music library used for the App Store screenshots.

Usage: python3 generate.py <output folder>

Writes <output>/Kivotos with a folder per school, a folder per album, and tagged
audio files with album art. One folder is left untagged, named "Artist - Title",
for showing off batch editing with file name tokens. Needs ffmpeg and swift.
"""

import json
import random
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
CODECS = {
    "m4a": ["-c:a", "aac", "-b:a", "256k", "-movflags", "use_metadata_tags"],
    "mp3": ["-c:a", "libmp3lame", "-b:a", "256k", "-id3v2_version", "3"],
    "flac": ["-c:a", "flac"],
}


def tone(seed):
    """A quiet chord, so each file has real audio and a believable size."""
    rng = random.Random(seed)
    root = rng.choice([196.0, 220.0, 246.9, 261.6, 293.7])
    voices = [f"sine=f={root * ratio:.1f}" for ratio in (1.0, 1.25, 1.5)]
    return voices, rng.randint(150, 270)


def encode(path, fmt, seed, metadata, cover=None):
    voices, duration = tone(seed)
    command = ["ffmpeg", "-y", "-loglevel", "error"]
    for voice in voices:
        command += ["-f", "lavfi", "-t", str(duration), "-i", voice]
    if cover:
        command += ["-i", str(cover)]
    mix = "".join(f"[{i}:a]" for i in range(len(voices)))
    command += ["-filter_complex", f"{mix}amix=inputs={len(voices)},volume=0.2,tremolo=f=2[a]", "-map", "[a]"]
    if cover:
        command += ["-map", f"{len(voices)}:v", "-c:v", "copy", "-disposition:v", "attached_pic"]
        if fmt == "mp3":
            command += ["-metadata:s:v", "title=Album cover", "-metadata:s:v", "comment=Cover (front)"]
    command += CODECS[fmt] + ["-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact"]
    for key, value in metadata.items():
        command += ["-metadata", f"{key}={value}"]
    command.append(str(path))
    subprocess.run(command, check=True)


def main():
    output = Path(sys.argv[1]).resolve()
    library = json.loads((HERE / "library.json").read_text())
    root = output / "Kivotos"
    shutil.rmtree(root, ignore_errors=True)
    covers = output / "Covers"
    subprocess.run(["swift", str(HERE / "Covers.swift"), str(HERE / "library.json"), str(covers)], check=True)

    seed = 0
    for school in library["folders"]:
        for album in school["albums"]:
            folder = root / school["name"] / album["folder"]
            folder.mkdir(parents=True, exist_ok=True)
            total = len(album["tracks"])
            for number, track in enumerate(album["tracks"], start=1):
                seed += 1
                metadata = {
                    "title": track["title"],
                    "artist": track["artist"],
                    "album": album["title"],
                    "album_artist": album["albumArtist"],
                    "composer": album["composer"],
                    "genre": album["genre"],
                    "date": album["year"],
                    "track": f"{number}/{total}",
                    "disc": "1/1",
                    "comment": album["comment"],
                    "copyright": f"℗ {album['year']} {library['publisher']}",
                    "publisher": library["publisher"],
                    "encoded_by": library["encodedBy"],
                    # Shown under Extended Tags
                    "MOOD": album["mood"],
                    "SCHOOL": school["name"],
                    "RECORDED_AT": album["recordedAt"],
                }
                name = f"{number:02d} {track['title']}.{album['format']}"
                encode(folder / name, album["format"], seed, metadata, covers / f"{album['title']}.jpg")
                print(f"Wrote {folder.name}/{name}")

    # A few favorites at the top level, so the file browser shows album art next to the folders
    albums = {album["title"]: album for school in library["folders"] for album in school["albums"]}
    for pick in library["loose"]:
        album = albums[pick["album"]]
        track = album["tracks"][pick["track"] - 1]
        school = next(school["name"] for school in library["folders"] if album in school["albums"])
        source = root / school / album["folder"] / f"{pick['track']:02d} {track['title']}.{album['format']}"
        name = f"{track['title']}.{album['format']}"
        shutil.copy2(source, root / name)
        print(f"Copied {name}")

    untagged = library["untagged"]
    folder = root / untagged["parent"] / untagged["folder"]
    folder.mkdir(parents=True, exist_ok=True)
    for track in untagged["tracks"]:
        seed += 1
        name = f"{track['artist']} - {track['title']}.{untagged['format']}"
        encode(folder / name, untagged["format"], seed, {})
        print(f"Wrote {folder.name}/{name}")


if __name__ == "__main__":
    main()
