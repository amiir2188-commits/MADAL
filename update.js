let LiveUpdate = null;
const isNative = Boolean(window.Capacitor?.isNativePlatform?.());
if (isNative) {
  try {
    ({ LiveUpdate } = await import('@capawesome/capacitor-live-update'));
  } catch (error) {
    console.warn('DUNIQ live update plugin is unavailable:', error);
  }
}

const VERSION_URL = 'https://raw.githubusercontent.com/amiir2188-commits/DUNIQ/main/version.json';
const FALLBACK_BUNDLE_URL = 'https://github.com/amiir2188-commits/DUNIQ/releases/latest/download/madal-web.zip';
const notice = document.getElementById('updateNotice');
const button = document.getElementById('applyUpdate');
const message = document.getElementById('updateMessage');
let latestBundle = null;
let checking = false;
let updating = false;

const updateStyle = document.createElement('style');
updateStyle.textContent = `
.update-start.is-loading{display:inline-flex;align-items:center;justify-content:center;gap:11px;cursor:wait;transform:none!important}
.update-start.is-loading::before{content:"";width:19px;height:19px;flex:none;border:3px solid #180d2544;border-top-color:#180d25;border-radius:50%;animation:gogol-update-spin .8s linear infinite}
.update-progress{min-height:24px;margin:15px auto 0;color:#f0e5fa;font-size:13px;line-height:1.5;text-align:center}
.update-progress:empty{display:none}
@keyframes gogol-update-spin{to{transform:rotate(360deg)}}
@media(prefers-reduced-motion:reduce){.update-start.is-loading::before{animation-duration:2s}}
`;
document.head.appendChild(updateStyle);

let progress = document.getElementById('updateProgress');
if (!progress && button) {
  progress = document.createElement('p');
  progress.id = 'updateProgress';
  progress.className = 'update-progress';
  progress.setAttribute('role', 'status');
  progress.setAttribute('aria-live', 'polite');
  progress.setAttribute('aria-atomic', 'true');
  button.insertAdjacentElement('afterend', progress);
}

function setProgress(text) {
  if (progress) progress.textContent = text;
}
function setButtonLoading(text) {
  if (!button) return;
  button.disabled = true;
  button.classList.add('is-loading');
  button.setAttribute('aria-busy', 'true');
  button.textContent = text;
}
function clearButtonLoading(text) {
  if (!button) return;
  button.disabled = false;
  button.classList.remove('is-loading');
  button.removeAttribute('aria-busy');
  button.textContent = text;
}

function showUpdate(version) {
  if (!notice || !button) return;
  notice.classList.remove('hidden');
  if (message) message.textContent = 'DUNIQ ' + version + ' waa diyaar. Taabo Update App si aad u cusboonaysiiso ka hor intaadan gelin app-ka caadiga ah. APK kale looma baahna.';
  button.classList.remove('hidden');
  clearButtonLoading('Update App');
  setProgress('');
}

async function checkNativeUpdate() {
  if (checking || updating || !notice || !button) return;
  checking = true;
  try {
    if (isNative && LiveUpdate) await LiveUpdate.ready();
    const response = await fetch(VERSION_URL + '?t=' + Date.now(), { cache: 'no-store' });
    if (!response.ok) return;
    const latest = await response.json();
    const current = window.DUNIQ_VERSION || '0.0.0';
    if (!latest.version || latest.version === current) return;
    if (isNative && !latest.bundle_url) return;
    latestBundle = {
      version: String(latest.version),
      url: latest.bundle_url || FALLBACK_BUNDLE_URL
    };
    showUpdate(latestBundle.version);
  } catch (error) {
    console.warn('DUNIQ live update check:', error);
  } finally {
    checking = false;
  }
}

if (button) {
  button.addEventListener('click', async () => {
    if (updating) return;
    if (!latestBundle) {
      if (!isNative) {
        updating = true;
        setButtonLoading('Waa la cusboonaysiinayaa...');
        setProgress('Fadlan sug inta DUNIQ dib isu furayo.');
        location.reload();
      }
      return;
    }
    updating = true;
    setButtonLoading('Update waa la soo dejinayaa...');
    setProgress('DUNIQ wuxuu soo dejinayaa cusboonaysiinta. Fadlan ha xirin app-ka, hana taaban badhanka mar kale.');
    try {
      if (isNative && LiveUpdate) {
        await LiveUpdate.downloadBundle({
          url: latestBundle.url,
          bundleId: latestBundle.version
        });
        setButtonLoading('Waa la rakibayaa...');
        setProgress('Soo dejintu way dhammaatay. DUNIQ wuxuu diyaarinayaa cusboonaysiinta...');
        await LiveUpdate.setNextBundle({ bundleId: latestBundle.version });
        setButtonLoading('Waa la dhammeeyey...');
        setProgress('DUNIQ dib ayuu u furmayaa. Hal daqiiqo sug...');
        await LiveUpdate.reload();
      } else if (isNative) {
        throw new Error('Adeegga cusboonaysiinta Android lama heli karo. Hubi in app-ka asalka ah la rakibay.');
      } else {
        setProgress('Waxaa la cusboonaysiinayaa faylasha app-ka...');
        if ('serviceWorker' in navigator) {
          const registration = await navigator.serviceWorker.getRegistration();
          await registration?.update();
          await registration?.unregister();
        }
        location.reload();
      }
    } catch (error) {
      console.error('DUNIQ update failed:', error);
      updating = false;
      const detail = error?.message ? String(error.message).slice(0, 180) : 'Sabab aan la aqoon';
      if (message) message.textContent = 'Cusboonaysiintu way fashilantay: ' + detail + '. Hubi internet-ka, kadib mar kale isku day.';
      setProgress('Cusboonaysiinta lama dhammaystirin. Mar kale isku day marka internet-ku hagaago.');
      clearButtonLoading('Mar kale isku day');
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
