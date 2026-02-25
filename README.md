# Display Control

A lightweight macOS menu bar app for managing connected displays.

## Features

- **Monitor icon** in the menu bar — no Dock icon, stays out of your way
- **Lists all connected displays** with their real names (read from IOKit)
- **Per-display submenu** with:
  - ✓ **Extended Display** — use the display independently (checkmarked when active)
  - **Mirror of [Display Name]** — one entry per other connected display (checkmarked when active)
- **Auto-refreshes** when displays are plugged or unplugged
- Changes are applied **permanently**, consistent with System Preferences behaviour

## Requirements

- macOS 12.0+
- Xcode 14+

## Building

```bash
cd osx-display-control

xcodebuild -project DisplayControl.xcodeproj \
  -scheme DisplayControl \
  -configuration Release build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$(pwd)/build"
```

The compiled app will be output to `build/Release/DisplayControl.app`.

## Running

After building, double-click **`build/Release/DisplayControl.app`** in Finder, or run:

```bash
open build/Release/DisplayControl.app
```

Or open `DisplayControl.xcodeproj` in Xcode and press **⌘R**.

## How It Works

| Concern | API |
|---------|-----|
| Menu bar icon | `NSStatusBar` / `NSStatusItem` |
| Display enumeration | `CGGetActiveDisplayList` |
| Display names | `IOServiceGetMatchingServices` + `IODisplayCreateInfoDictionary` |
| Mirror state | `CGDisplayMirrorsDisplay` |
| Apply changes | `CGBeginDisplayConfiguration` / `CGCompleteDisplayConfiguration` |
| Change notifications | `CGDisplayRegisterReconfigurationCallback` |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
