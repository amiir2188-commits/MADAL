GOGOL — APP BULSHO FIIDIYOW IYO SAWIRRO AH

APK-ga Android ee saldhigga ah: 1.10.59 (debug-signed build la xaqiijiyey)
Web bundle-ka cusub: 1.10.60 (bogagga Terms/Privacy/Community waa lagu daray)
GoGol (oo markii hore MADAL la oran jiray) waa app bulsho oo Soomaali-ku-horreeyo.

SOO DEJINTA
APK Android:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.59/app-debug.apk

Web update bundle:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.60/madal-web.zip

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
APK-ga 1.10.59 waa saldhigga Android ee hadda lagu tijaabinayo in-app updates. Web bundle-ka 1.10.60 wuxuu ku darayaa Terms, Privacy iyo Community pages. APK cusub si otomaatig ah looma beddelayo si aan loo khalkhal gelin saxiixa APK-ga saldhigga ah. Marka APK-gan la rakibo, isbeddellada HTML/CSS/JavaScript waxaa app-ka gudihiisa looga soo dejisan karaa iyada oo aan APK cusub la rakibin. Isbeddelada Android native ama plugins cusub weli waxay u baahan yihiin APK cusub. In-app update-ka waa in telefoon dhab ah lagu tijaabiyaa ka hor inta aan loo ballanqaadin inuu dhammaan qalabka si buuxda uga shaqaynayo.

HABAYNTA SUPABASE
- Project ID: nxtnfdyksskofjbvface.
- Ha gelin service-role key, database password ama secrets gudaha app-ka, GitHub code, ama chat.
- Migrations-ka ku jira supabase/migrations waa in marka hore la eego, backup la xaqiijiyo, kadibna si sax ah loo dabaqo.
- Migration 20261117000100 wuxuu hagaajiyaa samaynta profile-ka marka username hore loo qaatay.
- Migration 20261117000200 wuxuu diyaariyaa user_follows, media_reposts, media_favorites, is_private iyo is_verified; wuxuu kaloo adkeeyaa RLS/private-post visibility.
- Jadwalladii hore madal_follows iyo madal_shares lama tirtirayo, balse xogtooda si otomaatig ah looguma guurin jadwallada cusub.
- Stories waxay u baahan yihiin migrations 008 iyo cleanup Edge Function + Cron.
- LIVE waxay u baahan tahay migrations 009 iyo 010, LiveKit Cloud/server iyo secrets: LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET.
- Workflow-ga GitHub Actions → Deploy GoGol Supabase backend wuxuu u baahan yahay SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD, GOGOL_CRON_SECRET iyo saddexda LiveKit secrets. Waxa kale oo uu u baahan yahay backup dib loo soo celin karo iyo oggolaanshaha production environment.
- Cleanup Cron-ka Stories waa in Supabase Dashboard laga jadwaleeyo 15 daqiiqo kasta, kadib deployment.

XADIDAADAHA IYO TAYADA
- App-ku weli waa beta; CI build guulaystay macnaheedu ma aha in adeeg kasta telefoon dhab ah lagu tijaabiyey.
- LIVE, messaging, uploads, privacy, OTA iyo laba qalab waa in end-to-end lagu tijaabiyaa.
- For You wuxuu adeegsadaa engagement/freshness ranking; ma aha AI model la tababaray.
- APK-gu waa debug-signed direct-distribution build, mana aha Play Store release.
- Android package ID: com.madal.app; ha beddelin.
- iPhone native IPA wali lama diyaarin.
- Soo geli oo keliya waxyaabo aad leedahay ama aad fasax u haysato.
