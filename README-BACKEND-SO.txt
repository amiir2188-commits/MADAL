GOGOL — HAGAAHA BACKEND-KA SUPABASE

GoGol wuxuu adeegsadaa Supabase Authentication iyo database-ka si uu u maareeyo akoonnada iyo xogta app-ka.

1. Fur mashruuca Supabase ee GoGol.
2. Hubi Project URL iyo publishable/anon key-ga. Client-ka app-ka waxaa loo isticmaali karaa publishable/anon key oo keliya; WALIGAA ha gelin service_role ama secret key gudaha HTML/JavaScript ama APK.
3. Haddii aad samaynayso database cusub, dib u eeg supabase_schema.sql oo hubi waxa uu abuurayo ka hor fulinta.
4. Haddii aad isticmaalayso database hore u jiray, ha ku celin schema buuxa si indho la'aan ah. Isbarbar dhig jadwallada iyo policies-ka jira, kadib dib u eeg migrations-ka ku jira supabase/migrations/ oo dabaq kuwa loo baahan yahay, sida:
   - social v2
   - message read receipts
   - media/message compatibility
   - user safety and moderation
5. Daar Phone Auth iyo SMS provider haddii aad rabto diiwaangelin/gelitaan telefoon +252.
6. Tijaabi akoon cusub, login, gelitaanka xogta, upload iyo RLS adigoo adeegsanaya akoonno tijaabo ah.

ADEEGYADA APP-KA EE HADDAN
- Akoon iyo login email/password; telefoon +252 haddii SMS provider la habeeyo.
- Soo gelin iyo daawasho fiidiyow.
- Likes, comments, follows iyo feed tabs.
- Raadinta profiles iyo fariimo gaar ah.
- Wadaagis, repost iyo favorites.
- For You ranking ku salaysan engagement iyo freshness.

BADBAADO IYO XADIDAADO
- Report/block waxay u baahan yihiin migration-ka user safety/moderation iyo RLS policies-kiisa in lagu rakibo database-ka. In faylka SQL uu repo-ga ku jiro macnaheedu ma aha in production database-ka lagu dabaqay.
- Stories iyo Live streaming weli ma aha adeegyo dhamaystiran.
- Ma jiro admin moderation dashboard oo la xaqiijiyey inuu diyaar yahay.
- APK-ga la qaybiyo waa beta/debug-signed, mana aha Play Store build.
- Kaydinta iyo bandwidth-ka fiidiyowyada waxay ku xiran yihiin qorshaha iyo dejinta Supabase/storage.
- Hubi in qofka soo gelinaya uu xaq u leeyahay media-ga.

DIGNIIN: SQL migrations-ka production-ka ha lagu dabaqin ilaa la hubiyo schema-ga hadda jira, la sameeyo backup, lana fahmo saameyntooda. Daabacaadda webka ama APK-gu iskood uma beddelaan database-ka.
