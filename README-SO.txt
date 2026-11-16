GOGOL — APP BULSHO FIIDIYOW AH
APK Android-ka ugu dambeeya ee la xaqiijiyey: 1.10.49; web bundle-ka: 1.10.50

GoGol (oo markii hore MADAL la oran jiray) waa app bulsho oo Soomaali-ku-horreeyo, laguna isticmaalo Android iyo web.

SOO DEJINTA
APK Android:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.49/app-debug.apk

Sii-daynta iyo dhammaan faylasha:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.50/madal-web.zip

WAXYAABAHA NOOCA BETA-GA KU JIRA
- Daawashada iyo soo gelinta sawirro iyo fiidiyowyo; album sawirro badan (ilaa 10 sawir).
- Samaysashada akoon iyo gelitaanka email/password.
- Gelitaanka telefoonka +252 haddii Supabase Phone Auth iyo adeeg SMS la habeeyo.
- Like, faallo, raacis iyo quudinta For You/Following.
- Raadinta dadka, profiles iyo fariimo gaar ah.
- Wadaagis, repost iyo kaydinta waxyaabaha la jecleystay.
- Ogeysiisyo ku saabsan cusboonaysiinta web-content-ka.
- Bogagga asturnaanta, xeerarka bulshada iyo shuruudaha isticmaalka.
- Aqbalid cad oo shuruudaha iyo siyaasadda asturnaanta ah marka akoon cusub la samaynayo.
- Tirtiridda akoonka oo ammaan ah (waxay u baahan tahay migration-ka Supabase iyo Edge Function la daabacay).

Qaar ka mid ah adeegyada bulshada iyo badbaadadu waxay ku xiran yihiin in jadwallada, siyaasadaha RLS iyo migrations-ka Supabase ee ku habboon la rakibo. Stories iyo baahinta tooska ah (Live) weli ma aha adeegyo dhamaystiran. For You hadda wuxuu adeegsadaa kala-hormarin ku salaysan falgalka iyo cusaybka; ma aha nidaam AI la tababaray.

HABAYNTA SUPABASE
1. Hubi Project URL iyo publishable/anon key-ga app-ka. Ha gelin service-role ama secret key gudaha app-ka.
2. Haddii database cusub yahay, dib u eeg supabase_schema.sql ka hor inta aan lagu fulin Supabase SQL Editor.
3. Haddii database hore u jiro, marka hore hubi schema-giisa; kadib dib u eeg oo keliya migrations-ka ku habboon, kuna dabaq kala-horrayntooda.
4. Daabac Edge Function-ka tirtirka akoonka adigoo adeegsanaya `supabase functions deploy delete-account`. Service-role key-ga ha gelin app-ka; wuxuu ku ekaanayaa deegaanka Edge Function-ka. Faylasha dheeraadka ah waxay ku jiraan supabase/migrations/. Migration-ka social post visibility wuxuu hubiyaa in likes/faallooyinka aanay ka muuqan posts qarsoon. Migration-ka account deletion requests wuxuu kaydiyaa codsiyada tirtirka akoonka si maamulka gacanta uga baaraandego.
4. Si telefoonka +252 loogu galo, daar Phone Auth oo habeey adeeg SMS.

SQL migrations si otomaatig ah looma fuliyo marka app-ka la daabaco. Kahor production, kaydso database-ka oo dib u eeg SQL-ga. Report iyo block waxay u baahan yihiin migration-ka user safety/moderation iyo RLS policies-kiisa.

OGOW
- APK-gu waa beta/debug-signed build, mana aha Play Store release.
- Android package ID: com.madal.app; ha beddelin si updates-ku ugu shaqeeyaan rakibaaddii hore.
- Isbeddellada HTML/CSS/JavaScript waxaa si gooni ah loogu daabici karaa webka; isbeddellada Android native waxay u baahan yihiin APK cusub.
- iPhone wali ma laha native IPA build.
- Soo geli oo keliya muuqaal aad leedahay ama aad fasax u haysato.
