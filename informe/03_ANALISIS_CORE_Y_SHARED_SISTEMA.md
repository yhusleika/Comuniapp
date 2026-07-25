# 03 - ANÁLISIS DETALLADO DEL MÓDULO CORE Y COMPONENTES COMPARTIDOS

Este documento proporciona una explicación exhaustiva, clase por clase, función por función y línea por línea de todos los archivos alojados en los directorios `lib/core/` y `lib/shared/`, así como el punto de entrada `lib/main.dart`.

---

## 1. PUNTO DE ENTRADA PRINCIPAL (`lib/main.dart`)

* **Líneas 1–10**: Importaciones de bibliotecas base de Flutter Material, `flutter_bloc`, contenedor de inyección (`di`), servicios centrales (`SyncManager`, `HiveConfig`), sistema de temas (`AppTheme`), router (`app_router`, `AuthNotifier`) y el BLoC de autenticación (`AuthBloc`).
* **Líneas 11–19**: Función `main()` asíncrona:
  - `WidgetsFlutterBinding.ensureInitialized()`: Garantiza la vinculación nativa con el motor de Flutter antes de ejecutar operaciones asíncronas.
  - `await HiveConfig.init()`: Inicializa Hive y abre las 9 cajas cifradas con AES-256.
  - `await di.init()`: Registra todas las dependencias en GetIt.
  - `di.sl<SyncManager>().init()`: Arranca el listener de conectividad de red para la sincronización automática.
  - `runApp(const MyApp())`: Infla el árbol de widgets raíz.
* **Líneas 21–60**: Clase `MyApp` (StatefulWidget):
  - En `initState()`, obtiene la instancia Singleton de `AuthBloc`, dispara el evento `AuthCheckRequested()` para verificar la sesión guardada y crea el `AuthNotifier`.
  - En `build()`, envuelve la aplicación en `MultiBlocProvider` inyectando `AuthBloc`.
  - Retorna `MaterialApp.router` configurado con `debugShowCheckedModeBanner: false`, tema visual de `AppTheme` y enrutador `createAppRouter(_authNotifier)`.

---

## 2. CONFIGURACIÓN Y NAVEGACIÓN (`lib/core/config/` y `lib/core/router/`)

### 2.1 `lib/core/config/menu_item.dart`
* **Definición de Clase `MenuItem`**: Modela una opción del menú lateral con título (`title`), subtítulo (`subTitle`), ruta de navegación (`link`), icono FontAwesome (`icon`) y lista de roles permitidos (`rolesAllowed`).
* **Lista `appMenuItems`**: Arreglo de constantes de menú con permisos RBAC explícitos:
  - Dashboard (`/dashboard`): Todos los roles.
  - Habitantes (`/habitants`): `admin`, `vocero`, `coordinador`.
  - Reportes (`/reports`): Todos los roles.
  - Beneficios/Ayudas (`/ayudas`): `admin`, `vocero`, `coordinador`.
  - Censos (`/censos`): `admin`, `vocero`, `coordinador`.
  - Eventos (`/eventos`): Todos los roles.
  - Estructura Comuna (`/comuna`): Todos los roles.
  - Estadísticas (`/estadisticas`): `admin`, `vocero`.
  - Administración (`/administracion`): Exclusivo `admin`.
  - Auditoría (`/auditoria`): Exclusivo `admin`.
  - Configuración (`/configuracion`): Todos los roles.

### 2.2 `lib/core/router/auth_notifier.dart`
* **Propósito**: Notificador que extiende `ChangeNotifier` e implementa la reactividad entre el estado de `AuthBloc` y `GoRouter`.
* **Mecanismo**: Se suscribe al stream de `AuthBloc`. Cada vez que el estado cambia (ej. de `AuthInitial` a `AuthAuthenticated` o `AuthUnauthenticated`), invoca `notifyListeners()`, forzando a `GoRouter` a reevaluar sus reglas de redirección.

