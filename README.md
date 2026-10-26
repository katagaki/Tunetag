# Tunetag

A batch audio tag editor built for iOS.

## Repository layout

| Path | Contents |
|---|---|
| `App/` | The Tunetag app. Open `App/Tunetag.xcodeproj`. |
| `Prelude/` | The tag reading and writing engine, built on [TagLib](https://taglib.org) through [CXXTagLib](https://github.com/sbooth/CXXTagLib). |
| `Package.swift` | Swift package manifest for Prelude. |

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

Run the tests with `swift test` from the repository root.
