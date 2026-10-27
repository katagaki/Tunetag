# App Store Screenshots

| Path | Contents |
|---|---|
| `SampleData/` | The sample library: Gehenna Academy and Trinity General School clubs from Blue Archive's Kivotos. `library.json` lists the albums, `Covers.swift` draws their album art, and `generate.py` writes tagged audio files with ffmpeg. |
| `Captures/` | Raw captures, three per platform. |
| `Compose.swift` | The composer. It draws the background, caption, device frame and callouts around each capture. |
| `Screenshots.json` | Captions, device placement and callouts for each scene. |
| `Output/` | The finished screenshots: iPhone at 1320x2868, iPad at 2064x2752 and Mac at 2880x1800. |

## Making the sample library

```sh
python3 SampleData/generate.py /tmp/tunetag-sample
```

This writes `/tmp/tunetag-sample/Kivotos`. The `Sweets After Class` folder is left untagged and named `Artist - Title`, for the batch edit scenes. MP3 and FLAC files also get Mood, School and Recorded At tags, which show under Extended Tags.

## Capturing

- **iPhone and iPad**: Use a new iPhone 18 Pro Max and iPad Pro 13-inch (M5) simulator in English, in dark mode, with the status bar set to 9:41. Install a Release build and copy the contents of `Kivotos` into the app's `Documents` folder (`xcrun simctl get_app_container <udid> com.tsubuzaki.Tunetag data`). Set `ReviewPrompted` to true in the app's defaults so the review prompt stays away. Capture with `xcrun simctl io <udid> screenshot`.
- **Mac**: Build the Mac app with a throwaway bundle ID and ad-hoc signing, and open it on the `Kivotos` folder in the Parallels VM with `-AppleLanguages "(en)"`. Set the window to 1160x656 points, capture the screen with `prlctl capture`, and crop to the window, including its 1 pixel border.

## Composing

```sh
swift Compose.swift Screenshots.json          # every platform
swift Compose.swift Screenshots.json iPhone   # one platform
```

Callout arrows start at a highlighted part of the file name, and their bends and end points are in capture pixels. A bend that leaves out `x` or `y` keeps the previous one, so arrows run straight across and down.
