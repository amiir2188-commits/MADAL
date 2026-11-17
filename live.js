const LIVE_SUPABASE_URL = "https://nxtnfdyksskofjbvface.supabase.co";
const LIVE_SUPABASE_KEY = "sb_publishable_IGs6B3ozDGNZtAQaL4uZaQ_jXlMqOeJ";
const liveDb = window.gogolSupabase || window.supabase.createClient(LIVE_SUPABASE_URL, LIVE_SUPABASE_KEY);
let liveRoom = null;
let liveLocalTracks = [];
let liveSessionId = null;
let liveRole = null;
let liveHostUserId = null;
let liveKitModule = null;
let liveHeartbeat = null;
let liveLastChatAt = 0;

const liveStyle = document.createElement("style");
liveStyle.textContent = `
#gogolLiveDialog{position:fixed;inset:0;z-index:5000;background:#090512;color:#fff;display:none;flex-direction:column;padding:calc(12px + env(safe-area-inset-top)) 14px calc(14px + env(safe-area-inset-bottom));overflow:auto}
#gogolLiveDialog.open{display:flex}
.g-live-head{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:8px 0 16px}
.g-live-head strong{font-size:22px;letter-spacing:1px}
.g-live-head button,.g-live-btn{border:1px solid #49335c;border-radius:12px;padding:11px 14px;background:#241832;color:#fff;font-weight:800}
.g-live-primary{background:linear-gradient(110deg,#8b45d2,#df4d9b);border:0;color:#fff}
.g-live-field{width:100%;padding:13px;border:1px solid #49335c;border-radius:12px;background:#171020;color:#fff;margin:8px 0 14px;font:inherit}
.g-live-stage{position:relative;width:100%;aspect-ratio:9/16;max-height:58dvh;min-height:240px;border-radius:18px;overflow:hidden;background:#050308;display:grid;place-items:center}
.g-live-stage video{width:100%;height:100%;object-fit:contain;background:#050308}
.g-live-status{padding:10px 12px;margin:10px 0;border-radius:12px;background:#21152f;color:#e8d9ff}
.g-live-list{display:grid;gap:10px;margin:12px 0}
.g-live-item{display:flex;align-items:center;gap:12px;padding:13px;border:1px solid #38254a;border-radius:14px;background:#171020}
.g-live-dot{width:11px;height:11px;flex:none;border-radius:50%;background:#ff3158;box-shadow:0 0 12px #ff3158}
.g-live-item>div{flex:1;min-width:0}.g-live-item small{display:block;color:#b9acc7;margin-top:4px}
.g-live-actions{display:flex;gap:8px;flex-wrap:wrap;margin:12px 0}.g-live-actions button{flex:1;min-width:100px}
.g-live-stats{font-size:12px;color:#d9baff;margin:8px 0;font-weight:800}
.g-live-chat{height:170px;overflow:auto;border:1px solid #38254a;border-radius:12px;background:#120b1c;padding:9px;margin-top:10px}
.g-live-chat-line{font-size:13px;padding:4px 0;overflow-wrap:anywhere}.g-live-chat-line strong{color:#d9baff;margin-right:6px}
.g-live-chat-form{display:flex;gap:7px;margin-top:8px}.g-live-chat-form input{flex:1;min-width:0;margin:0}.g-live-chat-form button{flex:none}
`;
document.head.append(liveStyle);

