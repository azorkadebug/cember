"use strict";
// Çakabey Basketbol — Set Defteri. Set verisi veri.json'da AES-GCM ile şifreli.
// v2: kod → PBKDF2 (tek 256 bit blok) → SHA-256("ara"|…) arama anahtarı + SHA-256("kilit"|…) zarf anahtarı
//     → o öğrencinin zarfı → veri anahtarı → setler.
(function(){
const $=id=>document.getElementById(id);
const KAYIT="cakabey-kod";
// Ayrı Firebase projesi (Çember'den bağımsız): yalnız kullanım kaydı + maç notu. Anahtar herkese açık bir istemci anahtarıdır.
const FB={p:"cakabey-basketbol",k:"AIzaSyDrEf8fQ94EF0Y9MTEiBIxTBRsOjD7eofE"};
const FS="https://firestore.googleapis.com/v1/projects/"+FB.p+"/databases/(default)/documents";
const depo={al(k){try{return localStorage.getItem(k);}catch(e){return null;}},
  yaz(k,v){try{localStorage.setItem(k,v);}catch(e){}},sil(k){try{localStorage.removeItem(k);}catch(e){}}};

// ---------- Şifre çözme ----------
const b64=s=>Uint8Array.from(atob(s),c=>c.charCodeAt(0));
const hex=b=>Array.from(b,x=>x.toString(16).padStart(2,"0")).join("");
const normal=k=>(k||"").toUpperCase().replace(/[^A-Z0-9]/g,"");
let VERI=null;
async function veriYukle(){
  if(VERI)return VERI;
  let r;try{r=await fetch("veri.json",{cache:"no-cache"});}catch(e){throw new Error("ag");}
  if(!r.ok)throw new Error("ag");
  try{VERI=await r.json();}catch(e){throw new Error("veri");}
  if(!VERI||!VERI.zarflar)throw new Error("veri");
  return VERI;
}
async function coz(key,o){return new Uint8Array(await crypto.subtle.decrypt({name:"AES-GCM",iv:b64(o.iv)},key,b64(o.ct)));}
async function ozet(etiket,ana){const e=new TextEncoder().encode(etiket),b=new Uint8Array(e.length+ana.length);b.set(e);b.set(ana,e.length);
  return new Uint8Array(await crypto.subtle.digest("SHA-256",b));}
async function ac(kod){
  const v=await veriYukle();
  const temel=await crypto.subtle.importKey("raw",new TextEncoder().encode(normal(kod)),"PBKDF2",false,["deriveBits"]);
  const ana=new Uint8Array(await crypto.subtle.deriveBits({name:"PBKDF2",hash:"SHA-256",salt:b64(v.tuz),iterations:v.tur},temel,256));
  const zarf=v.zarflar[hex((await ozet("ara",ana)).slice(0,16))];
  if(!zarf) return null;
  const kilit=await crypto.subtle.importKey("raw",await ozet("kilit",ana),"AES-GCM",false,["decrypt"]);
  const z=JSON.parse(new TextDecoder().decode(await coz(kilit,zarf)));
  const veriAnahtari=await crypto.subtle.importKey("raw",b64(z.k),"AES-GCM",false,["decrypt"]);
  const ogretmen=z.r===1&&v.tam;
  const setler=JSON.parse(new TextDecoder().decode(await coz(veriAnahtari,ogretmen?v.tam:v.veri)));
  return {ad:(z.ad||"").trim(),takim:{y:"yildiz",k:"kucuk"}[z.t]||null,setler,id:ogretmen?null:(z.i||null),not:z.n||null,ogretmen};
}

// ---------- Giriş ----------
let suruyor=false,basladi=false;
function hataGoster(m){$("hata").textContent=m;$("kod").setAttribute("aria-invalid","true");$("kapi").classList.remove("yukleniyor");}
async function gir(kod,hatirla){
  if(suruyor||basladi)return false;
  if(!(window.crypto&&crypto.subtle)){hataGoster("Tarayıcın bu sayfayı açamıyor. Güncel Safari, Chrome ya da Firefox ile dene.");return false;}
  suruyor=true;const btn=$("girBtn");btn.disabled=true;btn.textContent="Açılıyor…";$("hata").textContent="";
  try{
    const s=await ac(kod);
    if(!s){depo.sil(KAYIT);hataGoster("Bu kod tanınmadı. Harfleri ve rakamları kontrol et; olmazsa kodu öğretmenine sor.");$("kod").select();return false;}
    if(hatirla)depo.yaz(KAYIT,normal(kod));else depo.sil(KAYIT);
    baslat(s);return true;
  }catch(e){
    hataGoster(e.message==="ag"?"Bağlantı kurulamadı. İnterneti kontrol edip tekrar dene."
      :e.message==="veri"?"Set defteri şu an yüklenemiyor. Biraz sonra tekrar dene.":"Açılamadı. Sayfayı yenileyip tekrar dene.");
    return false;
  }finally{suruyor=false;btn.disabled=false;btn.textContent="Gir";}
}
$("girisForm").addEventListener("submit",e=>{e.preventDefault();gir($("kod").value,$("hatirla").checked);});
$("kod").addEventListener("input",e=>{
  if(e.isComposing)return;const el=e.target;
  if(e.inputType&&e.inputType.startsWith("insert")&&e.inputType!=="insertFromPaste"&&normal(el.value).length>8&&el.dataset.onceki!=null){
    const p=el.selectionStart-1;el.value=el.dataset.onceki;try{el.setSelectionRange(p,p);}catch(_){}return;}
  let n=normal(el.value);const m=el.value.toUpperCase().match(/[A-Z0-9]{4}[\s-]?[A-Z0-9]{4}/);
  if(n.length>8&&m)n=normal(m[0]);
  const once=Math.min(8,normal(el.value.slice(0,el.selectionStart||0)).length);n=n.slice(0,8);
  el.value=n.length>4?n.slice(0,4)+"-"+n.slice(4):n;
  const pos=once>4?once+1:once;try{el.setSelectionRange(pos,pos);}catch(_){}
  el.dataset.onceki=el.value;$("hata").textContent="";el.removeAttribute("aria-invalid");
});
$("cikis").addEventListener("click",()=>{depo.sil(KAYIT);location.replace(location.pathname);});
const kayitli=depo.al(KAYIT);
if(kayitli){$("kapi").classList.add("yukleniyor");$("hatirla").checked=true;gir(kayitli,true);}
else $("kod").focus();

// ---------- Kullanım kaydı ve maç notu ----------
let OGR=null,NOT_ANAHTARI=null;const izlendi=new Set();
function kayit(t,setId){
  if(!OGR)return;
  const ad=Array.from(crypto.getRandomValues(new Uint8Array(10)),x=>x.toString(16).padStart(2,"0")).join("");
  const body={writes:[{update:{name:"projects/"+FB.p+"/databases/(default)/documents/kayitlar/"+ad,
    fields:{o:{stringValue:OGR},t:{stringValue:t},s:{stringValue:setId||""}}},
    updateTransforms:[{fieldPath:"z",setToServerValue:"REQUEST_TIME"}],currentDocument:{exists:false}}]};
  fetch(FS+":commit?key="+FB.k,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(body),keepalive:true}).catch(()=>{});
}
function izlediKaydet(){const p=state.play;if(!p||state.g!==varsayilanTakim)return;
  if(state.goruldu.size<p.S.length||performance.now()-state.t0<p.S.length*1200)return;const k=state.g+"/"+p.id;if(izlendi.has(k))return;izlendi.add(k);kayit("izle",p.id);}
const NOTLAR={},FIKSTUR={};
const AYLAR=d=>new Date(d+"T12:00:00").toLocaleDateString("tr-TR",{day:"numeric",month:"long",weekday:"long"});
async function notlariYukle(){
  if(!NOT_ANAHTARI)return;
  const anahtar={};
  for(const g in NOT_ANAHTARI){try{anahtar[g]=await crypto.subtle.importKey("raw",b64(NOT_ANAHTARI[g]),"AES-GCM",false,["decrypt"]);}catch(e){}}
  const yollar=[];for(const g in anahtar)for(const k of ["notlar","fikstur"])yollar.push("projects/"+FB.p+"/databases/(default)/documents/"+k+"/"+g);
  if(!yollar.length)return;
  let sonuc;try{const r=await fetch(FS+":batchGet?key="+FB.k,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({documents:yollar})});
    if(!r.ok)return;sonuc=await r.json();}catch(e){return;}
  for(const x of sonuc){
    if(!x.found)continue;const parca=x.found.name.split("/"),g=parca.pop(),tur=parca.pop(),d=x.found.fields||{};
    try{const m=JSON.parse(new TextDecoder().decode(await coz(anahtar[g],{iv:d.iv.stringValue,ct:d.ct.stringValue})));
      if(tur==="notlar"&&m.metin)NOTLAR[g]={metin:m.metin,z:d.z&&d.z.timestampValue};
      if(tur==="fikstur"&&Array.isArray(m.maclar))FIKSTUR[g]=m.maclar;
    }catch(e){}
  }
  notGoster();
}
function notGoster(){
  const g=state.g,n=NOTLAR[g],f=(FIKSTUR[g]||[]).slice().sort((a,b)=>(a.tarih+a.saat).localeCompare(b.tarih+b.saat));
  const kutu=$("macNotu");
  const bugun=new Date();bugun.setHours(0,0,0,0);const bugunStr=bugun.getFullYear()+"-"+String(bugun.getMonth()+1).padStart(2,"0")+"-"+String(bugun.getDate()).padStart(2,"0");
  const sirada=f.find(m=>m.tarih>=bugunStr);
  if(!n&&!f.length){kutu.hidden=true;return;}
  kutu.hidden=false;
  const mac=m=>AYLAR(m.tarih)+(m.saat?" "+m.saat:"")+" · "+(m.rakip||"?")+(m.yer?" · "+m.yer:"");
  $("siradaki").hidden=!sirada;if(sirada)$("siradakiMetin").textContent=mac(sirada);
  $("notBlok").hidden=!n;
  if(n){$("macNotuMetin").textContent=n.metin;
    $("macNotuTarih").textContent=n.z?"yazıldı: "+new Date(n.z).toLocaleDateString("tr-TR",{day:"numeric",month:"long"}):"";}
  kutu.classList.remove("acik");$("devami").hidden=!n||n.metin.length<140;$("devami").setAttribute("aria-expanded","false");$("devami").textContent="Devamı ▾";
  const fd=$("fikstur");fd.hidden=!f.length;fd.open=false;
  if(f.length){$("fiksturSayi").textContent="Fikstür ("+f.length+" maç)";const ul=$("fiksturListe");ul.textContent="";
    f.forEach(m=>{const li=document.createElement("li");if(m.tarih<bugunStr)li.className="gecmis";if(m===sirada)li.className="sirada";
      const a=document.createElement("span");a.textContent=mac(m);li.appendChild(a);
      if(m.skor){const b=document.createElement("b");b.textContent=" "+m.skor;li.appendChild(b);}ul.appendChild(li);});}
}

