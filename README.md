# Noir: a minimalist AMOLED watch face for Garmin

A large, centered time with only what matters around it: weather, date, heart rate, Body Battery, steps and watch battery. Everything else stays black.

Noir is a free [Connect IQ](https://developer.garmin.com/connect-iq/) watch face for AMOLED Garmin watches, written in Monkey C.

## Features

- **Readable always-on.** When the watch dims the screen, Noir switches to a thicker, brighter time with the date and battery. It stays well below Garmin's 10% luminance limit (about 2.3% measured) and shifts a few pixels every minute to protect the AMOLED screen.
- **Night screen.** During your sleep hours (set in Garmin Connect), Noir keeps its dim screen even when you raise your wrist. On the watch, set *Focus Modes > Sleep > Watch Face > Don't change* so Noir stays active at night.
- **Weather icon follows the real sunset**, using the sunrise and sunset computed by the watch.
- **Status icons only when needed**: phone disconnected, Do Not Disturb.
- **12/24 h and °C/°F follow your watch settings** by default.
- Date in the watch's language; settings in English and French.

## Settings

Available in the Garmin Connect app, or on the watch (hold MENU > Watch Face > Noir > Customize):

| Setting | Values | Default |
|---|---|---|
| Show seconds | on / off | off |
| Time format | same as watch / 24 h / 12 h (AM/PM) | same as watch |
| Show weather | on / off | on |
| Temperature unit | same as watch / Celsius / Fahrenheit | same as watch |
| Battery percentage | on / off | on |
| Status icons | on / off | on |

## Permissions

- **Complications**: heart rate, Body Battery, sunrise and sunset.
- **User profile**: only to read your sleep hours for the night screen.

Noir collects no data and sends nothing.

## Supported watches

AMOLED round watches with a 454 or 466 px screen. Smaller AMOLED screens (416 and 390 px) are planned. MIP screens are not supported: the design is made for AMOLED.

> **Only the fēnix 9 Pro 47 mm has been tested on a real watch.** The other watches share the same screen size and build without errors, but nobody has checked them yet. If you own one, please [report how Noir looks on it](../../issues/new?template=device-report.md): it takes two minutes and a photo.

| Watch | Device id | Status |
|---|---|---|
| fēnix 9 Pro 47 mm | `fenix9pro47mm` | ✅ tested on the watch |
| fēnix 9 Pro 51 mm | `fenix9pro51mm` | 🔨 builds, not tested |
| fēnix 9 47 / 51 mm | `fenix947mm` | 🔨 builds, not tested |
| fēnix 8 47 / 51 mm, tactix 8, quatix 8 | `fenix847mm` | 🔨 builds, not tested |
| fēnix 8 Pro 47 / 51 mm, MicroLED, quatix 8 Pro | `fenix8pro47mm` | 🔨 builds, not tested |
| epix Pro (Gen 2) 51 mm, D2 Mach 1 Pro, tactix 7 AMOLED | `epix2pro51mm` | 🔨 builds, not tested |
| D2 Mach 2 | `d2mach2` | 🔨 builds, not tested |
| D2 Mach 2 Pro | `d2mach2pro` | 🔨 builds, not tested |
| MARQ (Gen 3) | `marq3` | 🔨 builds, not tested |
| Forerunner 965 | `fr965` | 🔨 builds, not tested |
| Forerunner 970 | `fr970` | 🔨 builds, not tested |
| Forerunner 570 47 mm | `fr57047mm` | 🔨 builds, not tested |
| Venu 3 | `venu3` | 🔨 builds, not tested |
| Venu 4 45 mm | `venu445mm` | 🔨 builds, not tested |
| Approach S72 47 mm | `approachs7247mm` | 🔨 builds, not tested |

## Contributing

Reports from other watches are the most useful contribution right now: open a [device report](../../issues/new?template=device-report.md) with a photo of the watch face (active screen and, if you can, always-on screen). Bug reports and pull requests are welcome too.

## Known limitation

When a timer, stopwatch or activity runs in the background, the watch draws its own icon at the top center of the screen, over the weather line. The Connect IQ SDK offers no way to move this icon or to know when it is shown.

## Build

Requirements: [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) 9.2 or later, with the device profiles of the target watches, and a developer key ([how to create one](https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/)).

```sh
# Build for one watch (here a fēnix 9 Pro 47 mm)
monkeyc -f monkey.jungle -d fenix9pro47mm -o bin/Noir.prg -y /path/to/developer_key

# Package for the Connect IQ Store (all watches of the manifest)
monkeyc -e -r -f monkey.jungle -o store/Noir.iq -y /path/to/developer_key
```

To try it on a watch, copy `bin/Noir.prg` to the `GARMIN/APPS/` folder of the watch over USB (on macOS, with an MTP tool such as OpenMTP).

The Monkey C extension for Visual Studio Code can also build and run Noir in the simulator.

## Project structure

```
source/               Monkey C code: app, watch face view, settings menu
resources/            images (SVG), strings (English), settings, launcher icon
resources-fre/        French strings
manifest.xml          app id, supported watches, permissions
monkey.jungle         build configuration
design/               mockup, original icons and their license
docs/notes.md         development notes, in French
docs/store.md         Connect IQ Store listing, in English and French
```

## Credits

Icons are derived from [Lucide](https://lucide.dev) (ISC license; some icons from Feather, MIT license). See [design/LICENSE-lucide.txt](design/LICENSE-lucide.txt).

## License

Copyright (C) 2026 Fred R.

Noir is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [LICENSE](LICENSE).