const liveDialog = document.createElement("section");
liveDialog.id = "gogolLiveDialog";
liveDialog.setAttribute("role","dialog");
liveDialog.setAttribute("aria-modal","true");
liveDialog.setAttribute("aria-label","GoGol LIVE");
liveDialog.innerHTML = `
 <div class="g-live-head"><strong>🔴 GoGol LIVE</strong><button type="button" id="gLiveClose">Xir ✕</button></div>
 <div id="gLiveHome">
  <p class="muted">Daawo baahinta tooska ah ama bilow LIVE cusub.</p>
  <label for="gLiveTitle">Cinwaanka baahinta</label>
  <input id="gLiveTitle" class="g-live-field" maxlength="100" placeholder="Maxaad hadda la wadaagaysaa?">
  <button type="button" id="gLiveStart" class="g-live-btn g-live-primary" style="width:100%">▶ Bilow LIVE</button>
  <h3 style="margin:22px 0 8px">LIVE-yada socda</h3>
  <div id="gLiveList" class="g-live-list"><p class="muted">Waa la raadinayaa...</p></div>
  <p class="muted" style="font-size:12px">LIVE wuxuu u baahan yahay internet deggan, oggolaanshaha camera/microphone iyo dejinta LiveKit ee server-ka.</p>
 </div>
 <div id="gLiveRoomView" class="hidden">
  <div class="g-live-stage" id="gLiveStage"><p class="muted">Ku xirmaya...</p></div>
  <p id="gLiveRoomStatus" class="g-live-status" role="status">Diyaar garow...</p>
  <div id="gLiveViewers" class="g-live-stats">Daawadayaal: 0</div>
  <div id="gLiveChat" class="g-live-chat" aria-live="polite" aria-label="Wadahadalka LIVE"><p class="muted">Ku soo dhawoow wada sheekaysiga LIVE.</p></div>
  <form id="gLiveChatForm" class="g-live-chat-form"><input id="gLiveChatInput" maxlength="300" aria-label="Fariin LIVE" placeholder="Qor fariin..." autocomplete="off"><button type="submit" class="g-live-btn g-live-primary">Dir</button></form>
  <div class="g-live-actions">
   <button type="button" id="gLiveMic" class="g-live-btn">🎙️ Codka</button>
   <button type="button" id="gLiveCamera" class="g-live-btn">📷 Camera</button>
   <button type="button" id="gLiveEnd" class="g-live-btn g-live-primary">Jooji LIVE</button>
  </div>
 </div>
`;
document.body.append(liveDialog);

