const CACHE_NAME = 'gogol-app-v1.10.86';
const APP_FILES = ['./','./index.html','./account.html','./privacy.html','./community-guidelines.html','./terms.html','./manifest.webmanifest','./version.json','./gogol-logo.svg','./icons/icon-192.svg','./icons/icon-512.svg','./live.js','./update.js'];
self.addEventListener('install',event=>{
 event.waitUntil(caches.open(CACHE_NAME).then(cache=>cache.addAll(APP_FILES)).catch(error=>console.warn('MADAL cache install:',error)));
 self.skipWaiting();
});
self.addEventListener('activate',event=>{
 event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>(key.startsWith('madal-shell-')||key.startsWith('madal-app-')||key.startsWith('gogol-app-'))&&key!==CACHE_NAME).map(key=>caches.delete(key)))));
 self.clients.claim();
});
self.addEventListener('fetch',event=>{
 if(event.request.method!=='GET')return;
 const url=new URL(event.request.url);
 if(url.origin!==self.location.origin)return;
 if(url.pathname.endsWith('/version.json')){event.respondWith(fetch(event.request,{cache:'no-store'}).catch(()=>caches.match(event.request)));return}
 if(event.request.mode==='navigate'||url.pathname.endsWith('.html')||url.pathname.endsWith('.webmanifest')){
  event.respondWith(fetch(event.request).then(response=>{
   if(response.ok){const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put(event.request,copy))}
   return response;
  }).catch(()=>caches.match(event.request).then(cached=>cached||caches.match('./index.html'))));
  return;
 }
 event.respondWith(caches.match(event.request).then(cached=>cached||fetch(event.request).then(response=>{
  if(response.ok){const copy=response.clone();caches.open(CACHE_NAME).then(cache=>cache.put(event.request,copy))}
  return response;
 }).catch(()=>caches.match(event.request).then(cached=>cached||Response.error()))));
});
