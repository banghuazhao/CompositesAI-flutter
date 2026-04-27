import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

val versionProps = Properties()
val versionPropsFile = rootProject.file("version.properties")
if (!versionPropsFile.exists()) {
    throw GradleException("Could not find 'version.properties' file.")
}
versionPropsFile.inputStream().use { versionProps.load(it) }

val currentVersionName: String = versionProps.getProperty("versionName")
    ?: throw GradleException("versionName not set in version.properties")
val currentVersionCode: Int = versionProps.getProperty("versionCode")?.toInt()
    ?: throw GradleException("versionCode not set in version.properties")

android {
    namespace = "com.banghuazhao.swiftcomp"
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
        applicationId = "com.banghuazhao.swiftcomp"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = currentVersionCode
        versionName = currentVersionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            val storeFilePath = keystoreProperties["storeFile"] as String?
            storeFile = storeFilePath?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    packaging {
        resources {
            pickFirsts += "META-INF/DEPENDENCIES"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.6.0"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")
}
