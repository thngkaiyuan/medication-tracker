import assert from 'node:assert/strict';
import { readFile, stat } from 'node:fs/promises';
import test from 'node:test';

test('production build contains the complete offline app shell', async () => {
    const serviceWorker = await readFile(new URL('../dist/sw.js', import.meta.url), 'utf8');
    for (const asset of ['./index.html', './assets/app.css', './assets/app.js', './manifest.json']) {
        assert.match(serviceWorker, new RegExp(asset.replace(/[./]/g, '\\$&')));
    }

    for (const path of ['../dist/index.html', '../dist/assets/app.css', '../dist/assets/app.js', '../dist/manifest.json']) {
        assert.ok((await stat(new URL(path, import.meta.url))).size > 0, `${path} should not be empty`);
    }
});

test('iOS app is a native SwiftUI application with local persistence and backups', async () => {
    const appEntry = await readFile(new URL('../ios/App/App/MedTrackerApp.swift', import.meta.url), 'utf8');
    const store = await readFile(new URL('../ios/App/App/MedicationStore.swift', import.meta.url), 'utf8');
    const project = await readFile(new URL('../ios/App/App.xcodeproj/project.pbxproj', import.meta.url), 'utf8');

    assert.match(appEntry, /@main\s+struct MedTrackerApp: App/);
    assert.match(store, /applicationSupportDirectory/);
    assert.match(store, /JSONEncoder/);
    assert.match(store, /JSONDecoder/);
    assert.doesNotMatch(project, /CapApp-SPM/);
    assert.doesNotMatch(project, /public in Resources/);
});

test('iOS privacy manifest declares the filesystem timestamp reason', async () => {
    const manifest = await readFile(new URL('../ios/App/App/PrivacyInfo.xcprivacy', import.meta.url), 'utf8');
    assert.match(manifest, /NSPrivacyAccessedAPICategoryFileTimestamp/);
    assert.match(manifest, /C617\.1/);
    assert.match(manifest, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
});

test('iOS metadata declares that the app does not use non-exempt encryption', async () => {
    const infoPlist = await readFile(new URL('../ios/App/App/Info.plist', import.meta.url), 'utf8');
    assert.match(infoPlist, /<key>ITSAppUsesNonExemptEncryption<\/key>\s*<false\/>/);
});

test('App Store icon is an exact opaque 1024px PNG', async () => {
    const icon = await readFile(new URL('../ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png', import.meta.url));
    assert.equal(icon.subarray(1, 4).toString(), 'PNG');
    assert.equal(icon.readUInt32BE(16), 1024);
    assert.equal(icon.readUInt32BE(20), 1024);

    // PNG color types 4 and 6 contain an alpha channel; App Store icons may not.
    assert.ok(![4, 6].includes(icon[25]), `unexpected alpha-bearing PNG color type ${icon[25]}`);
});

test('App Store metadata stays within Apple listing limits', async () => {
    const metadataURL = new URL('../app-store/metadata/en-US/', import.meta.url);
    const readValue = async (name) => (await readFile(new URL(name, metadataURL), 'utf8')).trim();
    const name = await readValue('name.txt');
    const subtitle = await readValue('subtitle.txt');
    const promotionalText = await readValue('promotional_text.txt');
    const description = await readValue('description.txt');
    const keywords = await readValue('keywords.txt');
    const supportURL = new URL(await readValue('support_url.txt'));
    const privacyURL = new URL(await readValue('privacy_url.txt'));

    assert.ok(name.length >= 2 && name.length <= 30);
    assert.ok(subtitle.length <= 30);
    assert.ok(promotionalText.length <= 170);
    assert.ok(description.length <= 4_000);
    assert.ok(Buffer.byteLength(keywords, 'utf8') <= 100);
    assert.ok(keywords.split(',').every((keyword) => keyword.length > 2));
    assert.equal(supportURL.protocol, 'https:');
    assert.equal(privacyURL.protocol, 'https:');
});

test('App Store screenshots use accepted opaque device dimensions', async () => {
    const screenshots = [
        ['iphone-6.9/01-home.png', 1320, 2868],
        ['iphone-6.9/02-actions.png', 1320, 2868],
        ['iphone-6.9/03-history.png', 1320, 2868],
        ['ipad-13/01-home.png', 2064, 2752],
        ['ipad-13/02-actions.png', 2064, 2752],
        ['ipad-13/03-history.png', 2064, 2752],
    ];

    for (const [path, width, height] of screenshots) {
        const screenshot = await readFile(
            new URL(`../app-store/screenshots/${path}`, import.meta.url),
        );
        assert.equal(screenshot.subarray(1, 4).toString(), 'PNG', path);
        assert.equal(screenshot.readUInt32BE(16), width, path);
        assert.equal(screenshot.readUInt32BE(20), height, path);
        assert.ok(![4, 6].includes(screenshot[25]), `${path} must not contain alpha`);
    }
});
