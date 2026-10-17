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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// The Stripe Android plugin must compile Java and Kotlin to the same bytecode target.
// Keep this override scoped to Stripe; other Flutter plugins retain their own targets.
subprojects {
    if (name == "stripe_android") {
        afterEvaluate {
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
                compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

// TapAndPay is a restricted SDK for provisioning issued cards, not checkout.
// The Stripe plugin declares it transitively through an optional compileOnly SDK;
// AGP release lint otherwise tries to resolve it from public Maven repositories.
subprojects {
    if (name == "stripe_android") {
        configurations.configureEach {
            exclude(group = "com.google.android.gms", module = "play-services-tapandpay")
        }
    }
}
