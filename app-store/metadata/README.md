# App Store metadata

The `en-US` files contain copy-ready values for App Store Connect. They are deliberately plain text and contain no credentials or account-holder information.

## Recommended nonlocalized values

- Name: `MedTracker` (confirm availability)
- Bundle ID: `com.kaiyuan.medicationtracker`
- SKU: `medtracker-ios-001`
- Version: `1.0`
- Primary category: `Health & Fitness`
- Secondary category: `Medical`
- Price: `Free` (confirm with the account holder)
- Copyright: `2026 Positive` (owner-requested brand; App Store acceptance is subject to Apple)
- Marketing URL: `https://github.com/thngkaiyuan/medication-tracker`
- Privacy: `Data Not Collected`
- Demo account required: `No`
- Regulated medical device: `No`
- Encryption: the binary declares `ITSAppUsesNonExemptEncryption = false`

## Verified limits

- Name: 30 characters maximum
- Subtitle: 30 characters maximum
- Promotional text: 170 characters maximum
- Description: 4,000 characters maximum
- Keywords: 100 UTF-8 bytes maximum

Run the metadata assertions with:

```sh
npm test
```

Do not submit `privacy_url.txt` until that URL returns HTTP 200. App Review contact first name, last name, phone number, and email are required but intentionally excluded because the account holder must provide them.
