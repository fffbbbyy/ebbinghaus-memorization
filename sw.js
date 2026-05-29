const CACHE_NAME = 'ebbinghaus-v1';

const PRE_CACHE = [
  './index.html',
  './manifest.json',
  './icon.svg'
];

// Install — pre-cache core files
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRE_CACHE))
  );
  self.skipWaiting();
});

// Activate — clean old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch — cache-first for app & fonts, network-first for everything else
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  const isGoogleFont = url.hostname === 'fonts.googleapis.com' || url.hostname === 'fonts.gstatic.com';
  const isApp = url.origin === self.location.origin;

  if (isApp || isGoogleFont) {
    // Cache-first
    event.respondWith(
      caches.match(event.request).then(cached =>
        cached || fetch(event.request).then(response => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
          }
          return response;
        })
      )
    );
  }
  // else: let browser handle normally
});
