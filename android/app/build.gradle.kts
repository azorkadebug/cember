import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Upload keystore config (android/key.properties — gitignored, not committed)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.sabri.cember"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sabri.cember"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Debug anahtarına GERİ DÜŞÜLMEZ. Eskiden key.properties yoksa
            // release sessizce debug anahtarıyla imzalanıyordu — debug
            // keystore'un parolası evrensel olarak bilinir, yani o çıktıyı
            // herkes yeniden üretebilir. Anahtar yoksa derleme kırılır
            // (aşağıdaki taskGraph kontrolü).
            signingConfig = signingConfigs.getByName("release")

            // Kod küçültme + karartma. NOT: minify sonrası çöken Flutter
            // eklentileri yaygındır — Play'e yüklemeden önce release
            // derlemesini GERÇEK CİHAZDA test et.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Release derlemesi keystore olmadan başlatılırsa sessizce yanlış imzalı
// çıktı üretmek yerine açık hata ver.
gradle.taskGraph.whenReady {
    val releaseDerlemesi = allTasks.any {
        it.name.startsWith("assembleRelease") ||
        it.name.startsWith("bundleRelease") ||
        it.name.startsWith("packageRelease")
    }
    if (releaseDerlemesi && !keystorePropertiesFile.exists()) {
        throw GradleException(
            "android/key.properties bulunamadı — release derlemesi imzalanamaz. " +
            "Upload keystore'u ve key.properties dosyasını yerine koy."
        )
    }
}

flutter {
    source = "../.."
}
