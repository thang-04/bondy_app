allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Kotlin 2.2 removed support for languageVersion = "1.6".
// Some Flutter plugins (e.g. sentry_flutter) still declare that version in
// their own build.gradle. Override every Kotlin compile task to use 1.9 so
// those plugins build without errors.
subprojects {
    afterEvaluate {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                languageVersion.set(
                    org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9
                )
                apiVersion.set(
                    org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_1_9
                )
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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
