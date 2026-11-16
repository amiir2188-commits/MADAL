GOGOL — APP BULSHO FIIDIYOW AH
Nooca hadda la xaqiijiyey: 1.10.30

GoGol (oo markii hore MADAL la oran jiray) waa app bulsho oo Soomaali-ku-horreeyo, laguna isticmaalo Android iyo web.

SOO DEJINTA
APK Android:
https://github.com/amiir2188-commits/MADAL/releases/download/v1.10.30/app-debug.apk

Sii-daynta iyo dhammaan faylasha:
https://github.com/amiir2188-commits/MADAL/releases/tag/v1.10.30

WAXYAABAHA NOOCA BETA-GA KU JIRA
- Daawashada iyo soo gelinta fiidiyowyada.
- Samaysashada akoon iyo gelitaanka email/password.
- Gelitaanka telefoonka +252 haddii Supabase Phone Auth iyo adeeg SMS la habeeyo.
- Like, faallo, raacis iyo quudinta For You/Following.
- Raadinta dadka, profiles iyo fariimo gaar ah.
- Wadaagis, repost iyo kaydinta waxyaabaha la jecleystay.
- Ogeysiisyo ku saabsan cusboonaysiinta web-content-ka.

Qaar ka mid ah adeegyada bulshada iyo badbaadadu waxay ku xiran yihiin in jadwallada, siyaasadaha RLS iyo migrations-ka Supabase ee ku habboon la rakibo. Stories iyo baahinta tooska ah (Live) weli ma aha adeegyo dhamaystiran. For You hadda wuxuu adeegsadaa kala-hormarin ku salaysan falgalka iyo cusaybka; ma aha nidaam AI la tababaray.

HABAYNTA SUPABASE
1. Hubi Project URL iyo publishable/anon key-ga app-ka. Ha gelin service-role ama secret key gudaha app-ka.
2. Haddii database cusub yahay, dib u eeg supabase_schema.sql ka hor inta aan lagu fulin Supabase SQL Editor.
3. Haddii database hore u jiro, marka hore hubi schema-giisa; kadib dib u eeg oo keliya migrations-ka ku habboon, kuna dabaq kala-horrayntooda. Faylasha dheeraadka ah waxay ku jiraan supabase/migrations/.
4. Si telefoonka +252 loogu galo, daar Phone Auth oo habeey adeeg SMS.

SQL migrations si otomaatig ah looma fuliyo marka app-ka la daabaco. Kahor production, kaydso database-ka oo dib u eeg SQL-ga. Report iyo block waxay u baahan yihiin migration-ka user safety/moderation iyo RLS policies-kiisa.

OGOW
- APK-gu waa beta/debug-signed build, mana aha Play Store release.
- Android package ID: com.madal.app; ha beddelin si updates-ku ugu shaqeeyaan rakibaaddii hore.
- Isbeddellada HTML/CSS/JavaScript waxaa si gooni ah loogu daabici karaa webka; isbeddellada Android native waxay u baahan yihiin APK cusub.
- iPhone wali ma laha native IPA build.
- Soo geli oo keliya muuqaal aad leedahay ama aad fasax u haysato.
