buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Plugin de Firebase
        classpath("com.google.gms:google-services:4.4.1")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Cambio del directorio build
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Aplicar configuración a todos los subproyectos
subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tarea clean personalizada
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
