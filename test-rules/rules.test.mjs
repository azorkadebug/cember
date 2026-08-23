/**
 * Çember — Firestore güvenlik kuralları testleri
 *
 * Çalıştırmak için:
 *   cd test-rules && npm install && npm test
 *
 * Kurallar sunucu tarafındaki TEK gerçek koruma katmanı; uygulama içi
 * şifreleme kaldırıldığı için burada bir gerileme olması doğrudan öğrenci
 * verisinin başka bir öğretmene açılması demektir.
 */
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const ADMIN_UID = 'A1Xyb80fR7NQ6KuwBt6NUa5p2743';
const AYSE = 'ogretmen_ayse';
const BURAK = 'ogretmen_burak';

let testEnv;
let ayse, burak, admin, misafir;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-cember',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
  ayse = testEnv.authenticatedContext(AYSE).firestore();
  burak = testEnv.authenticatedContext(BURAK).firestore();
  admin = testEnv.authenticatedContext(ADMIN_UID).firestore();
  misafir = testEnv.unauthenticatedContext().firestore();
});

after(async () => {
  await testEnv.cleanup();
});

/** Kuralları atlayarak başlangıç verisini yerleştirir. */
beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'siniflar/sinif_ayse'), {
      ownerId: AYSE,
      ad: '8/B',
      brans: 'beden_egitimi',
    });
    await setDoc(doc(db, 'siniflar/sinif_ayse/ogrenciler/o1'), {
      ad: 'Bir Öğrenci',
      puan: 100,
      sifrelendi: false,
    });
    await setDoc(doc(db, 'siniflar/sinif_ayse/yoklamalar/2026-08-23'), {
      tarih: '2026-08-23',
      kayitlar: { o1: { geldi: true } },
    });
    await setDoc(doc(db, 'users/' + AYSE), { ad: 'Ayşe', email: '' });
    await setDoc(doc(db, 'users/' + BURAK), { ad: 'Burak', email: '' });
  });
});

describe('Kimliksiz erişim', () => {
  it('sınıf okuyamaz', async () => {
    await assertFails(getDoc(doc(misafir, 'siniflar/sinif_ayse')));
  });

  it('öğrenci okuyamaz', async () => {
    await assertFails(getDoc(doc(misafir, 'siniflar/sinif_ayse/ogrenciler/o1')));
  });

  it('sınıf oluşturamaz', async () => {
    await assertFails(
      setDoc(doc(misafir, 'siniflar/yeni'), { ownerId: AYSE, ad: 'X' }),
    );
  });

  it('profil okuyamaz', async () => {
    await assertFails(getDoc(doc(misafir, 'users/' + AYSE)));
  });
});

describe('Kiracı izolasyonu — öğretmenler arası', () => {
  it('Burak, Ayşe\'nin sınıfını okuyamaz', async () => {
    await assertFails(getDoc(doc(burak, 'siniflar/sinif_ayse')));
  });

  it('Burak, Ayşe\'nin öğrencisini okuyamaz', async () => {
    await assertFails(
      getDoc(doc(burak, 'siniflar/sinif_ayse/ogrenciler/o1')),
    );
  });

  it('Burak, Ayşe\'nin öğrencisini değiştiremez', async () => {
    await assertFails(
      updateDoc(doc(burak, 'siniflar/sinif_ayse/ogrenciler/o1'), { puan: 1 }),
    );
  });

  it('Burak, Ayşe\'nin yoklamasını okuyamaz', async () => {
    await assertFails(
      getDoc(doc(burak, 'siniflar/sinif_ayse/yoklamalar/2026-08-23')),
    );
  });

  it('Burak, Ayşe\'nin sınıfını silemez', async () => {
    await assertFails(deleteDoc(doc(burak, 'siniflar/sinif_ayse')));
  });

  it('Burak, Ayşe\'nin profilini okuyamaz', async () => {
    await assertFails(getDoc(doc(burak, 'users/' + AYSE)));
  });

  it('filtresiz sınıf listesi reddedilir', async () => {
    await assertFails(getDocs(collection(burak, 'siniflar')));
  });

  it('sahibine filtreli liste çalışır', async () => {
    await assertSucceeds(
      getDocs(query(collection(ayse, 'siniflar'), where('ownerId', '==', AYSE))),
    );
  });

  it('başkasının uid\'siyle filtrelemek veri döndürmez', async () => {
    await assertFails(
      getDocs(query(collection(burak, 'siniflar'), where('ownerId', '==', AYSE))),
    );
  });
});