// ---------- Saha (metre, FIBA). Orijin: sol dip köşe, y dip çizgiden uzaklaşır ----------
const RIM=[7.5,1.575];
const S={T:[7.5,9.0],LW:[2.4,6.7],RW:[12.6,6.7],LC:[0.7,1.1],RC:[14.3,1.1],LS:[4.7,8.6],RS:[10.3,8.6],
  LE:[5.1,5.8],RE:[9.9,5.8],LB:[4.6,2.3],RB:[10.4,2.3],FT:[7.5,5.8],IBR:[9.6,-0.75],IBL:[5.4,-0.75]};
const pt=v=>typeof v==="string"?S[v].slice():v.slice();
const TYPE={hucum:"Hücum seti",baseline:"Dip çizgiden başlama",sideline:"Kenar çizgiden başlama",pres:"Pres kırma"};
const GROUPS={yildiz:"Yıldız Erkek",kucuk:"Küçük Erkek"};
let PLAYS=null;

// ---------- Geometri ----------
function catmull(raw){
  if(raw.length<3) return raw.length===2?lin(raw[0],raw[1]):raw;
  const out=[],P=[raw[0],...raw,raw[raw.length-1]];
  for(let i=1;i<P.length-2;i++){
    const [p0,p1,p2,p3]=[P[i-1],P[i],P[i+1],P[i+2]];
    for(let k=0;k<16;k++){const t=k/16,t2=t*t,t3=t2*t;
      out.push([0,1].map(j=>.5*((2*p1[j])+(-p0[j]+p2[j])*t+(2*p0[j]-5*p1[j]+4*p2[j]-p3[j])*t2+(-p0[j]+3*p1[j]-3*p2[j]+p3[j])*t3)));}
  }
  out.push(raw[raw.length-1]);return out;
}
function lin(a,b){const o=[];for(let k=0;k<=16;k++){const t=k/16;o.push([a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t]);}return o;}
function cum(p){const c=[0];for(let i=1;i<p.length;i++)c.push(c[i-1]+Math.hypot(p[i][0]-p[i-1][0],p[i][1]-p[i-1][1]));return c;}
function along(pts,c,s){const L=c[c.length-1];s=Math.max(0,Math.min(L,s));let i=1;while(i<c.length-1&&c[i]<s)i++;
  const seg=c[i]-c[i-1]||1,t=(s-c[i-1])/seg;return [pts[i-1][0]+(pts[i][0]-pts[i-1][0])*t,pts[i-1][1]+(pts[i][1]-pts[i-1][1])*t];}
