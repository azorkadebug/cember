"use strict";
// Öğretmen paneli: tek şifre → (1) veri.json zarfını açar (tam adlar, set listesi, takım anahtarları)
//                              (2) Firebase'e ogretmen@cember.org olarak girer (kayıt okuma/silme, not ve fikstür yazma).
(function(){
const $=id=>document.getElementById(id);
const FB={p:"cakabey-basketbol",k:"AIzaSyDrEf8fQ94EF0Y9MTEiBIxTBRsOjD7eofE",e:"ogretmen@cember.org"};
const KOK="projects/"+FB.p+"/databases/(default)/documents";
const FS="https://firestore.googleapis.com/v1/"+KOK;
const b64=s=>Uint8Array.from(atob(s),c=>c.charCodeAt(0));
const tob64=b=>{let s="";for(let i=0;i<b.length;i+=8192)s+=String.fromCharCode(...b.subarray(i,i+8192));return btoa(s);};
const GRUP={yildiz:"Yıldız Erkek",kucuk:"Küçük Erkek"},TAKIMLAR=["yildiz","kucuk"];
const SINIR=5000;
let IC=null,TOKEN=null,TOKEN_BITIS=0,YENILE=null,SIFRE=null,ANAHTAR={},gun=7;
const kirli=new Set();

async function ozet(etiket,ana){const e=new TextEncoder().encode(etiket),b=new Uint8Array(e.length+ana.length);b.set(e);b.set(ana,e.length);
  return new Uint8Array(await crypto.subtle.digest("SHA-256",b));}
async function zarfAc(sifre){
  const v=await (await fetch("veri.json",{cache:"no-cache"})).json();
  const temel=await crypto.subtle.importKey("raw",new TextEncoder().encode(sifre),"PBKDF2",false,["deriveBits"]);
  const ana=new Uint8Array(await crypto.subtle.deriveBits({name:"PBKDF2",hash:"SHA-256",salt:b64(v.tuz),iterations:v.tur},temel,256));
  const k=await crypto.subtle.importKey("raw",await ozet("kilit",ana),"AES-GCM",false,["decrypt"]);
  try{return JSON.parse(new TextDecoder().decode(await crypto.subtle.decrypt({name:"AES-GCM",iv:b64(v.zarf.iv)},k,b64(v.zarf.ct))));}
  catch(e){return null;}
}
async function oturum(){
  if(TOKEN&&Date.now()<TOKEN_BITIS)return TOKEN;
  let r;
  if(YENILE){r=await fetch("https://securetoken.googleapis.com/v1/token?key="+FB.k,{method:"POST",headers:{"Content-Type":"application/x-www-form-urlencoded"},body:"grant_type=refresh_token&refresh_token="+encodeURIComponent(YENILE)});
    if(r.ok){const d=await r.json();TOKEN=d.id_token;YENILE=d.refresh_token;TOKEN_BITIS=Date.now()+(+d.expires_in-120)*1000;return TOKEN;}}
  try{r=await fetch("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="+FB.k,{method:"POST",headers:{"Content-Type":"application/json"},
    body:JSON.stringify({email:FB.e,password:SIFRE,returnSecureToken:true})});}catch(e){throw new Error("ag");}
  if(!r.ok)throw new Error("oturum");
  const d=await r.json();TOKEN=d.idToken;YENILE=d.refreshToken;TOKEN_BITIS=Date.now()+(+d.expiresIn-120)*1000;return TOKEN;
}
async function istek(url,secenek={}){
  const t=await oturum();
  let r;try{r=await fetch(url+(url.includes("?")?"&":"?")+"key="+FB.k,{...secenek,headers:{"Content-Type":"application/json",Authorization:"Bearer "+t}});}
  catch(e){throw new Error("bağlantı yok");}
  if(!r.ok)throw new Error(r.status===403?"izin/uzunluk hatası":"sunucu hatası "+r.status);
  return r.json();
}
async function sifrele(g,obj){
  const iv=crypto.getRandomValues(new Uint8Array(12));
  const ct=new Uint8Array(await crypto.subtle.encrypt({name:"AES-GCM",iv},ANAHTAR[g],new TextEncoder().encode(JSON.stringify(obj))));
  return {iv:tob64(iv),ct:tob64(ct)};
}
async function coz(g,f){return JSON.parse(new TextDecoder().decode(await crypto.subtle.decrypt({name:"AES-GCM",iv:b64(f.iv.stringValue)},ANAHTAR[g],b64(f.ct.stringValue))));}
async function yaz(yol,veri){
  return istek(FS+":commit",{method:"POST",body:JSON.stringify({writes:[{update:{name:KOK+"/"+yol,fields:{iv:{stringValue:veri.iv},ct:{stringValue:veri.ct}}},
    updateTransforms:[{fieldPath:"z",setToServerValue:"REQUEST_TIME"}]}]})});
}
const saat=()=>new Date().toLocaleTimeString("tr-TR",{hour:"2-digit",minute:"2-digit"});
async function kilitle(btn,is){btn.disabled=true;try{return await is();}finally{btn.disabled=false;}}

// ---------- Giriş ----------
$("girisForm").addEventListener("submit",async e=>{
  e.preventDefault();
  const n=$("sifre").value.toUpperCase().replace(/[^A-Z0-9]/g,"");
  if(!n){$("hata").textContent="Şifreyi yaz.";return;}
  const sifre=n.length===12?n.slice(0,4)+"-"+n.slice(4,8)+"-"+n.slice(8):$("sifre").value.trim();
  const btn=$("girBtn");btn.disabled=true;btn.textContent="Açılıyor…";$("hata").textContent="";$("sifre").removeAttribute("aria-invalid");
  try{
    let ic;try{ic=await zarfAc(sifre);}catch(err){throw new Error("ag");}
    if(!ic){$("hata").textContent="Şifre yanlış.";$("sifre").setAttribute("aria-invalid","true");$("sifre").select();return;}
    SIFRE=sifre;
    await oturum();
    IC=ic;
    for(const g of TAKIMLAR)ANAHTAR[g]=await crypto.subtle.importKey("raw",b64(IC.n[g]),"AES-GCM",false,["encrypt","decrypt"]);
    $("kapi").hidden=true;$("panel").hidden=false;$("sifre").value="";
    belgeleriGetir();kullanim();
  }catch(err){
    SIFRE=null;
    $("hata").textContent=err.message==="oturum"?"Şifre doğru ama sunucu girişi reddetti. Birkaç dakika sonra tekrar dene; sürerse Firebase'deki öğretmen hesabının şifresini kontrol et."
      :"Bağlanılamadı. İnterneti kontrol edip tekrar dene.";
  }finally{btn.disabled=false;btn.textContent="Gir";}
});
$("cikis").addEventListener("click",()=>{if(kirli.size&&!confirm("Kaydedilmemiş değişiklik var. Yine de çıkılsın mı?"))return;kirli.clear();location.reload();});
window.addEventListener("beforeunload",e=>{if(kirli.size){e.preventDefault();e.returnValue="";}});

// ---------- Notlar ve fikstür ----------
async function belgeleriGetir(){
  let sonuc=[];
  try{const r=await fetch(FS+":batchGet?key="+FB.k,{method:"POST",headers:{"Content-Type":"application/json"},
      body:JSON.stringify({documents:TAKIMLAR.flatMap(g=>[KOK+"/notlar/"+g,KOK+"/fikstur/"+g])})});sonuc=await r.json();}
  catch(e){TAKIMLAR.forEach(g=>$("d-"+g).textContent="Notlar okunamadı.");}
  const bulunan={};for(const x of sonuc)if(x.found){const p=x.found.name.split("/");bulunan[p[p.length-2]+"/"+p[p.length-1]]=x.found.fields;}
  for(const g of TAKIMLAR){
    const n=bulunan["notlar/"+g];
    if(!n)$("d-"+g).textContent="Not yok.";
    else try{const m=await coz(g,n);$("not-"+g).value=m.metin||"";$("d-"+g).textContent="Son kayıt: "+new Date(n.z.timestampValue).toLocaleString("tr-TR",{dateStyle:"medium",timeStyle:"short"});}
      catch(e){$("d-"+g).textContent="Not okunamadı (anahtar değişmiş olabilir; yeniden yazıp kaydet).";}
    let maclar=[];const f=bulunan["fikstur/"+g];
    if(f)try{maclar=(await coz(g,f)).maclar||[];}catch(e){}
    fiksturCiz(g,maclar,f?"Son kayıt: "+new Date(f.z.timestampValue).toLocaleString("tr-TR",{dateStyle:"medium",timeStyle:"short"}):"Henüz fikstür yok.");
  }
}
TAKIMLAR.forEach(g=>$("not-"+g).addEventListener("input",()=>kirli.add("not-"+g)));
document.querySelectorAll("[data-kaydet]").forEach(b=>b.addEventListener("click",()=>kilitle(b,async()=>{
  const g=b.dataset.kaydet,metin=$("not-"+g).value.trim(),d=$("d-"+g);
  if(!metin){d.textContent="Not boş; kaldırmak için 'Notu kaldır'.";return;}
  if(metin.length>3000){d.textContent="Not çok uzun (en fazla 3000 karakter).";return;}
  d.textContent="Kaydediliyor…";
  try{await yaz("notlar/"+g,await sifrele(g,{metin}));kirli.delete("not-"+g);d.textContent="Kaydedildi ✓ "+saat();}
  catch(e){d.textContent="Kaydedilemedi ("+e.message+").";}
})));
document.querySelectorAll("[data-sil]").forEach(b=>b.addEventListener("click",()=>{
  const g=b.dataset.sil;
  if(b.dataset.onay!=="1"){b.dataset.onay="1";b.textContent="Emin misin? Tekrar dokun";clearTimeout(b._t);b._t=setTimeout(()=>{b.dataset.onay="";b.textContent="Notu kaldır";},4000);return;}
  clearTimeout(b._t);b.dataset.onay="";b.textContent="Notu kaldır";
  kilitle(b,async()=>{$("d-"+g).textContent="Kaldırılıyor…";
    try{await istek(FS+":commit",{method:"POST",body:JSON.stringify({writes:[{delete:KOK+"/notlar/"+g}]})});$("not-"+g).value="";kirli.delete("not-"+g);$("d-"+g).textContent="Not kaldırıldı.";}
    catch(e){$("d-"+g).textContent="Kaldırılamadı ("+e.message+").";}});
}));

function fiksturCiz(g,maclar,durumMetni){
  const kok=$("fiksturler");let bolum=$("fx-"+g);
  if(!bolum){bolum=document.createElement("div");bolum.id="fx-"+g;kok.appendChild(bolum);}
  bolum.textContent="";
  const h=document.createElement("h3");h.textContent=GRUP[g];bolum.appendChild(h);
  const tw=document.createElement("div");tw.className="tablo";const t=document.createElement("table");t.className="fikstur-tablo";
  t.innerHTML="<thead><tr><th>Tarih</th><th>Saat</th><th>Rakip</th><th>Yer</th><th>Skor</th><th></th></tr></thead>";
  const tb=document.createElement("tbody");t.appendChild(tb);tw.appendChild(t);bolum.appendChild(tw);
  const satirEkle=m=>{
    const tr=document.createElement("tr");
    const hucre=(el,cls)=>{const td=document.createElement("td");if(cls)td.className=cls;td.appendChild(el);tr.appendChild(td);return el;};
    const inp=(type,val,ph,ad,cls)=>{const i=document.createElement("input");i.type=type;i.value=val||"";if(ph)i.placeholder=ph;i.setAttribute("aria-label",ad);if(cls)i.className=cls;i.addEventListener("input",()=>kirli.add("fx-"+g));return i;};
    hucre(inp("date",m.tarih,"","Tarih"));hucre(inp("time",m.saat,"","Saat"));
    hucre(inp("text",m.rakip,"Rakip okul","Rakip"),"genis");hucre(inp("text",m.yer,"Salon / yer","Yer"),"genis");
    hucre(inp("text",m.skor,"54-48","Skor","skor"));
    const sil=document.createElement("button");sil.type="button";sil.className="btn";sil.textContent="Sil";sil.setAttribute("aria-label","Bu maçı sil");
    sil.onclick=()=>{tr.remove();kirli.add("fx-"+g);};hucre(sil);
    tb.appendChild(tr);
  };
  maclar.slice().sort((a,b)=>(a.tarih+a.saat).localeCompare(b.tarih+b.saat)).forEach(satirEkle);
  const satir=document.createElement("div");satir.className="satir";
  const ekle=document.createElement("button");ekle.className="btn";ekle.textContent="+ Maç ekle";ekle.onclick=()=>{satirEkle({});kirli.add("fx-"+g);tb.lastChild.querySelector("input").focus();};
  const kaydet=document.createElement("button");kaydet.className="btn ana";kaydet.textContent="Fikstürü kaydet";
  const d=document.createElement("span");d.className="durum";d.setAttribute("role","status");d.textContent=durumMetni||"";
  kaydet.onclick=()=>kilitle(kaydet,async()=>{
    const liste=[...tb.children].map(tr=>{const i=tr.querySelectorAll("input");
      return {tarih:i[0].value,saat:i[1].value,rakip:i[2].value.trim(),yer:i[3].value.trim(),skor:i[4].value.trim()};})
      .filter(m=>m.tarih||m.rakip);
    if(liste.some(m=>!m.tarih)){d.textContent="Her maçın tarihi olmalı.";return;}
    d.textContent="Kaydediliyor…";
    try{
      if(!liste.length)await istek(FS+":commit",{method:"POST",body:JSON.stringify({writes:[{delete:KOK+"/fikstur/"+g}]})});
      else await yaz("fikstur/"+g,await sifrele(g,{maclar:liste}));
      kirli.delete("fx-"+g);d.textContent="Kaydedildi ✓ "+saat()+" · "+liste.length+" maç";
    }catch(e){d.textContent="Kaydedilemedi ("+e.message+").";}
  });
  satir.append(ekle,kaydet,d);bolum.appendChild(satir);
}

// ---------- Kullanım ----------
document.querySelectorAll("[data-gun]").forEach(b=>b.addEventListener("click",()=>{
  gun=b.dataset.gun;document.querySelectorAll("[data-gun]").forEach(x=>x.setAttribute("aria-pressed",x===b));kullanim();}));
$("yenile").addEventListener("click",()=>kullanim());
const tarih=z=>{const d=new Date(z),bugun=new Date();const fark=Math.round((new Date(bugun.toDateString())-new Date(d.toDateString()))/864e5);
  const s=d.toLocaleTimeString("tr-TR",{hour:"2-digit",minute:"2-digit"});
  return fark===0?"Bugün "+s:fark===1?"Dün "+s:d.toLocaleDateString("tr-TR",{day:"numeric",month:"short"})+" "+s;};
function baslangic(){
  if(gun==="sezon"){const n=new Date();const y=n.getMonth()>=8?n.getFullYear():n.getFullYear()-1;return new Date(y,8,1);}
  return new Date(Date.now()-(+gun)*864e5);
}
async function kayitlariOku(bas){
  const sonuc=await istek(FS+":runQuery",{method:"POST",body:JSON.stringify({structuredQuery:{from:[{collectionId:"kayitlar"}],
    where:{fieldFilter:{field:{fieldPath:"z"},op:"GREATER_THAN_OR_EQUAL",value:{timestampValue:bas.toISOString()}}},
    orderBy:[{field:{fieldPath:"z"},direction:"DESCENDING"}],limit:SINIR}})});
  return sonuc.filter(x=>x.document).map(x=>{const f=x.document.fields;return {ad:x.document.name,o:f.o.stringValue,t:f.t.stringValue,s:f.s.stringValue,z:f.z.timestampValue};});
}
async function kullanim(){
  $("kDurum").textContent="Yükleniyor…";
  let satirlar;
  try{satirlar=await kayitlariOku(baslangic());}
  catch(e){$("kDurum").textContent="Kayıtlar okunamadı ("+e.message+"). Aşağıdaki tablo güncel değil.";$("takimlar").classList.add("solgun");return;}
  $("takimlar").classList.remove("solgun");
  $("kDurum").textContent=satirlar.length+" kayıt · "+saat()+(satirlar.length>=SINIR?" · SINIRA ULAŞILDI: en eski kayıtlar gösterilmiyor, dönemi kısalt":"");
  const kutu=$("takimlar");kutu.textContent="";
  if(!satirlar.length){const p=document.createElement("p");p.className="bos";p.textContent="Bu dönemde henüz kayıt yok. Öğrenciler set defterini açtıkça burada görünür.";kutu.appendChild(p);}
  for(const g of TAKIMLAR){
    const ogr=IC.ogrenciler.filter(o=>o.t===g),setler=IC.setler[g]||[],setAd=Object.fromEntries(setler.map(s=>[s[0],s[1]]));
    const h=document.createElement("h3");h.textContent=GRUP[g];kutu.appendChild(h);
    const veri=ogr.map(o=>{const k=satirlar.filter(r=>r.o===o.i),gir=k.filter(r=>r.t==="giris"),iz=k.filter(r=>r.t==="izle"&&setAd[r.s]);
      return {o,gunler:new Set(gir.map(r=>new Date(r.z).toDateString())).size,izle:[...new Set(iz.map(r=>r.s))],
        son:gir.length?gir[0].z:null,sonIzle:iz.length?iz[0]:null};});
    const giren=veri.filter(v=>v.son).length;
    const izSay={};veri.forEach(v=>v.izle.forEach(s=>izSay[s]=(izSay[s]||0)+1));
    const enCok=setler.filter(s=>izSay[s[0]]).sort((a,b)=>izSay[b[0]]-izSay[a[0]])[0];
    const hic=setler.filter(s=>!izSay[s[0]]).map(s=>s[1]);
    const oz=document.createElement("div");oz.className="ozet";
    [[giren+"/"+ogr.length,"öğrenci girdi"],[veri.length?(veri.reduce((a,v)=>a+v.izle.length,0)/veri.length).toFixed(1):"0","kişi başı izlenen set"],
     [enCok?enCok[1]:"—","en çok izlenen"],[hic.length?hic.length+" set":"yok","hiç izlenmeyen"]].forEach(([b,s])=>{const d=document.createElement("div");const bb=document.createElement("b");bb.textContent=b;
       const ss=document.createElement("span");ss.textContent=s;d.append(bb,ss);oz.appendChild(d);});
    kutu.appendChild(oz);
    const tw=document.createElement("div");tw.className="tablo";const t=document.createElement("table");
    t.innerHTML="<thead><tr><th>Öğrenci</th><th>Son giriş</th><th>Giriş günü</th><th>İzlediği setler</th></tr></thead>";
    const tb=document.createElement("tbody");
    veri.sort((a,b)=>(b.son||"").localeCompare(a.son||"")||a.o.ad.localeCompare(b.o.ad,"tr")).forEach(v=>{
      const tr=document.createElement("tr");
      const c=(txt,cls)=>{const td=document.createElement("td");if(cls)td.className=cls;td.textContent=txt;tr.appendChild(td);return td;};
      const ad=c(v.o.ad);if(!v.son){const y=document.createElement("span");y.className="yok";y.textContent=gun==="sezon"?"bu sezon hiç girmedi":"son "+gun+" günde girmedi";ad.appendChild(y);}
      c(v.son?tarih(v.son):"—","sayi");c(String(v.gunler),"sayi");
      const td=c(v.izle.length+"/"+setler.length+(v.sonIzle?" · son: "+setAd[v.sonIzle.s]+" ("+tarih(v.sonIzle.z)+")":""));
      if(v.izle.length){const sw=document.createElement("div");sw.className="setler";v.izle.forEach(id=>{const sp=document.createElement("span");sp.textContent=setAd[id];sw.appendChild(sp);});td.appendChild(sw);}
      tb.appendChild(tr);});
    t.appendChild(tb);tw.appendChild(t);kutu.appendChild(tw);
    const girmeyen=veri.filter(v=>!v.son).map(v=>v.o.ad);
    const p=document.createElement("p");p.className="girmeyen";
    p.textContent=girmeyen.length?"Girmeyenler ("+girmeyen.length+"): "+girmeyen.join(", "):"Herkes girdi 👏";
    kutu.appendChild(p);
    if(girmeyen.length&&navigator.clipboard){const b=document.createElement("button");b.className="btn";b.textContent="Listeyi kopyala";
      b.onclick=()=>navigator.clipboard.writeText(GRUP[g]+" – set defterine girmeyenler: "+girmeyen.join(", ")).then(()=>{b.textContent="Kopyalandı ✓";setTimeout(()=>b.textContent="Listeyi kopyala",1500);},()=>{});
      kutu.appendChild(b);}
  }
}

// ---------- Sezon sonu temizlik ----------
$("temizle").addEventListener("click",()=>{
  const b=$("temizle");
  if(b.dataset.onay!=="1"){b.dataset.onay="1";b.textContent="Tüm kayıtlar silinecek. Emin misin? Tekrar dokun";clearTimeout(b._t);b._t=setTimeout(()=>{b.dataset.onay="";b.textContent="Tüm kullanım kayıtlarını sil (sezon sonu)";},5000);return;}
  clearTimeout(b._t);b.dataset.onay="";b.textContent="Tüm kullanım kayıtlarını sil (sezon sonu)";
  kilitle(b,async()=>{let toplam=0;$("tDurum").textContent="Siliniyor…";
    try{for(;;){const k=await kayitlariOku(new Date(0));if(!k.length)break;
        for(let i=0;i<k.length;i+=400)await istek(FS+":commit",{method:"POST",body:JSON.stringify({writes:k.slice(i,i+400).map(x=>({delete:x.ad}))})});
        toplam+=k.length;$("tDurum").textContent=toplam+" kayıt silindi…";if(k.length<SINIR)break;}
      $("tDurum").textContent=toplam+" kayıt silindi ✓";kullanim();
    }catch(e){$("tDurum").textContent="Silme yarıda kaldı ("+e.message+"), "+toplam+" kayıt silindi.";}});
});
})();
