# Tunetag

A batch audio tag editor built for iOS.

## Repository layout

| Path | Contents |
|---|---|
| `App/` | The Tunetag app. Open `App/Tunetag.xcodeproj`. |
| `Prelude/` | The tag reading and writing engine, built on [TagLib](https://taglib.org) through [CXXTagLib](https://github.com/sbooth/CXXTagLib). |
| `Package.swift` | Swift package manifest for Prelude and PreludeLookup. |

## Prelude

Prelude reads and writes tags in MP3, M4A, FLAC, Ogg Vorbis, Opus, WAV, AIFF and the other formats TagLib supports.

Add it to another project as a Swift package:

```swift
.package(url: "https://github.com/katagaki/Tunetag", branch: "main")
```

Then depend on the `Prelude` product:

```swift
import Prelude

// Read
guard let file = TagLibFile(path: path) else { return }
let snapshot = TagSnapshot(file)
print(snapshot.title, snapshot.track, snapshot.trackTotal)

// Write: nil leaves a field unchanged, and an empty string removes it
var tag = Tag()
tag.title = "New Title"
tag.comment = ""
TagWriter.apply(tag, to: file)
file.save()

// Every field, including custom ones
file.setValues(["Happy"], forProperty: "MOOD")
file.save()
```

## PreludeLookup

PreludeLookup finds the album that files belong to and fills in their tags. It recognizes songs by their audio with [ShazamKit](https://developer.apple.com/shazamkit/), then looks up their album on the [iTunes Search API](https://performance-partners.apple.com/search-api), and on [MusicBrainz](https://musicbrainz.org) with cover art from the [Cover Art Archive](https://coverartarchive.org) if iTunes doesn't have it. Albums can also be looked up by artist and album name, which gives the single best match. Apps using it need the ShazamKit App Service enabled for their identifier.

```swift
import PreludeLookup

let result = await AutomaticLookup.lookUp(filesAt: paths)
guard let release = result.bestMatch ?? result.releases.first else { return }
let detail = try await release.source.detail(for: release)

// Pair each file with a track, then write the chosen fields
let matches = LookupMatch.matched(await LookupMatch.read(paths: paths),
                                  to: detail.tracks, identifiers: result.identifiers)
for match in matches {
    guard let track = detail.tracks.first(where: { $0.id == match.trackID }) else { continue }
    _ = detail.apply(track, fields: LookupField.defaultFields, albumArt: nil, toFileAt: match.path)
}
```

Run the tests with `swift test` from the repository root.
