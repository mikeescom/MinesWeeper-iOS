# MinesWeeper for iOS

A Minesweeper game for iPhone. Players sign in with Google or email, and every win is saved to
their account so their best times follow them across devices.

This is the iOS version of [MinesWeeper for Android](https://github.com/mikeescom/MinesWeeper-Android).
Both apps play by the same rules and share the same Firebase project and record format.

## Features

- **Gameplay**
  - The board fills the screen.
  - Tap a square to open it; long-press to place or remove a flag.
  - The first tap is never a mine and opens an area.
  - You win by opening every safe square or by flagging every mine.
- **Header:** a mines counter, a face button that restarts the game, a timer, and an account
  menu.
- **Custom difficulty:** set the number of mines (1 to the number of squares minus 1, at most
  999) from the account menu.
- **Accounts:** Sign in with Apple, Sign in with Google, or email and password, including account
  creation and password reset. Players can delete their account and all their records from
  Settings.
- **Records:** every win is saved to Firebase Realtime Database and cached on the device. The
  Records screen ranks them by mines per square, then by time.

## Requirements

- Xcode 16 or later
- iOS 16.0 or later, iPhone only, portrait

Swift Package Manager fetches the dependencies when you open the project:

| Package | Products |
| --- | --- |
| [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) 11 | FirebaseAuth, FirebaseDatabase |
| [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) 8 | GoogleSignIn |

## Project structure

```
MinesWeeper/
├── Game/          Board: all game rules, no UIKit code (a port of the Android Board.kt)
├── Data/          RecordItem, RecordRanking, RecordsRepository (Realtime Database),
│                  LocalRecordStore (on-device cache) and Settings (UserDefaults)
├── Auth/          AuthProviding and its Firebase implementation (Google and email)
├── DI/            AppContainer, which builds the app's dependencies once at launch
├── Controllers/   Log in, create account, game board and records screens
└── UI/            Board view, digit display and shared colors and styles
MinesWeeperTests/  Unit tests
```

All screens are built in code; the only storyboard is the launch screen.

Screens get their dependencies through their initializers. `AppContainer` builds the live
implementations once in `SceneDelegate`, and screens depend only on the protocols
(`AuthProviding`, `RecordsStoring`, `GameSettings`), so tests can pass fakes. This does the job
that Hilt does in the Android app.

## Getting started

1. Open `MinesWeeper.xcodeproj` in Xcode and wait for the packages to resolve.
2. `MinesWeeper/GoogleService-Info.plist` is committed and points at the existing Firebase
   project. To use your own Firebase project, replace it with yours, and update the URL scheme
   in `MinesWeeper/Info.plist` to match its `REVERSED_CLIENT_ID`.
3. Select the **MinesWeeper** scheme and run it on a simulator or device.

### Firebase setup

The app shares its Firebase project with the Android app:

- **Authentication:** enable the **Apple**, **Google** and **Email/Password** sign-in providers.
  Sign in with Apple also needs the capability on the App ID in your Apple Developer account
  (Xcode's automatic signing adds it from `MinesWeeper/MinesWeeper.entitlements`).
- **Realtime Database:** records are stored at `users/<uid>/<record id>`, with the same fields as
  on Android. The database rules live in the Android repo (`database.rules.json`) and cover both
  apps.

## Testing

Run the tests in Xcode with ⌘U, or from the command line:

```sh
xcodebuild test \
  -project MinesWeeper.xcodeproj \
  -scheme MinesWeeper \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

The tests cover:

- **Game rules:** `BoardTests`, which mirror the Android `BoardTest`.
- **Record ranking:** `RecordRankingTests`.
- **Record format:** `RecordItemTests`.
- **On-device record cache:** `LocalRecordStoreTests`.
- **Settings:** `UserDefaultsSettingsTests`.

## Continuous integration

GitHub Actions (`.github/workflows/ios.yml`) builds the app and runs the tests on an available
iPhone simulator for every push to `main` and every pull request into it.
