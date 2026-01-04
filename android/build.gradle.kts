buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // 👇 Esta línea le enseña a construir Apps de Android (seguramente ya la necesitas)
        classpath("com.android.tools.build:gradle:8.1.0") 
        
        // 👇 ESTA ES LA QUE NECESITAMOS (Nota las comillas dobles y paréntesis)
        classpath("com.google.gms:google-services:4.4.2")
    }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