const clamp=x=>Math.max(0,Math.min(1,x));
const ease=t=>t<.5?2*t*t:1-Math.pow(-2*t+2,2)/2;
const PD=.18, SD=.25, TO=[.34,.3]; // pas süresi, şut süresi, topun eldeki kayması

function build(play){
  const cur={};for(const p in play.setup)cur[p]=pt(play.setup[p]);
  let holder=play.ball;
  play.S=play.steps.map(st=>{
    const start={};for(const p in cur)start[p]=cur[p].slice();
    const h0=holder,mv={};
    (st.m||[]).forEach(([p,k,pts,d=0,e=1])=>{const sm=catmull([start[p],...pts.map(pt)]);mv[p]={k,pts:sm,c:cum(sm),d,e};cur[p]=sm[sm.length-1].slice();});
    // Olay adım bitmeden tamamlansın: pas en geç 1-PD'de, şut en geç 1-SD'de başlar.
    const ev=[];(st.ps||[]).forEach(([a,b,at])=>ev.push({type:"pass",a,b,at:Math.min(at,1-PD)}));
    if(st.sh)ev.push({type:"shot",a:st.sh[0],at:Math.min(st.sh[1],1-SD)});
    ev.sort((x,y)=>x.at-y.at);ev.forEach(x=>{holder=x.type==="pass"?x.b:null;});
    return {start,h0,mv,ev,t:st.t};
  });
}
function posAt(play,si,p,f){const st=play.S[si],m=st.mv[p];if(!m)return st.start[p];
  const u=ease(clamp((f-m.d)/(m.e-m.d)));return along(m.pts,m.c,u*m.c[m.c.length-1]);}
