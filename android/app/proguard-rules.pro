# Çember — ProGuard/R8 kuralları
#
# minifyEnabled açıldığında Flutter eklentilerinin yansıma (reflection) ile
# eriştiği sınıflar aksi hâlde atılır ve uygulama çalışma anında çöker.
# Release derlemesini Play'e yüklemeden önce gerçek cihazda test et.

# --- Flutter ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# --- Play Core (deferred components) ---
# Flutter motoru PlayStoreDeferredComponentManager'a referans veriyor ama
# uygulama deferred component kullanmıyor, dolayısıyla Play Core kütüphanesi
# bağımlılıklarda yok. Bu kurallar olmadan R8 "Missing class
# com.google.android.play.core.*" deyip derlemeyi kırıyor.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# --- Firebase / Google Play Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore, model sınıflarını yansımayla dolduruyor.
-keepclassmembers class * {
  @com.google.firebase.firestore.PropertyName <fields>;
  @com.google.firebase.firestore.PropertyName <methods>;
}

# --- Google Sign-In ---
-keep class com.google.android.gms.auth.** { *; }

# --- BouncyCastle / PointyCastle (encrypt paketi) ---
# Eski şifreli kayıtları çözmek için hâlâ gerekli.
-dontwarn org.bouncycastle.**
-keep class org.bouncycastle.** { *; }

# --- Genel ---
# Satır numaralarını koru; kilitlenme raporları okunabilir kalsın.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes *Annotation*, Signature, Exception
