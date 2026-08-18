# App Store submission handoff

The app is implemented as an offline Capacitor iOS app. Its web assets ship inside the application bundle, medication data remains in persistent local WebKit storage, and backup export uses the native iOS share sheet.

## Human prerequisites

1. Install the current full Xcode release from the Mac App Store and open it once to finish installing components.
2. Join or renew the [Apple Developer Program](https://developer.apple.com/programs/) for the Apple ID that will own the app.
3. In Xcode, add that Apple ID under **Xcode → Settings → Accounts**.
4. Confirm that `com.kaiyuan.medicationtracker` is the desired globally unique bundle identifier. Change it in `capacitor.config.json` and the app target if it is not.

## Build and device verification

```sh
npm ci
npm run ios:open
```

In Xcode:

1. Select the **App** target, open **Signing & Capabilities**, choose the correct Team, and leave automatic signing enabled.
2. Select a connected iPhone and press Run.
3. With Airplane Mode enabled, verify launch, adding/editing/deleting medication, logging/editing/deleting a dose, manual records, and export/import.
4. Repeat the core flow on an iPad simulator because the target supports iPhone and iPad.

## App Store Connect values

- Name: `MedTracker` (subject to availability)
- Subtitle: `Private medication dose log`
- Primary category: `Health & Fitness`
- Secondary category: `Medical`
- Bundle ID: `com.kaiyuan.medicationtracker`
- Version: `1.0`
- SKU suggestion: `medtracker-ios-001`
- Support URL: `https://github.com/thngkaiyuan/medication-tracker/issues`
- Privacy policy URL: `https://thngkaiyuan.github.io/medication-tracker/privacy.html`
- App Privacy: select **Data Not Collected**; the app has no tracking, analytics, ads, accounts, or remote data transmission.
- Export compliance: select **No** for non-exempt/proprietary encryption; this app does not implement encryption algorithms.

Suggested description:

> MedTracker is a simple, private way to record medication doses and see when the next dose is due. Add medications with custom intervals and optional daily limits, log doses in a tap, review and edit history, and create portable JSON backups. Your medication data stays on your device, and the complete app works without an internet connection.

Suggested keywords:

`medication,dose,medicine,pill,history,schedule,offline,private,tracker,health`

Review notes:

> MedTracker is a personal record-keeping tool and does not diagnose, recommend doses, or provide medical advice. No account is required. All app functionality works offline. Test by adding a medication, tapping its tile, and choosing Log Dose or View Records. Export Data opens the native share sheet; Import Data accepts a JSON backup selected by the user.

## Archive and submit

1. In App Store Connect, create the app record using the exact bundle ID.
2. Capture required iPhone and iPad screenshots from the simulator/device after adding realistic sample data. Do not include real personal medication data.
3. In Xcode select **Any iOS Device (arm64)**, then **Product → Archive**.
4. In Organizer choose **Distribute App → App Store Connect → Upload**.
5. Attach the uploaded build in App Store Connect, finish age-rating/content-rights questions, add screenshots, and submit for review.

Never commit signing certificates, provisioning profiles, App Store Connect keys, or passwords to this repository.