function ballAt(play,si,f){
  const st=play.S[si];let h=st.h0;
  for(const ev of st.ev){
    if(f<ev.at)break;
    if(ev.type==="pass"){if(f<ev.at+PD){const a=posAt(play,si,ev.a,ev.at),b=posAt(play,si,ev.b,Math.min(1,ev.at+PD)),u=(f-ev.at)/PD;
        return {x:a[0]+TO[0]+(b[0]-a[0])*u,y:a[1]+TO[1]+(b[1]-a[1])*u,r:.2+.06*Math.sin(Math.PI*u)};}h=ev.b;}
    else{if(f<ev.at+SD){const a=posAt(play,si,ev.a,ev.at),u=(f-ev.at)/SD,x0=a[0]+TO[0],y0=a[1]+TO[1];
        return {x:x0+(RIM[0]-x0)*u,y:y0+(RIM[1]-y0)*u,r:.2+.16*Math.sin(Math.PI*u),shot:u};}h=null;}
  }
  if(h==null)return {x:RIM[0],y:RIM[1]+.45,r:.2,made:true};
  const p=posAt(play,si,h,f);return {x:p[0]+TO[0],y:p[1]+TO[1],r:.2,h};
}

// ---------- SVG çizim ----------
const NS="http://www.w3.org/2000/svg";
const el=(tag,attrs,parent)=>{const e=document.createElementNS(NS,tag);for(const k in attrs)e.setAttribute(k,attrs[k]);if(parent)parent.appendChild(e);return e;};
const f2=n=>n.toFixed(3);
const dOf=pts=>"M"+pts.map(p=>f2(p[0])+" "+f2(p[1])).join("L");

