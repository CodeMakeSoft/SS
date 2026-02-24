# SmartSync

Esta es la aplicación **móvil** (Android & iOS) del proyecto SmartSync. Permite a los usuarios visualizar las métricas y datos, registrar información, rastrear su ubicación a través de mapas interactivos, y cuenta con un moderno diseño integrado con una sólida arquitectura.

## 🚀 Arquitectura

El proyecto fue construido pensando en la escalabilidad y limpieza:

* **Separación de Responsabilidades:** La parte de Administración Web fue separada en un proyecto distinto (`smartsync_web_admin`) para agilizar los tiempos de compilación y evitar lógica confusa en el código y sobrepeso en la app móvil. Ambos proyectos están conectados al mismo proyecto de **Firebase**, consumiendo y enviando datos a la misma nube.
* **Características Principales**:
  * Integración nativa con **Google Maps**.
  * Autenticación de Usuarios respaldada por **Firebase Auth** / **Facebook Login**.
  * Gestiones de base de datos en tiempo real mediante **Firestore**.

## 🛡️ Seguridad

* Por seguridad, las claves de las APIs (`google-services.json`, `GoogleService-Info.plist`, y configuraciones locales como el Android `local.properties`) **no están versionadas** en el repositorio.
* Si clonas este repositorio, asegúrate de configurar tu `API_KEY` de Maps dentro de `android/local.properties` (bajo el nombre `google.maps.api.key=...`) y tu archivo `AppDelegate.swift` para iOS, al igual que colocar los archivos base de Google Services.

## 📱 Tecnologías Utilizadas

- Flutter & Dart
- Firebase (Auth, Firestore, Storage)
- Google Maps (Geolocator)
- Diseño basado en Glassmorphism moderno
