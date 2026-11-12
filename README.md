# Astronomy Logbook

App for stargazers and astronomers to maintain a log of their observations and astrophotographs.

The app can be compiled for Android and iOS smartphones and tablets and also as a web-application.

## Features

1. Operates in darkmode - convinent to maintain night vision
2. All data stored safely and securely on google cloud
3. No personal information required other than e-mail address for login
4. Free Open source project for the stargazers by a stargazer
5. The signed-in landing page shows Messier and NGC objects above the horizon during astronomical darkness, with approximate visibility intervals, best times and Sun and Moon events. Objects are ordered by apparent magnitude (brightest first), with unknown magnitudes last. NGC results load in pages as you scroll; reaching objects without magnitudes requires a second paged scan because Firestore magnitude queries omit missing fields. After astronomical dawn, it switches to the upcoming observing night. A location cached within the last 10 minutes may be shown temporarily while a fresh GPS fix is acquired. Times use the device's local time; atmospheric conditions, light pollution, moonlight and equipment affect actual visibility. On mobile, object links open Wikipedia in an in-app dark view; on the web they open a new browser tab.
6. The Messier object list and the visible-tonight results show whether each object has been observed. Tap a tile or link icon for Wikipedia, the visibility icon for timing details, or the observation icon to view matching logs or add a prefilled observation. The Messier list remains available without a location, but visibility is then unknown.
7. Add or remove visible Messier and NGC targets from the persistent viewing checklist. Checklist entries can be checked off or deleted, alongside custom items.

The maintenance function `uploadMessier()` in [lib/uploadobjects.dart](lib/uploadobjects.dart) adds missing catalog fields from the bundled CSV to existing `messier` Firestore documents, without replacing existing values. These include apparent magnitude, designation, constellation, size, distance in light-years, and viewing season. Running it requires Firestore write access.

`uploadNGC()` adds missing NGC designations, constellations, magnitudes, and catalog notes in resumable transactions, expands existing constellation abbreviations when they match the bundled catalog, and removes legacy `"null"` difficulty placeholders. Use `uploadNGC(constellationsOnly: true)` to update only matching legacy constellation abbreviations. `syncCatalogLinks()` stores associations from the two CSV files in both collections. Linked NGC observations count as viewed in the Messier list, including related objects such as NGC 6603 within M24.

## Changelog updates

Pushing a version tag matching `v*` runs the changelog workflow. It finds the nearest previous reachable version tag, sends all commit subjects and non-empty descriptions, including merge commits, between those tags to OpenRouter's `openrouter/free` router, and writes the returned release notes under the new version in `CHANGELOG.md`. The router selects from currently available free models, so model availability and rate limits can vary. Commit messages are sent, not source diffs; avoid putting sensitive information in commit subjects or descriptions. Review generated notes for accuracy. Re-running the workflow for a tag replaces that version's entries.

Set the `OPENROUTER_API_KEY` GitHub Actions secret before pushing a version tag. The release tag must be reachable from the default branch. GitHub Actions needs permission to write repository contents and push to that branch; branch protection or rulesets may block the push. Commits made with `GITHUB_TOKEN` do not themselves trigger other workflows. Rerun a failed workflow after correcting the underlying issue.

To preview the OpenRouter rewrite locally, set `OPENROUTER_API_KEY` in the shell environment and run `RELEASE_TAG=v2.9.2+369 python3 tools/update_changelog.py --dry-run`. This prints the generated diff without changing `CHANGELOG.md`.

## Downloads

* Online web app - <https://astrolog.vedala.holdings>
* Android: <https://play.google.com/store/apps/details?id=com.vedalaholdings.astro_log2>
* iOS: <https://apps.apple.com/us/app/astronomy-logbook/id1552320892>