function drawCourt(){
  const g=$("courtLines");
  el("rect",{x:0,y:0,width:15,height:14,fill:"#18223B"},g);
  el("rect",{x:5.05,y:0,width:4.9,height:5.8,fill:"#1E2A48"},g);
  el("rect",{x:0,y:0,width:15,height:14,class:"cl"},g);
  el("rect",{x:5.05,y:0,width:4.9,height:5.8,class:"cl"},g);
  el("path",{d:"M5.7 5.8A1.8 1.8 0 0 0 9.3 5.8",class:"cl"},g);
  el("path",{d:"M5.7 5.8A1.8 1.8 0 0 1 9.3 5.8",class:"cl","stroke-dasharray":".3 .25"},g);
  el("path",{d:"M0.9 0V2.99A6.75 6.75 0 0 0 14.1 2.99V0",class:"cl"},g);
  el("path",{d:"M6.25 1.575A1.25 1.25 0 0 0 8.75 1.575",class:"cl"},g);
  el("path",{d:"M5.7 14A1.8 1.8 0 0 1 9.3 14",class:"cl"},g);
  el("line",{x1:6.6,y1:1.2,x2:8.4,y2:1.2,class:"cl","stroke-width":".1","stroke-opacity":".9"},g);
  el("circle",{cx:RIM[0],cy:RIM[1],r:.23,fill:"none",stroke:"#F08A24","stroke-width":".06"},g);
  el("text",{x:7.5,y:13.6,class:"lbl","text-anchor":"middle",id:"lblOrta"},g).textContent="orta saha";
  el("text",{x:0,y:-0.4,class:"lbl",id:"lblDip"},g).textContent="dip çizgi";
}
function trim(pts,a,b){const c=cum(pts),L=c[c.length-1];if(L<a+b+.05)return null;const out=[along(pts,c,a)];
  for(let i=1;i<pts.length-1;i++)if(c[i]>a&&c[i]<L-b)out.push(pts[i]);out.push(along(pts,c,L-b));return out;}
function zig(pts){const c=cum(pts),L=c[c.length-1],o=[];const stop=L-.55;
  for(let s=0;s<=stop;s+=.06){const p=along(pts,c,s),q=along(pts,c,s+.05),dx=q[0]-p[0],dy=q[1]-p[1],n=Math.hypot(dx,dy)||1,a=.16*Math.sin(s/.42*2*Math.PI);
    o.push([p[0]-dy/n*a,p[1]+dx/n*a]);}
  o.push(pts[pts.length-1]);return o;}
