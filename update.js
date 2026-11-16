let LiveUpdate = null;
const isNative = Boolean(window.Capacitor?.isNativePlatform?.());
if (isNative) {
  try {
    ({ LiveUpdate } = await import('@capawesome/capacitor-live-update'));
  } catch (error) {
    console.warn('MADAL live update plugin is unavailable:', error);
  }
}

const VERSION_URL = 'https://raw.githubusercontent.com/amiir2188-commits/MADAL/main/version.json';
const FALLBACK_BUNDLE_URL = 'https://github.com/amiir2188-commits/MADAL/releases/latest/download/madal-web.zip';
const notice = document.getElementById('updateNotice');
const button = document.getElementById('applyUpdate');
const message = document.getElementById('updateMessage');
let latestBundle = null;
let checking = false;

function showUpdate(version) {
  if (!notice || !button) return;
  notice.classList.remove('hidden');
  if (message) message.textContent = 'MADAL ' + version + ' waa diyaar. Taabo Update App si aad u hesho muuqaalada iyo hagaajinta cusub; APK kale looma baahna.';
  button.classList.remove('hidden');
  button.textContent = 'Update App';
}

async function checkNativeUpdate() {
  if (checking || !notice || !button) return;
  checking = true;
  try {
    if (isNative && LiveUpdate) await LiveUpdate.ready();
    const response = await fetch(VERSION_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!response.ok) return;
    const latest = await response.json();
    const current = window.MADAL_VERSION || '0.0.0';
    if (!latest.version || latest.version === current) return;
    latestBundle = {
      version: String(latest.version),
      url: latest.bundle_url || FALLBACK_BUNDLE_URL
    };
    showUpdate(latestBundle.version);
  } catch (error) {
    console.warn('MADAL live update check:', error);
  } finally {
    checking = false;
  }
}

if (button) {
  button.addEventListener('click', async () => {
    if (!latestBundle) {
      if (!isNative) {
        button.disabled = true;
        button.textContent = 'Waa la cusboonaysiinayaa...';
        location.reload();
      }
      return;
    }
    button.disabled = true;
    button.textContent = isNative ? 'Update waa la soo dejinayaa...' : 'Waa la cusboonaysiinayaa...';
    try {
      if (isNative && LiveUpdate) {
        await LiveUpdate.downloadBundle({
          url: latestBundle.url,
          bundleId: latestBundle.version
        });
        await LiveUpdate.setNextBundle({ bundleId: latestBundle.version });
        button.textContent = 'Waa la dhammeeyey — dib ayaa loo furayaa...';
        await LiveUpdate.reload();
      } else {
        // PWA/browser: the service worker fetches the newest web files.
        if ('serviceWorker' in navigator) {
          const registration = await navigator.serviceWorker.getRegistration();
          await registration?.update();
          await registration?.unregister();
        }
        location.reload();
      }
    } catch (error) {
      console.error('MADAL update failed:', error);
      if (message) message.textContent = 'Cusboonaysiintu way fashilantay. Internet-ka hubi oo mar kale isku day.';
      button.disabled = false;
      button.textContent = 'Mar kale isku day';
    }
  });
}

checkNativeUpdate();
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') checkNativeUpdate();
});
window.addEventListener('online', checkNativeUpdate);
setInterval(() => {
  if (document.visibilityState === 'visible') checkNativeUpdate();
}, 5 * 60 * 1000);
