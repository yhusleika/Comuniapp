# 01 - ANÁLISIS METICULOSO DE LIBRERÍAS Y DEPENDENCIAS

Este documento desglosa **absolutamente todas** las dependencias y paquetes de software de los cuales depende el proyecto Comuniapp, tanto en el cliente móvil/frontend (Flutter) como en el servidor backend (Node.js/Express).

---

## 1. DEPENDENCIAS DEL FRONTEND / FLUTTER (`pubspec.yaml`)

### 1.1 Dependencias Principales y de Arquitectura (`dependencies`)

#### 1. `flutter` (SDK)
* **Versión**: SDK Flutter (`>=3.2.0 <4.0.0`).
* **Propósito**: Framework base para renderizado multiplataforma (Android, iOS, Web, Desktop) basado en el motor Skia/Impeller.
* **Justificación de uso**: Permite compilar una base de código única en lenguaje Dart con rendimiento cercano a nativo a 60/120 fps.

#### 2. `path` (`^1.9.0`)
* **Versión**: `1.9.0`.
* **Propósito**: Manipulación estandarizada y segura de rutas de archivos en el sistema operativo.
* **Ubicación en Código**: Utilizado en servicios de almacenamiento y gestión de directorios locales.
* **Justificación de uso**: Abstrae las diferencias en los separadores de ruta entre Windows (`\`) y POSIX/Linux/macOS/Android (`/`).

#### 3. `hive` (`^2.2.3`) y `hive_flutter` (`^1.1.0`)
* **Versiones**: `hive: ^2.2.3`, `hive_flutter: ^1.1.0`.
* **Propósito**: Base de datos NoSQL clave-valor ultra rápida y ligera escrita puramente en Dart.
* **Ubicación en Código**: `lib/core/services/hive_config.dart`, datasources locales (`habitants_local_data_source.dart`, `censos_local_data_source.dart`, etc.).
* **Justificación de uso**: Es el pilar del modelo *Offline-First*. Ofrece velocidad de lectura/escritura muy superior a SQLite (SQFlite) y soporta cifrado directo en disco mediante `HiveAesCipher`.

#### 4. `flutter_secure_storage` (`^9.0.0`)
* **Versión**: `9.2.4`.
* **Propósito**: Almacenamiento seguro en disco utilizando hardware de cifrado nativo del SO (Android Keystore y iOS Keychain).
* **Ubicación en Código**: `lib/core/services/hive_config.dart` (para resguardar la clave de cifrado AES-256 de Hive) y `lib/core/services/mongodb_service.dart` (para almacenar el Token JWT).
* **Justificación de uso**: Impide que cibercriminales o aplicaciones maliciosas con acceso root/jailbreak lean los datos sensibles o tokens en texto plano del sandbox de la app.

#### 5. `get_it` (`^7.6.4`)
* **Versión**: `7.7.0`.
* **Propósito**: Localizador de servicios (Service Locator) e Inyector de Dependencias para Dart.
* **Ubicación en Código**: `lib/core/di/injection_container.dart`.
* **Justificación de uso**: Desacopla la creación de objetos del uso de los mismos. Registra Singletons (`registerLazySingleton`) y Factorías (`registerFactory`) para Casos de Uso, Repositorios, BLoCs y Servicios, facilitando la prueba unitaria (*mocking*).

#### 6. `flutter_bloc` (`^8.1.3`) y `equatable` (`^2.0.5`)
* **Versiones**: `flutter_bloc: ^8.1.6`, `equatable: ^2.0.8`.
* **Propósito**: Patron de gestión de estado predecible basado en eventos (BLoC - Business Logic Component) e igualdad de objetos por valor.
* **Ubicación en Código**: `lib/features/*/presentation/bloc/*`.
* **Justificación de uso**: Separa completamente la lógica de negocio de la UI. `Equatable` evita reconstrucciones innecesarias del árbol de widgets al comparar instancias de estados por sus propiedades y no por referencia de memoria.

#### 7. `dartz` (`^0.10.1`)
* **Versión**: `0.10.1`.
* **Propósito**: Librería de programación funcional para Dart que introduce el tipo de dato `Either<L, R>`.
* **Ubicación en Código**: Casos de uso y repositorios (`Future<Either<Failure, T>>`).
* **Justificación de uso**: Evita el uso indiscriminado de bloque `try-catch` o lanzamiento de excepciones no controladas. El lado izquierdo (`Left`) representa un fallo (`Failure`) y el derecho (`Right`) representa el resultado exitoso.

#### 8. `flutter_riverpod` (`^2.4.9`)
* **Versión**: `2.6.1`.
* **Propósito**: Sistema de gestión de estado reactivo y compile-safe basado en proveedores.
* **Ubicación en Código**: `habitants_notifier.dart`, `ayudas_notifier.dart`, `censos_notifier.dart`.
* **Justificación de uso**: Ofrece reactividad simplificada en componentes específicos donde se prefiere notificar cambios de listas en tiempo real de forma fluida.

#### 9. `go_router` (`^13.0.1`)
* **Versión**: `13.2.5`.
* **Propósito**: Enrutador declarativo oficial de Flutter basado en la API Navigator 2.0.
* **Ubicación en Código**: `lib/core/router/app_router.dart`.
* **Justificación de uso**: Soporta rutas jerárquicas, parámetros por URL, deep linking y middleware de redirección reactiva (`redirect`) mediante `AuthNotifier` para denegar acceso a usuarios no autenticados o sin rol de administrador.

#### 10. `dio` (`^5.4.2+1`)
* **Versión**: `5.9.2`.
* **Propósito**: Cliente HTTP avanzado para Dart con soporte para interceptores, transformadores, timeouts y cancelación de peticiones.
* **Ubicación en Código**: `lib/core/services/mongodb_service.dart`.
* **Justificación de uso**: A diferencia del paquete `http` estándar, Dio permite agregar interceptores globales para inyectar automáticamente cabeceras de autorización JWT (`Bearer <token>`), gestionar errores HTTP globales y configurar timeouts de conexión de 30 segundos (crucial para cold-starts de servidores gratuitos en Render.com).

#### 11. `formz` (`^0.7.0`)
* **Versión**: `0.7.0`.
* **Propósito**: Abstracción para validación de formularios reactivos y representación inmutable de campos de entrada.
* **Ubicación en Código**: Formularios de login y registro de habitantes.
* **Justificación de uso**: Mantiene el estado de validez de las entradas (email, teléfono, cédula) de manera desacoplada de los widgets.

#### 12. `uuid` (`^4.2.1`)
* **Versión**: `4.5.3`.
* **Propósito**: Generador de identificadores únicos universales (UUID v4).
* **Ubicación en Código**: Asignación de IDs primarios únicos a habitantes, reportes, censos y logs creados en modo offline antes de subir al backend.
* **Justificación de uso**: Previene colisiones de IDs entre registros creados por diferentes usuarios en dispositivos distintos sin conexión.

#### 13. `intl` (`^0.19.0`)
* **Versión**: `0.19.0`.
* **Propósito**: Internacionalización, formato de fechas, horas, números y monedas.
* **Ubicación en Código**: Formateo de fechas de auditoría, reportes y eventos comunitarios.

#### 14. `crypto` (`^3.0.3`)
* **Versión**: `3.0.3`.
* **Propósito**: Algoritmos de hashing y criptografía (SHA-256, MD5, HMAC).
* **Ubicación en Código**: Utilidades de verificación de integridad y tokens de comprobación.

#### 15. `path_provider` (`^2.1.1`)
* **Versión**: `2.1.1`.
* **Propósito**: Obtención de directorios del sistema de archivos local (`ApplicationDocumentsDirectory`, `TemporaryDirectory`).
* **Ubicación en Código**: Inicialización de almacenamiento de Hive e imágenes de reporte.

#### 16. `connectivity_plus` (`^5.0.2`)
* **Versión**: `5.0.2`.
* **Propósito**: Monitor de estado de conectividad a la red (Wi-Fi, Datos Móviles, Ethernet, Ninguna).
* **Ubicación en Código**: `lib/core/services/sync_manager.dart` y `lib/core/network/network_info.dart`.
* **Justificación de uso**: Permite a `SyncManager` reaccionar de forma automática cuando el dispositivo recupera señal de red para disparar la sincronización.

#### 17. `animate_do` (`^3.1.2`)
* **Versión**: `3.3.9`.
* **Propósito**: Colección de animaciones fluidas basadas en Animate.css para Flutter (FadeIn, SlideIn, ZoomIn).
* **Ubicación en Código**: Transiciones de pantallas, banners de estado y modales.

#### 18. `flutter_image_compress` (`^2.3.0`) e `image_picker` (`^1.0.4`)
* **Versiones**: `flutter_image_compress: ^2.4.0`, `image_picker: ^1.2.2`.
* **Propósito**: Selección de imágenes desde la cámara/galería del dispositivo y su posterior compresión optimizada en formato JPEG/WebP.
* **Ubicación en Código**: `lib/core/services/image_compression_service.dart`, captura de fotos de perfil y reportes.
* **Justificación de uso**: Reduce fotos de 10 MB a menos de 300 KB antes de guardarlas localmente o transmitirlas por red, ahorrando ancho de banda y espacio en MongoDB.

#### 19. `font_awesome_flutter` (`^10.6.0`)
* **Versión**: `10.12.0`.
* **Propósito**: Set completo de iconos vectoriales de FontAwesome.
* **Ubicación en Código**: Menú lateral (`side_menu.dart`), tarjetas de beneficios y botones de acción.

#### 20. Componentes de UI y Dashboard (`syncfusion_flutter_gauges`, `timeline_tile`, `data_table_2`, `excel`, `pdf`, `printing`, `share_plus`)
* **`syncfusion_flutter_gauges` (`^24.2.3`)**: Indicadores radiales y medidores de velocidad en la pantalla de Dashboard.
* **`timeline_tile` (`^2.0.0`)**: Renderizado de líneas de tiempo para historial de auditoría y estados de denuncias.
* **`data_table_2` (`2.5.8`)**: Tablas de datos avanzadas con ordenamiento, paginación y columnas fijas.
* **`excel` (`^4.0.3`)**: Generación nativa de hojas de cálculo `.xlsx` desde estructuras de Dart.
* **`pdf` (`^3.11.3`) & `printing` (`^5.14.0`)**: Creación de documentos PDF vectoriales y diálogo de impresión directa.
* **`share_plus` (`^10.1.4`)**: Compartir archivos PDF/Excel exportados mediante aplicaciones nativas del sistema (WhatsApp, Correo, Telegram).

---

### 1.2 Dependencias de Desarrollo (`dev_dependencies`)

1. **`flutter_test`**: Framework oficial de pruebas unitarias y de widgets.
2. **`flutter_lints` (`^3.0.1`)**: Reglas de análisis estático recomendadas por la comunidad de Flutter para mantener código limpio.
3. **`build_runner` (`^2.4.6`)**: Generador de código en tiempo de desarrollo.
4. **`hive_generator` (`^2.0.1`)**: Genera automáticamente los adaptadores de Hive (`.g.dart`) leyendo las anotaciones `@HiveType` y `@HiveField`.
5. **`mocktail` (`^1.0.1`)**: Mocking seguro sin generación de código para pruebas unitarias.
6. **`flutter_launcher_icons` (`^0.13.1`)**: Generación automatizada de iconos de aplicación para Android e iOS.

---

## 2. DEPENDENCIAS DEL BACKEND / NODE.JS (`backend/package.json`)

```json
{
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.6",
    "dotenv": "^17.4.2",
    "express": "^5.2.1",
    "express-mongo-sanitize": "^2.2.0",
    "express-rate-limit": "^7.1.5",
    "helmet": "^7.1.0",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^9.7.1",
    "multer": "^2.2.0"
  }
}
```

#### 1. `express` (`^5.2.1`)
* **Propósito**: Framework web rápido, unopinionated y minimalista para Node.js.
* **Ubicación en Código**: `backend/src/index.js` y `backend/src/routes/*`.
* **Justificación de uso**: Maneja la canalización de peticiones HTTP v1, middlewares y enrutamiento RESTful.

#### 2. `mongoose` (`^9.7.1`)
* **Propósito**: Modelado de objetos de datos (ODM - Object Data Modeling) para MongoDB y Node.js.
* **Ubicación en Código**: `backend/src/config/db.js` y `backend/src/models/*`.
* **Justificación de uso**: Proporciona esquemas estructurados con validación de tipos, conversión de objetos, operaciones atómicas y agregaciones en MongoDB Atlas.

#### 3. `jsonwebtoken` (`^9.0.2`)
* **Propósito**: Implementación de Tokens de Web de JSON (JWT) según el estándar RFC 7519.
* **Ubicación en Código**: `backend/src/middleware/auth.middleware.js` y `backend/src/controllers/auth.controller.js`.
* **Justificación de uso**: Autentica de forma apátrida (stateless) las solicitudes HTTP. El servidor firma el token usando una clave secreta (`JWT_SECRET`) y el cliente lo envía en la cabecera `Authorization: Bearer <token>`.

#### 4. `bcryptjs` (`^2.4.3`)
* **Propósito**: Algoritmo de hashing de contraseñas optimizado derivado de Blowfish.
* **Ubicación en Código**: `backend/src/controllers/auth.controller.js` y `backend/src/controllers/users.controller.js`.
* **Justificación de uso**: Aplica salado (salt de 12 rondas) a las claves de usuario antes de guardarlas en MongoDB, haciendo matemáticamente inviable ataques de tablas arcoíris o fuerza bruta.

#### 5. `helmet` (`^7.1.0`)
* **Propósito**: Middleware de seguridad que configura automáticamente cabeceras HTTP de protección.
* **Ubicación en Código**: `backend/src/index.js`.
* **Justificación de uso**: Previene vulnerabilidades conocidas como Cross-Site Scripting (XSS), Clickjacking, X-Powered-By leakage, y fuerza la descarga segura de recursos.

#### 6. `express-rate-limit` (`^7.1.5`)
* **Propósito**: Limitador de tasa de solicitudes HTTP para Express.
* **Ubicación en Código**: `backend/src/index.js`.
* **Justificación de uso**: Restringe a un máximo de 200 peticiones por ventana de 15 minutos por dirección IP, evitando denegaciones de servicio (DoS) y fuerza bruta en endpoints de autenticación.

#### 7. `express-mongo-sanitize` (`^2.2.0`)
* **Propósito**: Middleware de sanitización contra inyecciones NoSQL.
* **Ubicación en Código**: `backend/src/index.js`.
* **Justificación de uso**: Elimina caracteres prohibidos como `$` y `.` de las entradas del usuario (`req.body`, `req.query`, `req.params`), impidiendo que atacantes inyecten operadores de consulta MongoDB (ej. `{ "$gt": "" }`).

#### 8. `cors` (`^2.8.6`)
* **Propósito**: Habilitación y filtrado de Intercambio de Recursos de Origen Cruzado (CORS).
* **Ubicación en Código**: `backend/src/index.js`.
* **Justificación de uso**: Controla qué orígenes (dominios/IPs) tienen permitido realizar peticiones HTTP al servidor API.

#### 9. `multer` (`^2.2.0`)
* **Propósito**: Middleware para gestión de peticiones `multipart/form-data` para subida de archivos.
* **Ubicación en Código**: `backend/src/routes/users.route.js` y `backend/src/routes/reports.route.js`.
* **Justificación de uso**: Procesa y guarda fotos de perfil e imágenes adjuntas a denuncias en el sistema de archivos del servidor (`/uploads`).

#### 10. `dotenv` (`^17.4.2`)
* **Propósito**: Carga variables de entorno desde un archivo `.env` hacia `process.env`.
* **Ubicación en Código**: `backend/src/index.js` y `backend/src/config/db.js`.
* **Justificación de uso**: Mantiene contraseñas de DB, URI de MongoDB Atlas y claves de firma JWT fuera del código fuente.
