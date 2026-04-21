import java.util.Properties

fun loadAndroidTvVersionCode(rootDir: File, fallback: Int): Int {
    val pubspec = rootDir.resolve("../pubspec.yaml")
    if (!pubspec.exists()) return fallback

    val line = pubspec.readLines().firstOrNull {
        it.trimStart().startsWith("android_tv_build_number:")
    } ?: return fallback

    val rawValue = line.substringAfter(":", "").trim()
    return rawValue.toIntOrNull() ?: fallback
}

fun loadAndroidTvVersionName(rootDir: File, fallback: String): String {
    val pubspec = rootDir.resolve("../pubspec.yaml")
    if (!pubspec.exists()) return fallback

    val line = pubspec.readLines().firstOrNull {
        it.trimStart().startsWith("android_tv_version:")
    } ?: return fallback

    val rawValue = line.substringAfter(":", "").trim()
    return rawValue.ifEmpty { fallback }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties().apply {
    val file = rootProject.file("keystore.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "org.moonfin.androidtv"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
    val androidTvVersionCode = loadAndroidTvVersionCode(rootDir, flutter.versionCode)
    val androidTvVersionName = loadAndroidTvVersionName(rootDir, flutter.versionName)

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "device"
    productFlavors {
        create("mobile") {
            dimension = "device"
            applicationId = "org.moonfin.androidtv"
            versionCode = flutter.versionCode
            versionName = flutter.versionName

            ndk {
                abiFilters += listOf("arm64-v8a")
            }
        }
        create("androidTv") {
            dimension = "device"
            applicationId = "org.moonfin.androidtv"
            versionCode = androidTvVersionCode
            versionName = androidTvVersionName

            ndk {
                abiFilters += listOf(
                    "arm64-v8a",
                    "armeabi-v7a",
                    "x86",
                    "x86_64",
                )
            }
        }
    }

    signingConfigs {
        create("release") {
            storeFile = file("release.keystore")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.android.gms:play-services-cast-framework:22.0.0")
}
