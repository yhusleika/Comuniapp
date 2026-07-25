# 07 - MANUAL DE DESPLIEGUE, MANTENIMIENTO Y OPERACIÓN

Este documento constituye la guía práctica y operacional para compilar, publicar, desplegar y mantener la plataforma **Comuniapp** en entornos de producción, prueba y desarrollo.

---

## 1. REQUISITOS PREVIOS DEL SISTEMA

### 1.1 Entorno de Desarrollo y Compilación
* **Flutter SDK**: Versión `3.2.0` o superior (Dart SDK `>=3.2.0 <4.0.0`).
* **Node.js**: Versión `18.0.0` LTS o superior.
* **Gestor de Paquetes**: `npm` v9+ o `yarn`.
* **JDK**: OpenJDK 17 (requerido para compilación de Android APK/AAB con Gradle 8+).
* **Android Studio / Xcode**: Para emulación y firmado de paquetes nativos.

---

## 2. DESPLIEGUE DEL BACKEND (NODE.JS + EXPRESS + MONGODB ATLAS)

### 2.1 Configuración del Servicio MongoDB Atlas
1. Crear un clúster en **MongoDB Atlas** (Shared o Dedicated).
2. Crear un usuario de base de datos con permisos `readWriteAnyDatabase`.
3. Configurar la lista blanca de acceso a la red (Network Access IP Whitelist) agregando `0.0.0.0/0` para permitir conexiones seguras desde el servidor PaaS (Render.com).
4. Copiar la cadena de conexión URI (ej. `mongodb+srv://admin:<password>@cluster0.mongodb.net/comuniapp_db?retryWrites=true&w=majority`).

### 2.2 Despliegue en Render.com
1. Crear un nuevo **Web Service** en Render conectando el repositorio de GitHub.
2. Configurar los parámetros del servicio:
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node src/index.js` (o detectado automáticamente mediante `Procfile`).
3. Definir las **Variables de Entorno (Environment Variables)**:
   ```env
   NODE_ENV=production
   PORT=3000
   MONGODB_URI=mongodb+srv://admin:PASS@cluster0.mongodb.net/comuniapp_db?retryWrites=true&w=majority
   JWT_SECRET=super_secret_key_comuniapp_production_2026_x98z
   ALLOWED_ORIGINS=https://comuniapp.web.app,http://localhost:3000
   ```

---

## 3. COMPILACIÓN Y PUBLICACIÓN DEL CLIENTE FLUTTER

### 3.1 Compilación de APK de Producción para Android
Para compilar el binario APK inyectando la URL pública del backend desplegado en Render:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://comuniapp-cmpr.onrender.com/v1
```

*El archivo ejecutable compilado se ubicará en `build/app/outputs/flutter-apk/app-release.apk`.*

### 3.2 Compilación de Android App Bundle (AAB para Google Play Store)
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://comuniapp-cmpr.onrender.com/v1
```

### 3.3 Compilación para Aplicación Web
```bash
flutter build web --release --dart-define=API_BASE_URL=https://comuniapp-cmpr.onrender.com/v1
```
*Los archivos estáticos generados en `build/web/` se pueden desplegar directamente en Firebase Hosting, Vercel o Netlify.*

---

## 4. MATRIZ DE RESOLUCIÓN DE PROBLEMAS (TROUBLESHOOTING)

| Problema / Síntoma | Causa Raíz Probable | Solución Operativa |
| :--- | :--- | :--- |
| **Error `401 Unauthorized` continuo** | Token JWT expirado (superó los 7 días de vigencia). | El usuario debe cerrar sesión e iniciar sesión nuevamente para obtener un token nuevo firmado. |
| **La app se queda en "Sincronizando..." más de 30s** | Cold start del backend en Render.com. | Esperar 30 segundos a que la instancia de Render despierte. Peticiones subsiguientes responderán en <200ms. |
| **Error de apertura de cajas Hive (`HiveError: Box already open`)** | Conflicto de hilos o reinicio abrupto. | `HiveConfig.init()` incluye manejo seguro. En caso extremo, reiniciar el proceso de la app. |
| **Fallo en `flutter pub get` por `share_plus`** | Incompatibilidad de paquetes win32 con `flutter_secure_storage`. | Mantener la restricción fija `share_plus: ^10.1.4` en `pubspec.yaml`. |
| **Inyección NoSQL detectada en logs** | Parámetros con `$` en entradas de usuario. | El middleware `express-mongo-sanitize` sanitiza automáticamente la entrada rechazando caracteres ilegales. |

---

## 5. RECOMENDACIONES DE MANTENIMIENTO PREVENTIVO

1. **Rotación de Clave `JWT_SECRET`**: Cambiar periódicamente la clave secreta de firma en las variables de entorno de Render.com.
2. **Respaldo de Base de Datos**: Programar backups automáticos diarios de MongoDB Atlas.
3. **Monitoreo Uptime**: Usar el endpoint `/health` con servicios como UptimeRobot o BetterStack para realizar un ping HTTP cada 5 minutos, evitando que la instancia gratuita de Render.com entre en modo de suspensión (Cold Start).
