import { LiveUpdate } from '@capawesome/capacitor-live-update';

const VERSION_URL = 'https://raw.githubusercontent.com/amiir2188-commits/MADAL/main/version.json';
const FALLBACK_BUNDLE_URL = 'https://github.com/amiir2188-commits/MADAL/releases/latest/download/madal-web.zip';
const isNative = Boolean(window.Capacitor?.isNativePlatform?.());
const notice = document.getElementById('updateNotice');
const button = document.getElementById('applyUpdate');

let latestBundle = null;

function showMessage(message) {
  if (notice) {
    notice.classList.remove('hidden');
    const textNode = notice.firstChild;
    if (textNode) textNode.textContent = message + ' ';
  }
}

async function checkNativeUpdate() {
  if (!isNative || !notice || !button) return;
  try {
    await LiveUpdate.ready();
    const response = await fetch(VERSION_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!response.ok) return;
    const latest = await response.json();
    const current = window.MADAL_VERSION || '0.0.0';
    if (!latest.version || latest.version === current) return;
    latestBundle = {
      version: String(latest.version),
      url: latest.bundle_url || FALLBACK_BUNDLE_URL
    };
    showMessage('MADAL nooc cusub (' + latestBundle.version + ') ayaa diyaar ah.');
    button.textContent = 'Soo dejiso cusboonaysiinta';
    button.classList.remove('hidden');
  } catch (error) {
    console.warn('MADAL live update check:', error);
  }
}

if (button) {
  button.addEventListener('click', async () => {
    if (!isNative || !latestBundle) {
      location.reload();
      return;
    }
    button.disabled = true;
    button.textContent = 'Waa la soo dejinayaa...';
    try {
      await LiveUpdate.downloadBundle({
        url: latestBundle.url,
        bundleId: latestBundle.version
      });
      await LiveUpdate.setNextBundle({ bundleId: latestBundle.version });
      button.textContent = 'Waa la cusboonaysiiyey — dib ayaa loo furayaa...';
      await LiveUpdate.reload();
    } catch (error) {
      console.error('MADAL update failed:', error);
      showMessage('Cusboonaysiintu way fashilantay. Isku day mar kale.');
      button.disabled = false;
      button.textContent = 'Mar kale isku day';
    }
  });
}

checkNativeUpdate();
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') checkNativeUpdate();
});