function drawStep(play,si,g){
  const st=play.S[si];
  for(const p in st.mv){const m=st.mv[p];
    if(m.k==="screen"){const t=trim(m.pts,.45,0);if(t)el("path",{d:dOf(t),class:"d-cut"},g);
      const n=m.pts.length,a=m.pts[Math.max(0,n-4)],b=m.pts[n-1];let dx=b[0]-a[0],dy=b[1]-a[1];const L=Math.hypot(dx,dy)||1;dx/=L;dy/=L;
      const cx=b[0]+dx*.55,cy=b[1]+dy*.55;el("line",{x1:f2(cx-dy*.5),y1:f2(cy+dx*.5),x2:f2(cx+dy*.5),y2:f2(cy-dx*.5),class:"d-bar"},g);}
    else{const t=trim(m.pts,.45,.5);if(!t)continue;el("path",{d:dOf(m.k==="dribble"?zig(t):t),class:"d-cut","marker-end":"url(#ah)"},g);}
  }
  for(const ev of st.ev){
    const a=posAt(play,si,ev.a,ev.at);
    const b=ev.type==="pass"?posAt(play,si,ev.b,Math.min(1,ev.at+PD)):RIM;
    const t=trim(lin(a,b),.48,ev.type==="pass"?.5:.25);
    if(!t){if(ev.type==="shot")el("circle",{cx:RIM[0],cy:RIM[1],r:.42,class:"d-shot"},g);continue;}
    const at={d:dOf(t),class:ev.type==="pass"?"d-pass":"d-shot"};if(ev.type==="pass")at["marker-end"]="url(#ahg)";
    el("path",at,g);
  }
}

// ---------- Durum ----------
const state={g:"yildiz",play:null,si:0,f:0,playing:false,hold:0,speed:1,trail:true,all:false,goruldu:new Set(),t0:0};
const STEP_MS=2300,HOLD_MS=500;
let dots={};
const dar=()=>matchMedia("(max-width:720px)").matches;