### 2.3 `lib/core/router/app_router.dart`
* **Función `createAppRouter(AuthNotifier authNotifier)`**: Construye la instancia de `GoRouter`.
* **Guardia de Redirección (`redirect`)**:
  - Si el estado de autenticación es `AuthInitial` o `AuthLoading`, retorna `null` (mantiene en pantalla de carga).
  - Si el usuario no está autenticado (`!AuthAuthenticated`) y trata de acceder a cualquier ruta que no sea `/login`, lo redirige forzosamente a `/login`.
  - Si el usuario está autenticado e intenta ir a `/login`, lo redirige automáticamente a `/dashboard`.
  - **Filtro RBAC**: Si un usuario intenta acceder a `/administracion` y su rol no contiene `admin`, lo redirige a `/dashboard`.

---

## 3. SERVICIOS CENTRALES (`lib/core/services/`)

### 3.1 `lib/core/services/hive_config.dart`
* **`_getOrCreateEncryptionKey()`**: Accede a `FlutterSecureStorage` leyendo la clave `hive_master_encryption_key`. Si no existe, genera una clave aleatoria de 256 bits mediante `Hive.generateSecureKey()` y la almacena de forma segura.
* **`init()`**: Inicializa Hive para Flutter, registra los 8 adaptadores de datos (`UserModelAdapter`, `HabitanteModelAdapter`, `ReporteModelAdapter`, `AyudaTypeModelAdapter`, `CensoModelAdapter`, `CensoRecordModelAdapter`, `AuditLogModelAdapter`, `EventoModelAdapter`) y abre las cajas cifradas con `HiveAesCipher`.

### 3.2 `lib/core/services/mongodb_service.dart`
* **Propósito**: Cliente HTTP robusto basado en Dio para conectar con la API RESTful remota.
* **Interceptor de Peticiones**: Extrae el Token JWT de `FlutterSecureStorage` (`jwt_token`) e inyecta la cabecera `Authorization: Bearer <token>`.
* **Métodos CRUD**: `createRecord`, `updateRecord`, `deleteRecord`, `getRecords`, `getStats`, `getUsers`.

### 3.3 `lib/core/services/sync_manager.dart`
* **Propósito**: Motor de sincronización en segundo plano.
* **Estados (`SyncStateEnum`)**: `idle`, `syncing`, `synced`, `offline`.
* **Métodos Internos de Sincronización**:
  - `_syncHabitants()`: Procesa habitantes no sincronizados (`isSynced == false`).
  - `_syncReports()`: Procesa denuncias locales pendientes.
  - `_syncCensos()`: Subación de formularios de censo creados localmente.
  - `_syncCensoRecords()`: Envío de respuestas de censo.
  - `_syncDeletedCensos()`: Ejecuta borrados remotos en cascada.
  - `_syncAuditLogs()`: Transmite logs de auditoría locales.
  - `_syncEventos()`: Sincroniza eventos de la comunidad.

### 3.4 `lib/core/services/audit_logger_service.dart`
* **Propósito**: Registro centralizado de auditoría para trazabilidad de acciones de usuarios.
* **Método `logAction({required String action, required String details, String? targetId})`**: Captura el usuario autenticado actual desde `AuthBloc`, crea una instancia de `AuditLog` con stampa de tiempo UTC, la guarda localmente en la caja `auditoria_logs` de Hive y la encola para sincronización.

### 3.5 `lib/core/services/image_compression_service.dart`
* **Propósito**: Optimización de imágenes.
* **Método `compressImage(File file)`**: Utiliza `flutter_image_compress` para reducir la resolución y calidad de las imágenes capturadas (calidad 70%, resolución máx 1024x1024), convirtiendo archivos grandes de cámara en imágenes livianas.

---

## 4. SISTEMA DE TEMAS Y DISEÑO (`lib/core/theme/`)

