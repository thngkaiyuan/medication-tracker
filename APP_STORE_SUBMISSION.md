# App Store submission handoff

The app is implemented natively in SwiftUI for iPhone and iPad. Medication data is saved as JSON in the app's Application Support directory, all tracking features work offline, and backup import/export uses the native iOS document picker and share sheet. Its backup format is compatible with the PWA.

## What is already complete

- Native SwiftUI app for iPhone and iPad, with no web view or network dependency.
- PWA-compatible JSON import/export through the native document picker and share sheet.
- Local persistence in Application Support and a privacy manifest declaring no collected data.
- Automated unit, lifecycle, persistence, export, large-text, and accessibility coverage on iPhone and iPad.
- Release static analysis and an unsigned Release archive validation.
- Privacy-safe screenshots under `app-store/screenshots`; all names and records are generated samples.

## Human prerequisites

1. Join or renew the [Apple Developer Program](https://developer.apple.com/programs/) for the Apple ID that will own the app.
2. In Xcode, add that Apple ID under **Xcode → Settings → Accounts** and accept any updated developer agreements.
3. Confirm that `com.kaiyuan.medicationtracker` is the desired globally unique bundle identifier. Change it before creating the App Store record if it is not.
4. Supply the public support contact, copyright holder, price/availability countries, and EU Digital Services Act trader status.

A free Apple developer account is sufficient for simulator testing and temporary installation on the account owner's own iPhone. TestFlight and App Store distribution require the paid Apple Developer Program membership. It is safe to postpone payment until the app and listing assets are ready.

This project is already built with Xcode 26 and the iOS 26 SDK, satisfying Apple's upload requirement in effect since April 28, 2026.

## Pre-submission blockers

- The support URL is public and returns HTTP 200.
- The privacy policy exists at `public/privacy.html`, is included in the production build, and is ready for GitHub Pages. The proposed public URL currently returns HTTP 404 because the iOS/PWA work is still on the local `codex/ios-app` branch rather than deployed from `main`. Merge/push the work, enable GitHub Pages with **GitHub Actions** as its source if needed, and verify the URL returns HTTP 200 before entering it in App Store Connect.
- A paid Apple Developer Program team must be active before a distribution-signed archive can be uploaded.

## Build and device verification

Open `ios/App/App.xcodeproj` in Xcode, or run `npm run ios:open`.

In Xcode:

1. Select the **App** target, open **Signing & Capabilities**, choose the correct Team, and leave automatic signing enabled.
2. Select a connected iPhone and press Run.
3. Choose **Product → Test** to run `AppTests` backup/persistence checks and `AppUITests` medication lifecycle and export-share-sheet checks.
4. With Airplane Mode enabled, manually verify launch, adding/editing/deleting medication, logging/editing/deleting a dose, manual records, and export/import. Import/export itself requires selecting a local file or destination but no internet connection.
5. Repeat the core flow on an iPad simulator because the target supports iPhone and iPad.

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
- Export compliance: answer that the app does not use encryption. It does not implement or invoke encryption algorithms.
- Price: `Free` (recommended; confirm before submission)
- Availability: confirm the desired countries/regions
- Age rating: complete Apple's current questionnaire accurately; the app contains no objectionable content, user-generated content, or unrestricted web access.
- Medical declaration: this is a personal record-keeping tool, not a regulated medical device, and it does not diagnose, prescribe, calculate a dose, or provide medical advice.
- Content rights: the submitter owns or has permission to use all included content.
- EU DSA: declare the account's trader/non-trader status in App Store Connect; this is an account/legal choice and cannot be inferred from the code.

Suggested description:

> MedTracker is a simple, private way to record medication doses and see when the next dose is due. Add medications with custom intervals and optional daily limits, log doses in a tap, review and edit history, and create portable JSON backups. Your medication data stays on your device, and the complete app works without an internet connection.

Suggested keywords:

`medication,dose,medicine,pill,history,schedule,offline,private,tracker,health`

Review notes:

> MedTracker is a personal record-keeping tool and does not diagnose, recommend doses, or provide medical advice. No account is required. All app functionality works offline. Test by adding a medication, tapping its card, and choosing Log Dose or View Records. Export Backup opens the native share sheet; Import Backup accepts a compatible JSON backup selected by the user.

## Archive and submit

1. In Certificates, Identifiers & Profiles, register the exact bundle ID if automatic signing has not already done so.
2. In App Store Connect, create the app record using the exact bundle ID and SKU.
3. Upload the prepared screenshots. Apple currently accepts the generated 6.9-inch iPhone size (1320×2868) and 13-inch iPad size (2064×2752). Keep screenshots opaque and do not add real medication data.
4. In Xcode select **Any iOS Device (arm64)**, then **Product → Archive**.
5. In Organizer choose **Distribute App → App Store Connect → Upload**.
6. Attach the uploaded build in App Store Connect, complete app privacy, age rating, content rights, encryption, medical-device, and review-contact questions, then submit for review.

## Exact handoff when the owner returns

1. Confirm the paid Apple Developer Program membership is active and tell Codex which Team appears in Xcode.
2. Confirm the bundle ID, seller/copyright name, support email/phone, price, availability, and EU trader status.
3. Stay available briefly for Apple ID two-factor authentication and any agreement acceptance.
4. Codex can then guide or complete the signing/archive/upload flow up to any Apple confirmation that must be performed by the account holder.

Apple review, approval, and the public release are external steps. Do not announce the app as available until App Store Connect shows the intended version as Ready for Distribution.

Never commit signing certificates, provisioning profiles, App Store Connect keys, or passwords to this repository.
