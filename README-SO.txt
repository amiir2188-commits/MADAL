GOGOL — APP BULSHO FIIDIYOW IYO SAWIRRO AH

APK-ga Android ee saldhigga ah: 1.10.59 (debug-signed build la xaqiijiyey)
Web bundle-ka cusub: 1.10.64 (astaanta GoGol, navigation muraayad-casri ah iyo astaamo SVG ah oo si fudud loo taaban karo) (bogagga Terms/Privacy/Community waa lagu daray)
GoGol (oo markii hore MADAL la oran jiray) waa app bulsho oo Soomaali-ku-horreeyo.

SOO DEJINTA
APK Android:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.59/app-debug.apk

Web update bundle:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.63/madal-web.zip

Dhammaan sii-daymaha:
https://github.com/amiir2188-commits/MADAL/releases

WAXYAABAHA APP-KA KU JIRA
- Soo geli oo daawo sawirro iyo fiidiyowyo; album-ku wuxuu qaadi karaa ilaa 10 sawir.
- Samee akoon, ku gal email/password; +252 wuxuu shaqaynayaa marka Phone Auth iyo adeeg SMS la habeeyo.
- Like, faallo, Follow, For You iyo Following feeds.
- Raadi dadka, eeg profiles, dir fariimo gaar ah.
- Share, Repost iyo Save/Favorites.
- Stories sawir/fiidiyow ah oo dhacaya 24 saac kadib.
- GoGol LIVE beta: baahin camera/microphone, daawadayaal iyo LIVE chat.
- Dejinta asturnaanta, block/report, bogagga shuruudaha iyo siyaasadda asturnaanta.
- Codsi tirtirid akoon oo ammaan ah.

CUSBOONAYSIINTA APP-KA
APK-ga 1.10.59 waa saldhigga Android ee hadda lagu tijaabinayo in-app updates. Web bundle-ka 1.10.62 wuxuu ku darayaa Terms, Privacy, Community pages, astaanta GoGol, hagaajinta cache-ka updater-ka iyo SDK-yada LIVE oo versions-kooda la pin-gareeyey. Marka APK-ga saldhigga ah la rakibo, isbeddellada HTML/CSS/JavaScript waxaa app-ka gudihiisa looga soo dejisan karaa iyada oo aan APK cusub la rakibin. APK cusub waxaa la daabacaa oo keliya marka workflow-ga gacanta lagu bilaabo oo `publish_apk=true` la doorto. Stable release-signing keystore wali lama dejin; sidaas darteed APK-ga 1.10.59 ha ahaado saldhigga inta aan saxiix joogto ah la diyaarin. Isbeddelada Android native ama plugins cusub waxay u baahan yihiin APK cusub oo saxiix joogto ah leh. In-app update-ka waa in telefoon dhab ah lagu tijaabiyaa ka hor ballanqaad buuxa.

HABAYNTA SUPABASE
- Project ID: nxtnfdyksskofjbvface.
- Ha gelin service-role key, database password ama secrets gudaha app-ka, GitHub code, ama chat.
- Migrations-ka ku jira supabase/migrations waa in marka hore la eego, backup la xaqiijiyo, kadibna si sax ah loo dabaqo.
- Workflow-ga backend-ka wuxuu leeyahay `preflight_only=true` oo hubiya secrets-ka isla markaana sameeya dry-run aan waxba ka beddelin production. Marka backup dib loo soo celin karo la xaqiijiyo oo keliya ayaa `preflight_only=false`, `confirm_production_deploy=true`, `backup_completed=true` la doortaa.
- Migration 20261117000100 wuxuu hagaajiyaa samaynta profile-ka marka username hore loo qaatay.
- Migration 20261117000200 wuxuu diyaariyaa user_follows, media_reposts, media_favorites, is_private iyo is_verified; wuxuu kaloo adkeeyaa RLS/private-post visibility.
- Jadwalladii hore madal_follows iyo madal_shares lama tirtirayo, balse xogtooda si otomaatig ah looguma guurin jadwallada cusub.
- Stories waxay u baahan yihiin migrations 008 iyo cleanup Edge Function + Cron.
- LIVE waxay u baahan tahay migrations 009 iyo 010, LiveKit Cloud/server iyo secrets: LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET.
- Workflow-ga GitHub Actions → Deploy GoGol Supabase backend wuxuu u baahan yahay SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD iyo GOGOL_CRON_SECRET. LiveKit secrets waa ikhtiyaari; haddii aan la dejin, qaybaha kale ee backend-ka waa la deploy-gareyn karaa, LIVE-na wuxuu sugayaa credentials.
- Ka hor production deploy, samee backup database oo dib loo soo celin karo. CSV-yada public tables keligood kuma jiraan Auth users, Storage files, policies iyo schema oo dhan. Faylasha Storage-ka iyo xogta muhiimka ah meel ammaan ah ku hay.
- Cleanup Cron-ka Stories waa in Supabase Dashboard laga jadwaleeyo 15 daqiiqo kasta, kadib deployment.

XADIDAADAHA IYO TAYADA
- App-ku weli waa beta; CI build guulaystay macnaheedu ma aha in adeeg kasta telefoon dhab ah lagu tijaabiyey.
- LIVE, messaging, uploads, privacy, OTA iyo laba qalab waa in end-to-end lagu tijaabiyaa.
- For You wuxuu adeegsadaa engagement/freshness ranking; ma aha AI model la tababaray.
- APK-gu waa debug-signed direct-distribution build, mana aha Play Store release.
- Android package ID: com.madal.app; ha beddelin.
- iPhone native IPA wali lama diyaarin.
- Soo geli oo keliya waxyaabo aad leedahay ama aad fasax u haysato.


SAxiixa JOOGTADA AH EE APK-GA (SI AAN MUSTAQBALKA LOO UNINSTALL-GAREYN)
GitHub repo → Settings → Secrets and variables → Actions → New repository secret.
Ku dar afartan secret:
1. ANDROID_KEYSTORE_BASE64 — base64-ka faylka gogol-release.jks.
2. ANDROID_KEYSTORE_PASSWORD — password-ka keystore-ka.
3. ANDROID_KEY_ALIAS — alias-ka key-ga (tusaale: gogol).
4. ANDROID_KEY_PASSWORD — password-ka key-ga.

Keystore-ka ku samee kombiyuutar aad adigu maamusho adigoo adeegsanaya keytool:
keytool -genkeypair -v -keystore gogol-release.jks -alias gogol -keyalg RSA -keysize 2048 -validity 10000
Linux/macOS base64:
base64 -w 0 gogol-release.jks > gogol-release-base64.txt
Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("gogol-release.jks"))
Ha gelin gogol-release.jks ama password-yada GitHub repository-ga, hana ku wadaagin chat. Hayso laba nuqul oo ammaan ah oo keystore-ka ah; haddii lumo, APK-yada dambe laguma cusboonaysiin karo isla package-ka. Kadib secrets-ka geli, GitHub Actions → Build GoGol Android APK ku bilow publish_apk=true. Haddii aad hore u rakibtay APK-ga debug-signed ee 1.10.59, saxiix cusub awgiis uninstall ayaa loo baahan karaa ka hor rakibidda APK-ga release-ka cusub.
