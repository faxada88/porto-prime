plugins {
    // Expose Kotlin task types to this root Gradle script without applying
    // the Kotlin Android plugin to the root project.
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
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

// stripe_android compiles its Java tasks to JVM 17. The Android Studio
// toolchain can otherwise select JVM 21 for the plugin's Kotlin task and
// Gradle refuses to combine incompatible bytecode targets. Keep the
// workaround scoped to Stripe; app logic and payment handling are unchanged.
subprojects {
    if (name == "stripe_android") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>()
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                )
            }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
