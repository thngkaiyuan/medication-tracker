# App Review response — version 1.0 build 1

Apple requested additional information under Guideline 2.1 on 2026-08-19. No code defect was identified. Do not resubmit until the physical-device recording is attached and the operating-system version shown by the recording device has been confirmed.

## Draft App Review Notes

APP REVIEW INFORMATION — VERSION 1.0 BUILD 1

### 1. Physical-device recording

A screen recording captured on a physical iPhone 17 Pro running the latest available iOS version is attached to our App Review reply. It begins with launching the app and demonstrates the typical flow through setup, logging, status, records, editing, and data controls.

### 2. Devices and operating systems tested

- Physical iPhone 17 Pro — iOS 26.6: final manual testing of the exact submitted build, including launch, medication lifecycle, logging, records, editing/deletion, backup import/export, persistence, and Airplane Mode operation.
- iPhone 17 Pro simulator — iOS 26.5: automated lifecycle, persistence, and native export tests.
- iPhone 17 Pro Max simulator — iOS 26.5: 6.9-inch layout and screenshot verification.
- iPad Pro 13-inch (M5) simulator — iPadOS 26.5: core flow and 13-inch layout verification.
- iPad Air 11-inch (M4) simulator — iPadOS 26.5: responsive layout verification.

Update the physical-device OS version above if Software Update installs anything newer before recording.

### 3. Purpose and target audience

MedTracker is a private, offline personal record-keeping utility for people who take medications, especially as-needed medications. It lets a user record when a dose was taken, review and correct that history, and see when the minimum interval and optional rolling 24-hour limit entered by that user have cleared. This reduces reliance on memory and provides a quick, glanceable history. MedTracker does not determine medical safety, recommend a dose, diagnose, prescribe, or replace the medication label or advice from a clinician or pharmacist.

### 4. Setup and access

No account, registration, login credentials, subscription, purchase, or sample file is required. On first launch, tap Add Medication; enter a name and the limits taken from the medication label or professional instructions; then tap Save. Tap a medication tile and choose Log Dose or View Records. The records screen supports adding, editing, and deleting records and editing the medication. The More Options menu provides Export Backup, Import Backup, and Privacy & About. All tracking functions work offline. Import accepts an optional MedTracker JSON backup selected by the user; it is not required to review the app.

### 5. External services, tools, or platforms

None are used to deliver core functionality. There is no backend, authentication provider, payment processor, data provider, AI service, advertising SDK, analytics SDK, or tracking SDK. The native SwiftUI app stores medication data locally in its Application Support container and uses Apple’s native document picker and share sheet only when the user chooses import or export. User-initiated privacy-policy and support links open public web pages but are not required for app operation.

### 6. Regional differences

There are no regional differences in features or content. The app functions consistently in every available region. It adapts displayed dates and times to the device locale and time zone. The current interface language is English (U.S.).

### 7. Regulated industry or protected material

MedTracker is a personal logging utility, not a medical device or medical service. It provides no diagnosis, treatment, dosage calculation, dose recommendation, or medical-safety determination. Users enter their own timing limits based on the medication label or professional instructions. The app contains no protected third-party material and requires no regulated-industry authorization or third-party content credentials.

## Physical-device recording runbook

Target length: approximately 2–3 minutes. Do not add narration or microphone audio.

### Prepare the device

1. On the physical iPhone 17 Pro, open Settings > General > Software Update. Install any available update because Apple explicitly requested the latest operating system. Record the final iOS version for the response.
2. Use the exact version 1.0 build 1. Prefer TestFlight. If it is not available in TestFlight, temporarily re-enable Developer Mode and use the already approved development installation; do not substitute a changed build.
3. If the installed app contains any real medication data, export a backup before wiping it. Then delete and reinstall MedTracker so the recording starts from a blank slate. Deleting the app permanently removes its local data.
4. Move the MedTracker icon onto an otherwise blank Home Screen page. Use a neutral wallpaper without people, locations, names, or other personal information.
5. Enable Do Not Disturb. After TestFlight installation is complete, enable Airplane Mode to prevent notification banners and demonstrate offline operation.
6. Ensure Screen Recording is available in Control Center. Keep its microphone off.

### Record the app flow

1. Start Screen Recording from Control Center with the microphone off. Return to the blank Home Screen and wait three seconds.
2. Launch MedTracker. Pause for two seconds on the empty state.
3. Tap Add Medication.
4. Enter the name `Acetaminophen 500 mg — Sample`.
5. Set Minimum hours between doses to `6`.
6. Turn on Set a daily dose limit and set Maximum in any 24 hours to `4`.
7. Tap Save. Pause on the green tile so `Entered wait limits cleared` and `No doses recorded` are visible. These are demonstration values, not dosing advice.
8. Tap the medication tile. Pause on the action dialog, then tap Log Dose.
9. Pause on the red-orange tile so the countdown and newly recorded last-dose time are visible.
10. Tap the tile again, then tap View Records. Pause on the current dose record.
11. Tap Add Manual Record. Set the date and time to August 18, 2026 at 9:00 AM, then tap Save.
12. If needed, scroll to show both records. Tap the ellipsis beside record 1, choose Edit Record, change its time to 9:15 AM, and tap Save.
13. Tap the back chevron to return home.
14. Tap More Options (ellipsis), then Privacy & About. Slowly show the Privacy, How colors work, and Medical disclaimer sections. Tap Done.
15. Tap More Options once more and pause while Export Backup and Import Backup are visible, but do not open the share sheet because it may reveal personal sharing suggestions.
16. Dismiss the menu and pause on the main MedTracker screen for two seconds.
17. Stop Screen Recording from Control Center.

### Trim and inspect

1. In Photos, trim the beginning so the first frame is the neutral Home Screen immediately before MedTracker is launched. This satisfies Apple's request that the recording begin with launching the app.
2. Trim the end before Control Center appears, leaving the final MedTracker screen as the last frame.
3. Watch the entire video with sound on and confirm it contains no voices, notifications, contact names, email addresses, personal wallpaper, real medications, or other identifying information.
4. Keep the original full-resolution `.mov` file. Suggested filename: `MedTracker-physical-iPhone17Pro-iOS26.6.mov`, updating the OS version if necessary.

## Reply checklist

- Attach the inspected physical-device recording to the App Review reply.
- Confirm the physical iOS version and update sections 1 and 2 if necessary.
- Copy the seven sections into App Review Information > Notes.
- Reply that the requested information has been added to Notes and the recording is attached.
- Resubmit version 1.0 build 1 without changing the binary.

