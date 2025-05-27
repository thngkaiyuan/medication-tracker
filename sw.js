self.addEventListener('install', (e) => {
    console.log('Service Worker: Install event');
    e.waitUntil(self.skipWaiting());
});
self.addEventListener('activate', (e) => {
    console.log('Service Worker: Activate event');
    e.waitUntil(self.clients.claim());
});
self.addEventListener('fetch', (e) => {
    // console.log('Service Worker: Fetching', e.request.url);
    e.respondWith(
        fetch(e.request).catch((error) => {
            console.warn('Service Worker: Fetch failed for', e.request.url, error);
        })
    );
});
