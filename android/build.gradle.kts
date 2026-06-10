


buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath ("com.android.tools.build:gradle:8.11.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.23")
   
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // You might want to keep repositories here for project dependencies
    }
    // Dependencies for your actual project modules will go in their
    // respective build.gradle.kts files (e.g., app/build.gradle.kts)
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
    // Get the actual Directory object, then its File representation, then its Path
    val buildDirPath = rootProject.layout.buildDirectory.get().asFile.toPath()
    // Check if the directory exists before attempting to delete
    if (java.nio.file.Files.exists(buildDirPath)) {
        java.nio.file.Files.delete(buildDirPath)
    }
}


    