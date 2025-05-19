buildscript {

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0") // Ensure correct version
        classpath("com.google.gms:google-services:4.4.2") // ✅ Try this// Add Google Services
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0") // ✅ Recommended
        classpath("com.android.tools:r8:8.1.56") // ✅ Use 8.1.56 instead of 8.2.0
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}


val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