function setPlay(g,id,push=true){
  state.g=g;const list=PLAYS[g];const play=list.find(p=>p.id===id)||list[0];
  if(!play.S)build(play);
  state.play=play;state.si=0;state.f=0;state.playing=false;state.hold=0;state.goruldu=new Set([0]);state.t0=performance.now();
  if(push||location.hash!=="#"+g+"-"+play.id){try{history.replaceState(null,"","#"+g+"-"+play.id);}catch(e){}}
  const pres=play.type==="pres";
  if($("lblDip")){$("lblDip").textContent=pres?"KENDİ POTAMIZ · topu buradan oyuna sokuyoruz":"dip çizgi";$("lblOrta").textContent=pres?"orta saha ↓ hücum yönü":"orta saha";}
  $("court").setAttribute("aria-label",pres?"Kendi yarı sahamız, üstten görünüm":"Hücum yarı sahası, üstten görünüm");
  renderList();renderInfo();buildPlayers();renderDiag();frame();updatePlayBtn();notGoster();
}
function renderList(){
  document.querySelectorAll(".tab").forEach(t=>t.setAttribute("aria-pressed",t.dataset.g===state.g));
  const box=$("list");box.textContent="";
  [["hucum","Hücum setleri","Hücum"],["baseline","Dip çizgiden başlama","Dip"],["sideline","Kenar çizgiden başlama","Kenar"],["pres","Pres kırma","Pres"]].forEach(([ty,label,kisa])=>{
    const ps=PLAYS[state.g].filter(p=>p.type===ty);if(!ps.length)return;
    const h=document.createElement("h2");h.textContent=label+" ("+ps.length+")";box.appendChild(h);
    ps.forEach(p=>{const b=document.createElement("button");b.className="setbtn";
      const tur=document.createElement("i");tur.textContent=kisa;
      const bb=document.createElement("b");bb.textContent=p.name+(p.gizli?" ✎":"");const sm=document.createElement("small");sm.textContent=p.call;b.append(tur,bb,sm);
      b.setAttribute("aria-current",p===state.play);b.onclick=()=>setPlay(state.g,p.id);box.appendChild(b);});
  });
  const sec=box.querySelector('[aria-current="true"]');
  if(sec&&dar())box.scrollLeft=Math.max(0,sec.offsetLeft-box.clientWidth/2+sec.offsetWidth/2);
}
function renderInfo(){
  const p=state.play;$("pName").textContent=p.name;
  $("pMeta").textContent="";
  [...(p.gizli?[["Taslak · yalnız sen görüyorsun","chip taslak"]]:[]),[TYPE[p.type],"chip type"],[GROUPS[state.g],"chip"],["İşaret: "+p.call,"chip"]].forEach(([t,c])=>{const s=document.createElement("span");s.className=c;s.textContent=t;$("pMeta").appendChild(s);});
  $("pGoal").textContent=p.goal;
  const ol=$("pSteps");ol.textContent="";
  p.steps.forEach((s,i)=>{const li=document.createElement("li");const b=document.createElement("button");b.type="button";b.textContent=s.t;li.appendChild(b);
    b.onclick=()=>{goStep(i);state.playing=true;updatePlayBtn();kick();if(dar())$("court").scrollIntoView({block:"nearest",behavior:hareketAz()?"auto":"smooth"});};
    ol.appendChild(li);});
  const ul=$("pKeys");ul.textContent="";p.keys.forEach(k=>{const li=document.createElement("li");li.textContent=k;ul.appendChild(li);});
  $("duyuru").textContent=p.name+": "+p.goal;
}
function buildPlayers(){
  const g=$("players");g.textContent="";dots={};const r=dar()?.5:.42;
  Object.keys(state.play.setup).sort().forEach(p=>{
    const grp=el("g",{class:"pl"+(+p===state.play.inb?" inb":"")},g);
    el("circle",{r},grp);el("text",{y:.02},grp).textContent=p;dots[p]=grp;});
  $("ball").firstElementChild.dataset.r=dar()?1.25:1;
}
function renderDiag(){
  const g=$("diag");g.textContent="";const p=state.play;
  if(state.all){p.S.forEach((_,i)=>drawStep(p,i,el("g",{},g)));}
  else{ if(state.trail)for(let i=0;i<state.si;i++)drawStep(p,i,el("g",{class:"past"},g));
    drawStep(p,state.si,el("g",{},g)); }
  document.querySelectorAll("#pSteps li").forEach((li,i)=>{li.className=state.all?"":(i===state.si?"on":(i<state.si?"past":""));
    if(!state.all&&i===state.si)li.setAttribute("aria-current","step");else li.removeAttribute("aria-current");});
  const n=p.S.length;
  $("adimMetni").textContent=state.all?"Tüm şema: "+n+" adım birlikte":(state.si+1)+"/"+n+" · "+p.steps[state.si].t;
}
function frame(){
  const p=state.play,si=state.si,f=state.all?0:state.f;const s=state.all?0:si;
  for(const k in dots){const q=posAt(p,s,k,f);dots[k].setAttribute("transform","translate("+f2(q[0])+" "+f2(q[1])+")");}
  const b=ballAt(p,s,f);const bc=$("ball").firstElementChild;const k=+(bc.dataset.r||1);
  bc.setAttribute("cx",f2(b.x));bc.setAttribute("cy",f2(b.y));bc.setAttribute("r",f2(b.r*k));
  for(const d in dots)dots[d].classList.toggle("top",!state.all&&String(b.h)===d);
  const last=si===p.S.length-1,fl=$("flash");
  const sayi=b.made&&!state.all&&last&&p.S[si].ev.some(e=>e.type==="shot");
  const gecti=!state.all&&last&&state.f>=1&&p.type==="pres";
  fl.textContent=state.all?"":sayi?"SAYI!":gecti?"ORTA SAHA ✓":(state.si===0&&state.f===0&&!state.playing?"Başlangıç dizilişi":"");
  fl.setAttribute("y",sayi?"4.1":p.type==="pres"?"9.8":"12.2");
}
function goStep(i){state.si=Math.max(0,Math.min(state.play.S.length-1,i));state.goruldu.add(state.si);state.f=0;state.hold=0;state.all=false;$("all").checked=false;renderDiag();frame();}
function updatePlayBtn(){const end=state.si===state.play.S.length-1&&state.f>=1&&!state.playing;
  $("bPlay").textContent=state.playing?"❚❚ Durdur":(end?"⟲ Tekrar":"▶ Oynat");}
