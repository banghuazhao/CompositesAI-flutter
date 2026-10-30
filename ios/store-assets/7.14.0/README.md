# CompositesAI 7.14.0 App Store assets

The English (U.S.) draft listing uses these assets. Other storefronts retain
their existing screenshot and localization behavior.

- `header-search-universal.png`: opaque RGB PNG, 5244 × 2950, shared by
  **Header** and **Search Results**.
- `duo/outer/en-US/`: the signed-in chat welcome JPEG and two calculator PNGs
  at 1398 × 2034.
- `duo/inner/en-US/`: the signed-in chat welcome JPEG and two calculator PNGs
  at 2853 × 2007.

The active screenshots show the signed-in welcome screen, calculator selection,
and laminate plate results. The two signed-in welcome images were captured from
the normal app after the user signed in on the dedicated Duo simulator. They
show starter questions and an empty composer, with no private conversation
content. Native `simctl io screenshot --type=jpeg` captures include system chrome and
provide opaque JPEGs without resizing or compositing. The old `01-guest.png` files are retained
as superseded captures and are no longer active in the listing.

The calculator screenshots come from the production routes. The calculation uses E1 = 181 GPa, E2 = 10.3 GPa,
G12 = 7.17 GPa, ν12 = 0.28, 0.125 mm plies and a [0/45/-45/90]s layup.
The calculator captures contain no account data or generated chat responses.

The dedicated automated capture target is for signed-out calculator captures
and legacy guest previews only. Do not run it against a signed-in profile.
It runs on native iOS. It renders production routes
at each display's logical viewport and 3× density, excluding system chrome.
The driver validates dimensions, PNG checksums, opacity, and complete output
before writing any images. Run on a dedicated signed-out iPhone Duo simulator:

```sh
flutter drive --no-pub -d <DUO_SIMULATOR_ID> \
  --driver=integration_test/ios_duo_screenshot_driver.dart \
  --target=integration_test/ios_duo_store_screenshots_test.dart

# Open the simulator's inner display in landscape first, then run:
flutter drive --no-pub -d <DUO_SIMULATOR_ID> \
  --dart-define=STORE_DUO_INNER=true \
  --driver=integration_test/ios_duo_screenshot_driver.dart \
  --target=integration_test/ios_duo_store_screenshots_test.dart
```

Capture output is written under `build/store-assets-7.14.0/duo/`. Copy the
reviewed files into this directory before uploading. Restore the production
build target after capture:

```sh
flutter build ios --simulator --debug --config-only --no-pub --target=lib/main.dart
```

The creative illustration was generated with the built-in imagegen tool using
`creative-prompt.txt`. `creative-source.png` preserves its original output;
the universal asset is resampled to Apple's accepted dimensions without
changing its composition. It is promotional artwork, not an app screenshot
or a specific simulation result.

Apple specifications:
- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- https://developer.apple.com/app-store/asset-best-practices/

`upload-verification.json` records the verified draft placements. Uploading
these assets does not submit the version for review or release it.
