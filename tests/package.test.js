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

test('iOS bundle is synchronized with the web build', async () => {
    const webIndex = await readFile(new URL('../dist/index.html', import.meta.url), 'utf8');
    const iosIndex = await readFile(new URL('../ios/App/App/public/index.html', import.meta.url), 'utf8');
    assert.equal(iosIndex, webIndex);
});

test('iOS privacy manifest declares the filesystem timestamp reason', async () => {
    const manifest = await readFile(new URL('../ios/App/App/PrivacyInfo.xcprivacy', import.meta.url), 'utf8');
    assert.match(manifest, /NSPrivacyAccessedAPICategoryFileTimestamp/);
    assert.match(manifest, /C617\.1/);
    assert.match(manifest, /<key>NSPrivacyTracking<\/key>\s*<false\/>/);
});
