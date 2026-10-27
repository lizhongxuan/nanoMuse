plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "io.morde.app"
    compileSdk = 35
    defaultConfig {
        applicationId = "io.morde.app"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
    sourceSets.getByName("main").assets.srcDir(layout.buildDirectory.dir("generated/mordeLegalAssets"))
}

val mordeLegalAssets = layout.buildDirectory.dir("generated/mordeLegalAssets/legal")
val copyMordeLegalAssets by tasks.registering(Copy::class) {
    from(rootProject.file("../../../LICENSE")) { rename { "LICENSE.nanoMuse.txt" } }
    from(rootProject.file("../../../NOTICE")) { rename { "NOTICE.nanoMuse.txt" } }
    from(rootProject.file("../../../THIRD_PARTY_NOTICES.md")) { rename { "THIRD_PARTY_NOTICES.nanoMuse.md" } }
    from(rootProject.file("../../MORDE_THIRD_PARTY_LICENSES.md"))
    into(mordeLegalAssets)
}
tasks.named("preBuild").configure { dependsOn(copyMordeLegalAssets) }

dependencies {
    implementation(platform("androidx.compose:compose-bom:2025.09.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:okhttp-sse:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
    testImplementation("junit:junit:4.13.2")
}
