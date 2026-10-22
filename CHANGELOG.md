# Changelog

All notable changes to Noir. Versions follow [Semantic Versioning](https://semver.org): major for breaking changes, minor for new features, patch for fixes. A version is tagged in git (`vX.Y.Z`) when it is sent to the Connect IQ Store.

## [1.2.1] - 2026-10-22

Second version sent to the Connect IQ Store. It includes everything from 1.1.0 and 1.2.0, which were never released on their own.

### Changed
- Default indicators are now heart rate, steps, Body Battery, in the same columns as the Auto mode. Choices already made in the watch face editor are kept.

## [1.2.0] - not released (included in 1.2.1)

### Added
- **Auto indicators** (setting, off by default): the three indicators follow the moment of the day.
  - After waking up: heart rate, sleep score, Body Battery.
  - After an activity: heart rate, intensity minutes, Body Battery.
  - Rest of the day: stress, steps, Body Battery.
- **Auto window** setting: duration of the wake-up and after-activity moments (30 min, 1 h, 1 h 30).

## [1.1.0] - not released (included in 1.2.1)

### Added
- Choose the three indicators in the watch face editor (fēnix 8 and newer): heart rate, Body Battery, steps, stress, calories, floors climbed, intensity minutes, respiration, pulse ox, recovery time, sleep score, altitude, solar input.
- Icons for the ten new indicators.

### Changed
- Heart rate updates continuously instead of waiting for system notifications.

## [1.0.0] - 2026-10-20

First release, sent to the Connect IQ Store.

- Minimalist AMOLED watch face: time, date, weather, heart rate, Body Battery, steps, battery.
- Readable always-on screen, with burn-in protection shift.
- Night screen during sleep hours.
- Weather icon following sunrise and sunset.
- Status icons: phone disconnected, Do Not Disturb.
- Settings: seconds, time format, weather, temperature unit, battery percentage, status icons (English and French).

[1.2.1]: https://github.com/fraynal/noir-garmin-watchface/compare/v1.0.0...v1.2.1
[1.0.0]: https://github.com/fraynal/noir-garmin-watchface/releases/tag/v1.0.0
