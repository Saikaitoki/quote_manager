// app/views/pwa/service-worker.js
// PWA Service Worker for Offline Support

const CACHE_NAME = "quote-manager-v1";

// Assets to cache immediately
const PRE_CACHE_ASSETS = [
    "/offline.html",
    "/icon.png",
    // Build assets will be cached dynamically as they are requested
];

self.addEventListener("install", (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => {
            return cache.addAll(PRE_CACHE_ASSETS);
        })
    );
    self.skipWaiting();
});

self.addEventListener("activate", (event) => {
    event.waitUntil(
        caches.keys().then((keyList) => {
            return Promise.all(
                keyList.map((key) => {
                    if (key !== CACHE_NAME) {
                        return caches.delete(key);
                    }
                })
            );
        })
    );
    self.clients.claim();
});

self.addEventListener("fetch", (event) => {
    if (event.request.method !== "GET") return;

    event.respondWith(
        (async () => {
            const cache = await caches.open(CACHE_NAME);

            // 1. Try Network First
            try {
                const networkResponse = await fetch(event.request);

                // Cache successful network responses (basic strategy)
                if (networkResponse.status === 200) {
                    cache.put(event.request, networkResponse.clone());
                }

                return networkResponse;
            } catch (error) {
                // 2. Fallback to Cache
                const cachedResponse = await cache.match(event.request);
                if (cachedResponse) {
                    return cachedResponse;
                }

                // 3. Fallback to Offline Page for navigation requests
                if (event.request.mode === "navigate") {
                    return cache.match("/offline.html");
                }

                throw error;
            }
        })()
    );
});
