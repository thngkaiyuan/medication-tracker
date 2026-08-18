# MedTracker roadmap

MedTracker remains deliberately focused on private medication tracking. Broader cooldown or desire-control use cases may share ideas with the app, but they should not dilute its medication-specific purpose, language, or interface.

Version 1.0 build 1 is frozen and submitted to Apple. The items below are candidates for later releases, not changes to the submitted build.

## Product principles

- Keep the app exceptionally clean, quick, and simple.
- Minimize phone interaction, especially when a user is in pain.
- Preserve offline operation and on-device privacy.
- Make status understandable without color alone.
- Describe only the user-entered timing and rolling limits. Never claim that MedTracker determines whether taking medication is medically safe.
- Prefer a small number of high-value features over a crowded interface.

## Priorities

### 1. Optional local notifications when entered limits clear

Highest priority. Users should not need to remember when they last logged a dose, maintain a mental countdown, or repeatedly reopen the app.

Proposed behavior:

- Offer an opt-in notification for each medication.
- Schedule it locally for the time when both the entered minimum interval and optional rolling 24-hour limit clear.
- Recalculate notifications after logging, editing, or deleting a dose and after editing a medication's limits.
- Work without an account, server, analytics, or internet connection.
- Use careful wording such as `Entered limits have cleared for Ibuprofen`, never `Safe to take` or `Dose due`.
- Explain that notification delivery time is controlled by iOS and may not be exact.
- Provide a simple global notification setting without adding clutter to the main screen.

Acceptance considerations:

- Permission is requested only in context, after the user enables notifications.
- Editing records cannot leave stale notifications scheduled.
- Time-zone and daylight-saving changes are handled correctly.
- Notification content can be hidden or made generic for privacy.
- Unit and UI tests cover scheduling, rescheduling, cancellation, and disabled-permission behavior.

### 2. Glanceable widget and fast system actions

Second priority. Opening the app currently requires finding its Home Screen location and tapping through, which is meaningful friction during a migraine or other pain episode.

Explore:

- A configurable Home Screen widget for one or several medications.
- Lock Screen presentation showing the entered-limit status and remaining wait.
- A direct log action through App Intents, where platform behavior permits it without sacrificing confirmation or privacy.
- Control Center, Action button, Shortcuts, and Siri integration built on the same intent.
- Deep links to a medication's action menu or records.

The widget must retain the app's calm visual hierarchy, textual status, and conservative safety language. It should not imply that green means medically safe.

### 3. Quantity-aware records and configurable rolling limits

Useful for people whose meaning of one dose varies, but lower priority because many users already treat each medication's dose as a known unit.

Potential scope:

- Optional quantity and unit per logged dose.
- A maximum quantity within a configurable rolling period.
- Backward-compatible migration treating every existing record as quantity `1`.
- PWA-compatible import/export migration with explicit schema-version handling.

This should proceed only with a migration design that preserves every existing record and keeps one-tap logging simple for users who do not need quantities.

### 4. Brief Undo after logging

Lower priority because the current action dialog already makes accidental logging uncommon. A short-lived `Dose recorded · Undo` affordance could still make recovery faster without adding a persistent control.

### 5. Carefully selected history insights

Optional and intentionally constrained. Possible examples include totals over time or average intervals, but insights must not crowd the core experience or introduce adherence scores, streak pressure, or medical interpretation.

## Explicitly out of scope for MedTracker

- General habit, craving, food, shopping, or desire-control tracking.
- Medical advice, dose recommendations, or claims that another dose is safe.
- Social features, advertising, engagement mechanics, or streak gamification.
- Requiring an account or network connection for core functionality.

