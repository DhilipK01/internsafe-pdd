'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "63db981e89c73532ce3ff547956fb38c",
"assets/AssetManifest.bin.json": "b6bf8ffaf85fb7c486f7b04a8e7e1e12",
"assets/assets/branding/internsafe_ai_logo.png": "ccbc5c13c4b634fcb82adf209fca5a7c",
"assets/assets/fonts/GrandHotel-Regular.ttf": "000c98f72dcc7e997782a3497138c5d9",
"assets/FontManifest.json": "101bd0955c869fcae905cc40e5573685",
"assets/fonts/MaterialIcons-Regular.otf": "38b8f145eeecb20f18463435dfe0abb2",
"assets/NOTICES": "2735448f21a2f40c05604834088e22b1",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "451200cdf852d8ca115ed1677db7b5c8",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "b2703f18eee8303425a5342dba6958db",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "5257ed203151d19a4b6d451a48776655",
"assets/packages/lucide_icons/assets/lucide.ttf": "03f254a55085ec6fe9a7ae1861fda9fd",
"assets/packages/sign_in_button/assets/logos/2.0x/facebook_new.png": "dd8e500c6d946b0f7c24eb8b94b1ea8c",
"assets/packages/sign_in_button/assets/logos/2.0x/google_dark.png": "68d675bc88e8b2a9079fdfb632a974aa",
"assets/packages/sign_in_button/assets/logos/2.0x/google_light.png": "1f00e2bbc0c16b9e956bafeddebe7bf2",
"assets/packages/sign_in_button/assets/logos/3.0x/facebook_new.png": "689ce8e0056bb542425547325ce690ba",
"assets/packages/sign_in_button/assets/logos/3.0x/google_dark.png": "c75b35db06cb33eb7c52af696026d299",
"assets/packages/sign_in_button/assets/logos/3.0x/google_light.png": "3aeb09c8261211cfc16ac080a555c43c",
"assets/packages/sign_in_button/assets/logos/facebook_new.png": "93cb650d10a738a579b093556d4341be",
"assets/packages/sign_in_button/assets/logos/google_dark.png": "d18b748c2edbc5c4e3bc221a1ec64438",
"assets/packages/sign_in_button/assets/logos/google_light.png": "f71e2d0b0a2bc7d1d8ab757194a02cac",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"favicon.png": "e58a5e740ae49c62468195698a23b3dc",
"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"flutter_bootstrap.js": "7ac84cec499fe2d2c6832081a245aa67",
"googleb556ab4655e821b9.html": "5028edd9f29ace2c6d155730b79d0adc",
"icons/Icon-192.png": "9c2e0c152753a49e6b44fd1affd8ded5",
"icons/Icon-512.png": "d6b168140f21a8821ea6fc681f8e046e",
"icons/Icon-App-1024x1024@1x.png": "73b117c5ea1556cf1ce3977a9fc11b99",
"icons/Icon-App-20x20@1x.png": "5363ab3a2bb940db83f641123d8abcad",
"icons/Icon-App-20x20@2x.png": "3c545ce0a395cc84e31c6626c45065df",
"icons/Icon-App-20x20@3x.png": "0b4e59612db4fafcfed8db62f5f52462",
"icons/Icon-App-29x29@1x.png": "34ff83a1210408fbe3f77632fd523f12",
"icons/Icon-App-29x29@2x.png": "1a69f010ce50b82622a60cf9dfbdf7c0",
"icons/Icon-App-29x29@3x.png": "b8821f06bee93e6e7c6f12ec6a9ffc67",
"icons/Icon-App-40x40@1x.png": "3c545ce0a395cc84e31c6626c45065df",
"icons/Icon-App-40x40@2x.png": "785457548a8ccb5548310a372a2a2569",
"icons/Icon-App-40x40@3x.png": "d8c3a6d5f6198a313c8a60cc8990682d",
"icons/Icon-App-50x50@1x.png": "a801bf2bfeab3aebcc608da342bf54cf",
"icons/Icon-App-50x50@2x.png": "48538b26147f53807311f56634c3e87a",
"icons/Icon-App-57x57@1x.png": "d9e43e824f79871976c657de848b3af6",
"icons/Icon-App-57x57@2x.png": "f1bfaf180282ab47d8da435c11ea912d",
"icons/Icon-App-60x60@2x.png": "d8c3a6d5f6198a313c8a60cc8990682d",
"icons/Icon-App-60x60@3x.png": "2faf4e75ec4d08e471b60bd2af3e9b3b",
"icons/Icon-App-72x72@1x.png": "c955cade9cd23a84c7fe3e5c6e257fce",
"icons/Icon-App-72x72@2x.png": "d1e57bfa5fc51094e1fa190c09ce2341",
"icons/Icon-App-76x76@1x.png": "0eb0ed0079f2744bda0f1ff1271b2ace",
"icons/Icon-App-76x76@2x.png": "977ac078ff21ae6ffe45e86acb7e41bf",
"icons/Icon-App-83.5x83.5@2x.png": "279aecf1f4baf725c8c94d6c9ffb7d1d",
"icons/Icon-maskable-192.png": "9c2e0c152753a49e6b44fd1affd8ded5",
"icons/Icon-maskable-512.png": "d6b168140f21a8821ea6fc681f8e046e",
"icons/internsafe_ai_logo.png": "ccbc5c13c4b634fcb82adf209fca5a7c",
"index.html": "e73557d279c11ac5de7f611b9019e24a",
"/": "e73557d279c11ac5de7f611b9019e24a",
"main.dart.js": "51d831f1722ba68306b269383874d76d",
"manifest.json": "3f4d7ea2c67a99912036650bd9fa9dbf",
"version.json": "6e661e08190c8911a2364f33167c69de",
"_headers": "fa4b8ef7e01e1edff930f2506f72ab88",
"_redirects": "b6318954f4d7bbf4763f67d034b9b035"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
