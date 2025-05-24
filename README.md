# Medication Tracker PWA

<img width="703" alt="image" src="https://github.com/user-attachments/assets/e5e6705d-df6d-4c0d-9b2f-96ece9506c0b" />

A simple, clean, and modern Progressive Web App (PWA) to help you track your medication intake, view your history, and manage your medication schedule effectively. All data is stored locally in your browser.

**Access the App:** <https://thngkaiyuan.github.io/medication-tracker/>

*(Initial code structure by Claude Sonnet 4. Significantly rewritten, enhanced, and refined by Google's Gemini 2.5 Pro. This README was also drafted with the assistance of Gemini.)*

## Overview

This application provides a user-friendly interface to:
* Add, edit, and delete medications with custom schedules (time between doses, max doses per day).
* Log when you take a dose with a simple swipe (on touch devices) or a click.
* View a clear, chronologically sorted history of when each medication was taken.
* Visually see when it's safe to take your next dose with color-coded tiles.
* Manage your medication data through local export and import for backup and peace of mind.

The app is designed primarily for mobile touch interaction but is functional on desktop browsers as well.

## Features

* **Medication Management:** Easily add, edit, and delete medications.
* **Intuitive Logging (Mobile First):**
    * **Swipe Right** on a medication tile (touch devices) or **Click a tile** (all devices) to open an action menu, then select "Log Dose."
    * The text "Log Dose" appears behind the tile during a right swipe.
* **Records & History:**
    * **Swipe Left** on a medication tile (touch devices) or **Click a tile** and select "View Records" to see its history.
    * Records are displayed chronologically (oldest first).
    * **Undo/Redo:** Easily correct logging mistakes from the records screen.
    * **Back Navigation:** Use the top-left arrow icon on the records screen or swipe right (touch devices) to return to the main list.
* **Visual Status Indicators:** Color-coded tiles provide an at-a-glance understanding of your schedule.
* **Timezone Aware:** Accurately tracks and displays dose times across timezones.
* **Data Backup & Restore:** Export your data as a JSON file and import it back when needed. Accessed via the "three dots" menu.
* **PWA Installable:** Add to your device's home screen for an app-like experience.
* **Responsive & Minimalist Design:** Clean, focused, and adapts to different screen sizes.

## How to Use

### Main Screen

* **Adding a Medication:**
    1.  Tap the "three dots" icon at the bottom left, then select "Add Medication" (or tap the main "+ Add Medication" button if that layout is present).
    2.  Fill in the medication details in the modal that appears.
    3.  Tap "Add".
* **Interacting with a Medication Tile:**
    * **Click/Tap a Tile:** A modal will pop up asking if you want to "Log Dose" or "View Records".
    * **Swipe Right (Touch Devices):** Reveals "Log Dose" text and logs the dose upon release.
    * **Swipe Left (Touch Devices):** Slides to the records screen for that medication.
* **Data Management (Export/Import):**
    1.  Tap the "three dots" icon button at the bottom left of the main screen.
    2.  A menu will appear with "Export Data" and "Import Data" options.
    3.  **Export:** Click "Export Data". A JSON file (`medication_tracker_backup_[date].json`) will be downloaded.
    4.  **Import:** Click "Import Data". Select your backup JSON file. *Your current data will be replaced by the data from the file.*

### Records Screen

* **Viewing History:** Logged doses are listed with the oldest at the top.
* **Editing a Medication:** Tap the pencil icon at the top right of the records screen. This opens a modal to modify medication details or delete the medication (with confirmation).
* **Undo/Redo Doses:** Use the "Redo" (left) and "Undo" (right) buttons at the bottom.
* **Returning to Main Screen:** Tap the back arrow icon at the top left, or swipe right on the screen (touch devices).

## Installing the PWA

You can install this app on your Android device for a more native experience:

* **Android (Chrome):**
    1.  Navigate to <https://thngkaiyuan.github.io/medication-tracker/> in the Chrome browser.
    2.  Tap the browser's menu (three dots on the top right).
    3.  Tap "Add to Home screen."
    4.  Confirm by tapping "Install" on the prompt. The app icon will be added to your home screen.

**Note:** For the PWA to be installable and for all features (like the service worker) to function correctly, the app must be accessed via an **HTTPS** connection (the link above is already HTTPS).

## Timezone Handling

The app stores all dose timestamps in UTC (Coordinated Universal Time). When displaying records or calculating time until the next dose, it uses your device's current local timezone. This ensures that your medication schedule remains accurate even if you travel across different timezones.

## Contributing & Support

This is a personal project shared with the community. It is offered as-is, and there is no committed level of official support.

However, feedback and contributions are highly encouraged and welcome! If you have suggestions, find bugs, or want to improve the app:
* Feel free to open an issue on the GitHub repository (if one is available for this project).
* Pull requests with improvements are greatly appreciated.

---

We hope this app is helpful for you!