describe('Sahiplik değişmezliği', () => {
  it('ownerId başka bir kullanıcıya devredilemez', async () => {
    await assertFails(
      updateDoc(doc(ayse, 'siniflar/sinif_ayse'), { ownerId: BURAK }),
    );
  });

  it('ownerId aynı kalarak güncelleme çalışır', async () => {
    await assertSucceeds(
      updateDoc(doc(ayse, 'siniflar/sinif_ayse'), { ad: '8/C' }),
    );
  });

  it('başkasının adına sınıf oluşturulamaz', async () => {
    await assertFails(
      setDoc(doc(burak, 'siniflar/sahte'), { ownerId: AYSE, ad: 'Sahte' }),
    );
  });

  it('kendi adına sınıf oluşturulabilir', async () => {
    await assertSucceeds(
      setDoc(doc(burak, 'siniflar/burak1'), { ownerId: BURAK, ad: '5/A' }),
    );
  });
});

describe('Sahip kendi verisini yönetebilir', () => {
  it('sınıfını okur', async () => {
    await assertSucceeds(getDoc(doc(ayse, 'siniflar/sinif_ayse')));
  });

  it('öğrenci ekler', async () => {
    await assertSucceeds(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o2'), {
        ad: 'Yeni Öğrenci',
        puan: 100,
        sifrelendi: false,
      }),
    );
  });

  it('yoklama kaydeder', async () => {
    await assertSucceeds(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/yoklamalar/2026-08-24'), {
        tarih: '2026-08-24',
        kayitlar: { o1: { geldi: false } },
      }),
    );
  });

  it('öğrencisini siler', async () => {
    await assertSucceeds(
      deleteDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o1')),
    );
  });

  it('kendi profilini yazar', async () => {
    await assertSucceeds(
      setDoc(doc(ayse, 'users/' + AYSE), { ad: 'Ayşe Y.', email: '' }),
    );
  });
});

describe('Veri doğrulama', () => {
  it('çok uzun sınıf adı reddedilir', async () => {
    await assertFails(
      updateDoc(doc(ayse, 'siniflar/sinif_ayse'), { ad: 'A'.repeat(200) }),
    );
  });

  it('çok uzun öğrenci notu reddedilir', async () => {
    await assertFails(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o3'), {
        ad: 'Test',
        not: 'B'.repeat(5000),
      }),
    );
  });

  it('negatif puan reddedilir', async () => {
    await assertFails(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o4'), {
        ad: 'Test',
        puan: -5,
      }),
    );
  });

  it('aşırı büyük sağlık notu listesi reddedilir', async () => {
    await assertFails(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o5'), {
        ad: 'Test',
        saglikNotlari: Array.from({ length: 100 }, (_, i) => ({ not: String(i) })),
      }),
    );
  });

  it('şifreli eski biçimdeki uzun ad hâlâ kabul edilir', async () => {
    // Geriye dönük uyumluluk: base64 ciphertext düz metinden uzundur.
    await assertSucceeds(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/ogrenciler/o6'), {
        ad: 'x'.repeat(300),
        sifrelendi: true,
      }),
    );
  });
});

describe('Admin yetkisi', () => {
  it('normal kullanıcı users koleksiyonunu listeleyemez', async () => {
    await assertFails(getDocs(collection(ayse, 'users')));
  });

  it('admin users koleksiyonunu listeleyebilir', async () => {
    await assertSucceeds(getDocs(collection(admin, 'users')));
  });

  it('admin custom claim ile de listeleyebilir', async () => {
    const claimli = testEnv
      .authenticatedContext('bambaska_uid', { admin: true })
      .firestore();
    await assertSucceeds(getDocs(collection(claimli, 'users')));
  });

  it('admin başkasının sınıfını yine de okuyamaz', async () => {
    // Admin yalnızca profil listesine erişir; öğrenci verisi ona da kapalı.
    await assertFails(getDoc(doc(admin, 'siniflar/sinif_ayse')));
  });
});

describe('Tanımsız yollar', () => {
  it('kök seviyede bilinmeyen koleksiyon reddedilir', async () => {
    await assertFails(setDoc(doc(ayse, 'rastgele/belge'), { x: 1 }));
  });

  it('sınıf altında bilinmeyen alt koleksiyon reddedilir', async () => {
    await assertFails(
      setDoc(doc(ayse, 'siniflar/sinif_ayse/gizli/belge'), { x: 1 }),
    );
  });
});
