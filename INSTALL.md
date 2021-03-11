# Installation procedure

Pre-built applications are available and utilize the cloud resources hosted by the author (myself). These are:
1. Web version: https://astrolog.vedala.holdings
2. Android: https://play.google.com/store/apps/details?id=com.vedalaholdings.astro_log
3. iOS: https://appdistribution.firebase.dev/i/8c0b75f66438e0ed 

It is also, however, easy to build this app for yourself so that you alone are in control of the data, unless you 
want to distribute your version of the app.

The program is written in [flutter](flutter.dev) and can be compiled for Android, iOS and Web platforms.
The installation requirements and steps for each platform is provided below.

## Requirements

1. Install flutter using the steps enumerated [here](https://flutter.dev/docs/get-started/install).
For this, you must be on one of the following platforms: MacOS, Windows, Linux or ChromeOS. 
2. Ensure that flutter environment is on `dev` channel
  ```sh
  $ flutter channel dev
  $ flutter upgrade
  ```
3. Clone the repo
  ```shell
  git clone https://github.com/kvedala/astro-logbook --depth 1 --branch main
  ```
4. Install the required packages using the command:
  ```sh
  flutter pub get
  ```
5. Other build requirements are described [in here](https://flutter.dev/docs/get-started/install).
  * To build for android, [Android Studio](https://developer.android.com/studio).
  * To build for iOS, [XCode](https://apps.apple.com/in/app/xcode/id497799835?mt=12) is required.
6. For authentication, the platform uses [Firebase Authentication](https://firebase.flutter.dev/docs/auth/overview)
7. For Cloud database storage, [Google Firestore](https://firebase.flutter.dev/docs/firestore/usage/). If you implement it yourself,
ensure to review and setup the database [security rules](https://firebase.flutter.dev/docs/firestore/usage#data-security).
8. Ensure to update all the config and API keys in the project as described in the links above.
  
## Build the app

### Build for Web

```sh
flutter build web --release
```
The build directory by default is: `<repo root>/build/web`. The files therein can be directly uploaded to 
your hosting server. The current app is hosted using [FirebaseHosting](https://firebase.google.com/docs/hosting).

### Build for Android

```sh
flutter build apk --release
```
The generated APK file will be available in the folder: `<repo root>/build/app/outputs/flutter-apk/app-release.apk`. 
This file can be installed on your android device, provided you enable "Install from unknown sources" in your device.

### Build for iOS

```sh
flutter build ipa --release
```
The generated ARCHIVE file will be available in the folder: `<repo root>/build/ios/archive/Runner.xcarchive`.
This file can then be distributed using [Apple Testflight](https://developer.apple.com/testflight/) or other means.