### 4.1 `lib/core/theme/app_theme.dart`
* **Tokens de Color**:
  - Primario: Azul Comunitario (`#0284C7` / `Colors.sky.shade600`).
  - Secundario: Verde Esperanza (`#10B981` / `Colors.emerald.shade500`).
  - Fondo Claro: `#F8FAFC`, Fondo Oscuro: `#0F172A`.
  - Superficie Clara: `#FFFFFF`, Superficie Oscura: `#1E293B`.
* **Configuración Material 3**: `useMaterial3: true`, bordes redondeados en tarjetas (`12.0`), botones elevados con elevación cero y relleno suave, esquemas de entrada `InputDecorationTheme` con bordes sutiles.

### 4.2 `lib/core/theme/theme_cubit.dart`
* **Propósito**: Cubit ligero que gestiona el estado del tema (`ThemeData`). Permite alternar dinámicamente entre modo claro y oscuro (`toggleTheme()`) persistiendo la preferencia en Hive.

---

## 5. CONTENEDOR DE INYECCIÓN DE DEPENDENCIAS (`lib/core/di/injection_container.dart`)

Utiliza `GetIt` (`sl`) para registrar todas las instancias del sistema organizadas por módulos de Clean Architecture:
* **Factories (`registerFactory`)**: BLoCs y Cubits (`AuthBloc`, `HabitantsBloc`, `ReportsBloc`, `AyudasBloc`, `CensosBloc`, `AuditoriaBloc`, `ProfileBloc`). Se crean instancias nuevas en cada consumo de UI.
* **Singletons (`registerLazySingleton`)**: Casos de Uso, Repositorios, Data Sources, `MongoDBService`, `SyncManager`, `AuditLoggerService`, `NetworkInfo`, `Connectivity`.

---

## 6. UTILIDADES Y HELPERS (`lib/core/utils/` y `lib/shared/helpers/`)

### 6.1 `lib/core/utils/user_roles_helper.dart`
* **`fetchOperadoresAsync()`**: Consulta asíncrona que combina la lectura de la caja local `user_session` de Hive y el endpoint remoto `/v1/users` para retornar la lista de responsables autorizados (operadores, voceros, administradores).
* **`getOperadores()`**: Retorna la lista dinámica o un conjunto de operadores por defecto (*fallback*).

### 6.2 `lib/shared/helpers/sectores_helper.dart`
* **`getAvailableSectores()`**: Retorna la lista consolidada de sectores comunitarios leyendo la caja local `sectores_box`, la API remota `/v1/sectores` o aplicando el fallback de 4 sectores por defecto (`Sector 1 - Centro`, `Sector 2 - Norte`, `Sector 3 - Sur`, `Sector 4 - Este`).

### 6.3 Exportador de Archivos Multiplataforma (`file_saver.dart`)
* **`file_saver_mobile.dart`**: Utiliza `path_provider` y `share_plus` para guardar y abrir diálogos de compartir archivos en Android e iOS.
* **`file_saver_web.dart`**: Utiliza la API DOM del navegador para crear un elemento `<a>` con atributo `download` y un objeto Blob URL para descargar archivos Excel/PDF en la Web.

---

## 7. COMPONENTES VISUALES COMPARTIDOS (`lib/shared/widgets/`)

### 7.1 `lib/shared/widgets/custom_scaffold.dart`
* Scaffold adaptable que incluye el AppBar institucional con logotipo de Comuniapp, avatar del usuario actual, botón de alternancia de tema claro/oscuro, drawer del menú lateral y cuerpo responsivo (`body`).

### 7.2 `lib/shared/widgets/side_menu.dart`
* Menú lateral de navegación. Filtra las opciones de `appMenuItems` según los roles del usuario autenticado (`user.role`). Incluye información de perfil en la cabecera y botón de Cierre de Sesión (`LogoutRequested`).

### 7.3 `lib/shared/widgets/sync_status_banner.dart`
* Banner flotante superior que reacciona a los cambios emitidos por `SyncManager`. Muestra un indicador de estado animado:
  - Naranja: "Modo Offline — Los cambios se guardarán localmente".
  - Azul giratorio: "Sincronizando con la base de datos...".
  - Verde: "Base de datos sincronizada".
