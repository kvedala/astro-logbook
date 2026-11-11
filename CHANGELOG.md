# Changelog

## 2.9.0+356

* Version/build number bump only; no functional changes since 2.8.2+354.

## 2.8.2+354

* Added an app information/privacy website and an account deletion page.
* Fixed a checklist crash and always show the Google account chooser at sign-in.
* Added a "Tonight" observing page with objects visible tonight and their visibility windows.
* Enriched Messier and NGC object details, added catalog links, and expanded NGC constellation names.
* Improved catalog tiles and observation actions.
* Fixed overflow in observation details.
* Updated Android location permissions and service binding, and enabled signed Android builds.

## 2.8.1+334

* Version/build number bump only; no functional changes since 2.8.0+328.

## 2.8.0+328

* Updated sign-in provider buttons and Android Firebase configuration.
* Added Facebook SDK login on Android and Crashlytics symbol upload for iOS.
* Updated Android package and build configuration.

## 2.7.1+317

* Modernized authentication and the observation data layer.
* Consolidated social sign-in with Firebase Auth; added Facebook Limited Login, sign-in cancellation handling, and Firebase App Check.
* Updated Flutter/platform tooling and migrated to `material_ui`.

## 2.7.0+301

* Updated platform files, dependencies, analytics, localization, and app icons.

## 2.6.0+293

* Updated major dependencies and fixed related issues.
* Fixed iOS location permission descriptions and configuration; improved localization usage.

## 2.5.0+285

* Added a navigation drawer and consolidated page navigation.
* Improved weather and WebView behavior, loading feedback, and internationalization.

## 2.4.2+267

* Improved object-list display and weather-page performance.
* Added web builds to the build script.

## 2.4.1+264

* Fixed iOS project configuration and a Facebook plugin build crash.

## 2.4.0+258

* Added a settings page, account deletion, and an Astrospheric weather page.
* Added confirmation dialogs and support for editing observation fields.
* Updated to Material 3 and improved web, iOS, and Android builds.

## 2.3.1+225

* Updated Android/Gradle and iOS build tooling and dependencies.
* Added build-script support for Android and iOS IPA builds.
* Added analytics for route changes and fixed handling of missing coordinate seconds.

## 2.3.0+14

* Added Caldwell catalog support and improved NGC catalog data handling.
* Added right ascension/declination data and rise/set time calculations for objects.

## 2.2.0+13

* The Messier list now indicates which objects have been observed.
* Added the iOS App Store link.

## 2.1.1+12

* Updated the iOS location-use description.

## 2.1.0+11

* Added the NGC catalog and improved Messier/NGC object handling.
* Fixed the web build.

## 2.0.1+10

* Optimized geolocation and fixed iOS build issues.

## 2.0.0+9

* Added Messier catalog loading and rise/set time calculations.

## 1.8.0+8

* Upgraded Firebase dependencies.

## 1.7.3+7

* Expanded analytics and updated Firebase configuration and dependencies.

## 1.7.2+5

* Refreshed app icons, logo, and web favicon.

## 1.7.1+0

* Migrated to Dart null safety and updated Firebase, platform configuration, and dependencies.
* Enabled analytics and improved initial search-widget behavior.

## 1.7.0+4

* Added long-press tile selection, result filtering, timezone display, and PDF export.
* Added PDF viewing on web and improved platform-specific data loading.

## 1.6.1(0)

* Bug Fix: Add checklist item string limit to 5 lines maximum.

## 1.6.0(0)

* Replaced text tabs with icon tabs. The current tab title
  is now shown below the name
* Added checklist tracking
* Swipe to delete a checklist item
* Optimize search filters in observation gallery

## 1.5.1(0)

* Added ability to add more notes to an observation.

## 1.5.0(0)

* Added ability to edit observation notes that are already
  saved in the cloud.

## 1.4.0(0)

* Added Equipment gallery
* Ability to add, remove and edit equipment details
  from the gallery

## 1.3.6(3)

* fix bug - non-integer values of seeing, visibility & transp.

## 1.3.6(2)

* fix bug - non-integer values of seeing, visibility & transp. - only for old data
* addded delete confirmation

## 1.3.6(1)

* fix getting user full name with AppleSignIn

## 1.3.6(0)

* restrict slider icon size
* integer bug fix in degree conversion
* added 5 sec timeout for get GPS location
* optimize equipment widget
* optimize more
* simplify icon buttons

## 1.3.5(4)

* bug fixed with slider bars in "add observation"
* make full-screen in gallary mode to hide status bars

## 1.3.5(3)

* bug fixed with date range search

## 1.3.5(2)

* Replace date searc hwith date range search

## 1.3.5(1)

* Allow ovservation tile data scroll
* Allow clear date filter

## 1.3.5(0)

* Filter observations gallery by Messier or NGC# or by date

## 1.3.4(0)

* Added seeing, visibility and transparency options

## 1.3.3(0)

* update signed in Welcome Page

## 1.3.0(2)

* Fixed datetime
* Fixed android bundle ID

## 1.3.0(0)

* Added Apple and Facebook SignIn

## 1.2.1(6)

* Force load equipments after adding a new equipment

## 1.2.1(5)

* Fix add equipment bug inside add observation

## 1.2.1(4)

* Fix google signin URL for iOS

## 1.2.1(3)

* fix iOS builds

## 1.2.1(2)

* Excryption exemption in iOS
* operates in "Dark" mode to help maintain night vision

## 1.2.1(0)

* Limit resolution of date-time when recording new observation - this fixes a bug to check matching DB entries

## 1.2.0(0)

* Editable latitude and longitude fields when adding a new observation

## 1.1.0(1)

* Web safe build

## 1.0.0(1)

Initial version

* secure data accessible only by the data owner
* no personal info needed other than e-mail address
* one click sign up and sign-in
* fast data access and data input