function togglePlay(){
  if(state.all){state.all=false;$("all").checked=false;goStep(0);}
  const end=state.si===state.play.S.length-1&&state.f>=1;
  if(!state.playing&&end){goStep(0);}
  state.playing=!state.playing;updatePlayBtn();kick();
}
const hareketAz=()=>matchMedia("(prefers-reduced-motion: reduce)").matches;
let last=0,raf=0;
function kick(){if(!raf){last=performance.now();raf=requestAnimationFrame(loop);}}
function loop(now){
  raf=0;const dt=Math.min(64,now-last);last=now;
  if(!state.playing)return;
  if(state.hold>0){state.hold-=dt;if(state.hold<=0){if(state.si<state.play.S.length-1){state.si++;state.goruldu.add(state.si);state.f=0;renderDiag();}else{state.playing=false;updatePlayBtn();izlediKaydet();}}}
  else if(hareketAz()){state.f=1;state.hold=1500;}
  else{state.f+=dt*state.speed/STEP_MS;if(state.f>=1){state.f=1;state.hold=HOLD_MS;}}
  frame();
  if(state.playing)raf=requestAnimationFrame(loop);
}

// ---------- Başlat (giriş sonrası) ----------
let varsayilanTakim="yildiz";
function fromHash(){const h=(location.hash||"").slice(1);const m=h.match(/^(yildiz|kucuk)-(.+)$/);
  if(m)setPlay(m[1],m[2],false);else if(h==="yildiz"||h==="kucuk")setPlay(h,null,false);else setPlay(varsayilanTakim,null,false);}
function baslat(s){
  if(basladi)return;basladi=true;
  PLAYS=s.setler;if(s.takim&&PLAYS[s.takim])varsayilanTakim=s.takim;
  OGR=s.id;NOT_ANAHTARI=s.not;
  {const gk="cakabey-giris";const bug=new Date().toDateString()+"|"+OGR;if(depo.al(gk)!==bug){depo.yaz(gk,bug);kayit("giris","");}}
  $("selam").textContent=s.ad?"Merhaba, "+s.ad:"";
  $("kapi").hidden=true;$("uygulama").hidden=false;
  document.querySelectorAll(".tab").forEach(t=>t.onclick=()=>setPlay(t.dataset.g,null));
  $("bPlay").onclick=togglePlay;
  $("bReset").onclick=()=>{state.playing=false;goStep(0);updatePlayBtn();};
  $("bPrev").onclick=()=>{state.playing=false;const i=state.f>0.02?state.si:state.si-1;goStep(i);updatePlayBtn();};
  $("bNext").onclick=()=>{state.playing=false;if(state.f<1){state.f=1;state.hold=0;frame();}else if(state.si<state.play.S.length-1)goStep(state.si+1);
    if(state.si===state.play.S.length-1&&state.f>=1)izlediKaydet();updatePlayBtn();};
  $("speed").onchange=e=>{state.speed=+e.target.value;e.target.blur();};
  $("trail").onchange=e=>{state.trail=e.target.checked;renderDiag();};
  $("all").onchange=e=>{state.all=e.target.checked;state.playing=false;updatePlayBtn();renderDiag();frame();};
  document.addEventListener("keydown",e=>{const t=e.target;
    if(e.altKey||e.metaKey||e.ctrlKey||t.isContentEditable||/^(INPUT|SELECT|TEXTAREA)$/.test(t.tagName))return;
    if(e.key===" "){if(t.closest&&t.closest("button"))return;e.preventDefault();if(!e.repeat)togglePlay();}
    else if(e.key==="ArrowRight"){e.preventDefault();$("bNext").click();}
    else if(e.key==="ArrowLeft"){e.preventDefault();$("bPrev").click();}
    else if(e.key==="Home"){e.preventDefault();$("bReset").click();}});
  window.addEventListener("hashchange",fromHash);
  let genis=dar();window.addEventListener("resize",()=>{if(dar()!==genis){genis=dar();buildPlayers();frame();}});
  drawCourt();fromHash();notlariYukle();
  $("devami").addEventListener("click",()=>{const k=$("macNotu"),a=k.classList.toggle("acik");$("devami").setAttribute("aria-expanded",a);$("devami").textContent=a?"Kısalt ▴":"Devamı ▾";});
  $("pName").tabIndex=-1;try{$("pName").focus({preventScroll:true});}catch(_){}
}
})();
