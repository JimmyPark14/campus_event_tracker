allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ensure Flutter plugins use the new compileSdkVersion and targetSdkVersion
extra.set("compileSdkVersion", 36)
extra.set("targetSdkVersion", 36)
extra.set("minSdkVersion", 24)

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    afterEvaluate {
        project.extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