const liveEl = id => document.getElementById(id);
const liveStatus = message => { liveEl("gLiveRoomStatus").textContent = message; };
const liveUser = async () => {
 const {data,error}=await liveDb.auth.getUser();
 if(error || !data.user) throw new Error("Fadlan marka hore gal akoonkaaga GoGol.");
 return data.user;
};
const liveSDK = async () => {
 if(!liveKitModule) liveKitModule=await import("https://cdn.jsdelivr.net/npm/livekit-client@2.24.1/+esm");
 return liveKitModule;
};
const liveOpen = async () => {
 liveDialog.classList.add("open");
 liveEl("gLiveMic").classList.remove("hidden");liveEl("gLiveCamera").classList.remove("hidden");
 liveEl("gLiveHome").classList.remove("hidden");
 liveEl("gLiveRoomView").classList.add("hidden");
 await liveLoadSessions();
};
const liveClose = async () => {
 if(liveRoom) await liveLeave(liveRole==="host");
 liveDialog.classList.remove("open");
};
async function liveLoadSessions(){
 const list=liveEl("gLiveList");
 list.textContent="Waa la raadinayaa...";
 const {data,error}=await liveDb.from("madal_live_sessions")
  .select("id,host_id,title,started_at,last_heartbeat_at")
  .eq("status","live").gt("last_heartbeat_at",new Date(Date.now()-180000).toISOString()).order("started_at",{ascending:false}).limit(30);
 if(error){list.textContent="LIVE-yada lama soo rari karin. Hubi in migration 009 la rakibay.";return}
 list.replaceChildren();
 if(!data?.length){list.textContent="Hadda LIVE socda ma jiro. Adiga ayaa noqon kara qofka ugu horreeya!";return}
 const me=await liveDb.auth.getUser();
 for(const item of data){
  if(item.host_id===me.data?.user?.id) continue;
  const row=document.createElement("div");row.className="g-live-item";
  const dot=document.createElement("span");dot.className="g-live-dot";
  const info=document.createElement("div");
  const title=document.createElement("strong");title.textContent=item.title;
  const sub=document.createElement("small");sub.textContent="LIVE • "+new Date(item.started_at).toLocaleString();
  info.append(title,sub);
  const join=document.createElement("button");join.className="g-live-btn g-live-primary";join.textContent="Daawo";
  join.addEventListener("click",()=>liveJoin(item));
  row.append(dot,info,join);list.append(row);
 }
 if(!list.children.length) list.textContent="LIVE kale hadda ma jiro.";
}
async function liveGetToken(sessionId,role){
 const {data,error}=await liveDb.functions.invoke("live-token",{body:{session_id:sessionId,role}});
 if(error) throw new Error(error.message||"Live token lama helin.");
 if(data?.error) throw new Error(data.error);
 if(!data?.token||!data?.server_url) throw new Error("Server-ku ma soo celin LiveKit token.");
 return data;
}
async function liveShowRoom(session,title,role){
 liveSessionId=session.id;liveRole=role;liveHostUserId=String(session.host_id||'');
 liveEl("gLiveHome").classList.add("hidden");
 liveEl("gLiveRoomView").classList.remove("hidden");
 liveEl("gLiveStage").replaceChildren();
 liveStatus(role==="host"?"Camera iyo microphone waa la diyaarinayaa...":"Waxaad ku xirmaysaa baahinta...");
 const credentials=await liveGetToken(session.id,role);
 const {Room,RoomEvent,Track}=await liveSDK();
 liveRoom=new Room({adaptiveStream:true,dynacast:true});
 liveRoom.on(RoomEvent.TrackSubscribed,(track)=>{const node=track.attach();node.autoplay=true;node.playsInline=true;liveEl("gLiveStage").append(node)});
 liveRoom.on(RoomEvent.TrackUnsubscribed,(track)=>track.detach().forEach(node=>node.remove()));
 liveRoom.on(RoomEvent.Disconnected,()=>{if(liveRole)liveStatus("Xiriirkii LIVE wuu go'ay.")});
 liveRoom.on(RoomEvent.DataReceived,(payload,participant)=>{
  try{
   const packet=JSON.parse(new TextDecoder().decode(payload));
   if(packet?.type==="chat"&&typeof packet.text==="string"&&packet.text.trim().length>0&&packet.text.length<=300)
    liveAddChat(participant?.name||participant?.identity?.slice(0,8)||"Qof",packet.text.trim());
  }catch(error){console.warn("GoGol LIVE chat packet:",error)}
 });
 liveRoom.on(RoomEvent.ParticipantConnected,liveUpdateViewerCount);
 liveRoom.on(RoomEvent.ParticipantDisconnected,liveUpdateViewerCount);
 await liveRoom.connect(credentials.server_url,credentials.token);
 liveEl("gLiveChat").replaceChildren();
 liveUpdateViewerCount();
 if(role==="host"){
  liveLocalTracks=await LiveKitCreateTracks();
  for(const track of liveLocalTracks) {
   await liveRoom.localParticipant.publishTrack(track);
   if(track.kind==="video"){const preview=track.attach();preview.autoplay=true;preview.playsInline=true;liveEl("gLiveStage").append(preview)}
  }
  liveStatus("🔴 Waxaad si toos ah u baahinaysaa: "+title);
  liveEl("gLiveMic").classList.remove("hidden");liveEl("gLiveCamera").classList.remove("hidden");
  liveHeartbeat=setInterval(()=>{liveDb.from("madal_live_sessions").update({last_heartbeat_at:new Date().toISOString()}).eq("id",session.id).then(({error})=>{if(error)console.warn("GoGol LIVE heartbeat:",error.message)})},20000);
 }else{
  liveStatus("🔴 LIVE: "+title+" • Waad daawanaysaa");
  liveEl("gLiveMic").classList.add("hidden");liveEl("gLiveCamera").classList.add("hidden");
  for(const participant of liveRoom.remoteParticipants.values()){
   for(const publication of participant.trackPublications.values()){
    if(publication.track){const node=publication.track.attach();node.autoplay=true;node.playsInline=true;liveEl("gLiveStage").append(node)}
   }
  }
 }
}
function liveAddChat(name,message){
 const list=liveEl("gLiveChat");
 const line=document.createElement("div");line.className="g-live-chat-line";
 const author=document.createElement("strong");author.textContent=name+": ";
 const body=document.createElement("span");body.textContent=message;
 line.append(author,body);list.append(line);
 while(list.children.length>50)list.firstElementChild.remove();
 list.scrollTop=list.scrollHeight;
}
function liveUpdateViewerCount(){
 if(!liveRoom)return;
 // The host is a remote participant for viewers, but is not a viewer.
 // Count only remote participants whose identity is not the host identity.
 const remote=[...liveRoom.remoteParticipants.values()];
 const viewers=remote.filter(participant=>!liveHostUserId||!String(participant.identity||'').startsWith(liveHostUserId+'-')).length;
 liveEl("gLiveViewers").textContent="Daawadayaal: "+viewers;
}
async function liveSendChat(event){
 event.preventDefault();
 const field=liveEl("gLiveChatInput"),message=field.value.trim();
 if(!message||!liveRoom)return;
 if(Date.now()-liveLastChatAt<800)return;
 liveLastChatAt=Date.now();
 try{
  const packet={type:"chat",text:message.slice(0,300)};
  await liveRoom.localParticipant.publishData(new TextEncoder().encode(JSON.stringify(packet)),{reliable:true,topic:"gogol-live-chat"});
  liveAddChat(liveRoom.localParticipant.name||"Aniga",packet.text);
  field.value="";
 }catch(error){alert("Fariinta lama dirin: "+error.message)}
}
async function LiveKitCreateTracks(){
 const {createLocalTracks}=await liveSDK();
 return await createLocalTracks({audio:true,video:{facingMode:"user",resolution:{width:720,height:1280}}});
}
async function liveStart(){
 const button=liveEl("gLiveStart");button.disabled=true;
 try{
  const user=await liveUser();
  const title=liveEl("gLiveTitle").value.trim()||"GoGol LIVE";
  const {data:previous,error:previousError}=await liveDb.from("madal_live_sessions")
   .select("id,last_heartbeat_at").eq("host_id",user.id).eq("status","live").maybeSingle();
  if(previousError) throw new Error("Xaaladda LIVE hore lama hubin karin.");
  if(previous){
   const age=Date.now()-new Date(previous.last_heartbeat_at).getTime();
   if(age<=180000) throw new Error("Waxaad hore u leedahay LIVE socda. Jooji ka hor intaadan mid kale bilaabin.");
   const {error:closeError}=await liveDb.from("madal_live_sessions")
    .update({status:"ended",ended_at:new Date().toISOString()}).eq("id",previous.id);
   if(closeError) throw new Error("LIVE-gii hore wuu dhacay, balse lama xirin. Fadlan mar kale isku day.");
  }
  const roomName="gogol-"+crypto.randomUUID();
  const {data:session,error}=await liveDb.from("madal_live_sessions")
   .insert({host_id:user.id,room_name:roomName,title,status:"live"}).select("id,host_id,title,started_at").single();
  if(error) throw new Error("LIVE session lama abuuri karin. Hubi migration 009.");
  try{await liveShowRoom(session,title,"host")}
  catch(error){await liveLeave(false);await liveDb.from("madal_live_sessions").update({status:"ended",ended_at:new Date().toISOString()}).eq("id",session.id);throw error}
 }catch(error){alert(error.message||"LIVE lama bilaabi karin.");await liveLoadSessions()}
 finally{button.disabled=false}
}
async function liveJoin(session){
 try{await liveShowRoom(session,session.title,"viewer")}
 catch(error){alert(error.message||"LIVE lama daawan karo.");await liveLeave(false);await liveLoadSessions()}
}
async function liveLeave(endSession=true){
 const sessionId=liveSessionId, role=liveRole;
 if(liveHeartbeat){clearInterval(liveHeartbeat);liveHeartbeat=null}
 liveRole=null;liveSessionId=null;liveHostUserId=null;
 if(liveRoom){try{await liveRoom.disconnect()}catch{}liveRoom=null}
 for(const track of liveLocalTracks){try{track.stop()}catch{}}
 liveLocalTracks=[];
 liveEl("gLiveChat").replaceChildren();liveEl("gLiveViewers").textContent="Daawadayaal: 0";
 if(endSession&&role==="host"&&sessionId){
  const {error}=await liveDb.from("madal_live_sessions")
   .update({status:"ended",ended_at:new Date().toISOString()}).eq("id",sessionId);
  if(error) alert("Baahinta waa la joojiyey, balse xaaladda LIVE server-ka lama cusboonaysiin.");
 }
 liveEl("gLiveRoomView").classList.add("hidden");
 liveEl("gLiveHome").classList.remove("hidden");
 await liveLoadSessions();
}
liveEl("gLiveClose").addEventListener("click",liveClose);
liveEl("gLiveStart").addEventListener("click",liveStart);
liveEl("gLiveEnd").addEventListener("click",()=>liveLeave(true));
liveEl("gLiveChatForm").addEventListener("submit",liveSendChat);
liveEl("gLiveMic").addEventListener("click",async()=>{
 if(!liveRoom)return;
 const enabled=liveRoom.localParticipant.isMicrophoneEnabled;
 await liveRoom.localParticipant.setMicrophoneEnabled(!enabled);
 liveEl("gLiveMic").textContent=enabled?"🔇 Codka xiran":"🎙️ Codka";
});
liveEl("gLiveCamera").addEventListener("click",async()=>{
 if(!liveRoom)return;
 const enabled=liveRoom.localParticipant.isCameraEnabled;
 await liveRoom.localParticipant.setCameraEnabled(!enabled);
 liveEl("gLiveCamera").textContent=enabled?"📷 Camera xiran":"📷 Camera";
});
document.addEventListener("click",event=>{
 if(event.target.closest("#liveEntry")) liveOpen().catch(error=>alert(error.message));
});
