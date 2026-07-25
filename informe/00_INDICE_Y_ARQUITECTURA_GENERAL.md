# 00 - ÍNDICE GENERAL Y ARQUITECTURA DEL SISTEMA COMUNIAPP

## 1. INTRODUCCIÓN Y PROPÓSITO DEL DOCUMENTO

El presente documento constituye la primera entrega del **Informe de Análisis Técnico Profundo, Meticuloso e Integral** de la aplicación **Comuniapp** (Gestión Social Comunitaria Offline-First). Este informe ha sido redactado con un nivel de detalle del 100%, cubriendo sin omisión alguna cada archivo, clase, método, variable, dependencia, librería, protocolo de seguridad, protocolo de red, esquema de base de datos y flujo de datos dentro de la arquitectura del sistema.

**Comuniapp** es una plataforma tecnológica diseñada para optimizar la gestión comunitaria, el censo poblacional, la distribución de ayudas sociales (CLAP, gas, medicamentos), el registro de denuncias/reportes de infraestructura, la coordinación de eventos de calle y la auditoría de operaciones en comunidades urbanas y rurales.

---

## 2. FICHA TÉCNICA DEL PROYECTO

* **Nombre de la Aplicación**: Comuniapp (`social_management_pro`).
* **Versión Actual**: `1.0.0+1`.
* **Paradigma de Almacenamiento**: *Offline-First* (Operación local prioritaria sin conexión a Internet con sincronización remota diferida).
* **Stack Móvil / Frontend**: Flutter `3.2.0+` (Dart SDK `>=3.2.0 <4.0.0`), Clean Architecture, BLoC (`flutter_bloc`), Riverpod (`flutter_riverpod`), Hive Database (AES-256), Dio HTTP Client, GoRouter.
* **Stack Backend / Servidor**: Node.js (`>=18.0.0`), Express.js (`v5.2.1`), Mongoose ORM (`v9.7.1`), MongoDB Atlas, JWT Authentication, Bcryptjs, Helmet Security, Express Rate Limit, Mongo Sanitize.
* **Entornos Soportados**: Android (APK/AAB), iOS (IPA), Web (Single Page Application HTML5/JS), Linux Desktop, Windows Desktop, macOS Desktop.

---

## 3. MAPA COMPLETO DEL PROYECTO Y ESTRUCTURA DE ARCHIVOS

A continuación se presenta el árbol completo de la estructura del repositorio:

```
Comuniapp/
├── android/                             # Configuración nativa para plataforma Android
│   ├── app/build.gradle                 # Configuración de compilación, Gradle, SDK mínimo (21)
│   └── gradle.properties                # Propiedades de compilación de Android
├── assets/                              # Recursos gráficos estáticos
│   ├── images/                          # Logotipos, fondos e isotipos del sistema
│   └── loaders/                         # Animaciones de carga
├── backend/                             # API RESTful desarrollada en Node.js + Express
│   ├── Procfile                         # Script de inicio para despliegue en PaaS (Render.com/Heroku)
│   ├── package.json                     # Declaración de dependencias del servidor
│   ├── package-lock.json                # Bloqueo de versiones exactas de dependencias Node
│   └── src/                             # Código fuente del backend
│       ├── index.js                     # Punto de entrada principal y bastionado de Express
│       ├── config/
│       │   └── db.js                    # Conexión a MongoDB Atlas mediante Mongoose
│       ├── controllers/                 # Lógica de negocio y controladores REST
│       │   ├── auth.controller.js       # Registro, Login, hashing bcrypt y emisión de JWT
│       │   ├── auditoria.controller.js  # Registro y consulta de logs de auditoría
│       │   ├── ayudas.controller.js     # Gestión de tipos y asignaciones de ayudas sociales
│       │   ├── censo_records.controller.js # Respuestas de encuestas poblacionales
│       │   ├── censos.controller.js     # Diseñador dinámico de censos poblacionales
│       │   ├── eventos.controller.js    # Eventos comunitarios y logística
│       │   ├── habitants.controller.js  # Padrón electoral y catálogo de habitantes
│       │   ├── reports.controller.js    # Gestión de reportes/denuncias comunitarias
│       │   ├── sectores.controller.js   # Catálogo geográfico de sectores y calles
│       │   ├── stats.controller.js      # Métricas agregadas y analítica del dashboard
│       │   └── users.controller.js      # Perfil de usuario y actualización con fotos
│       ├── middleware/                  # Capa de middlewares de seguridad y control
│       │   ├── auth.middleware.js       # Verificación de firmas JWT y control de acceso RBAC
│       │   └── role.middleware.js       # Filtros adicionales por rol de usuario
│       ├── models/                      # Esquemas de datos Mongoose para MongoDB
│       │   ├── auditoria.model.js       # Modelo AuditLog
│       │   ├── ayuda.model.js           # Modelo AyudaType
│       │   ├── censo.model.js           # Modelo Censo (Estructura dinámica de formulario)
│       │   ├── censo_record.model.js    # Modelo CensoRecord (Registro de familia encuestada)
│       │   ├── evento.model.js          # Modelo Evento
│       │   ├── habitante.model.js       # Modelo Habitante
│       │   ├── reporte.model.js         # Modelo Reporte
│       │   ├── sector.model.js          # Modelo Sector
│       │   └── user.model.js            # Modelo User (Credenciales y perfiles)
│       └── routes/                      # Definición de rutas HTTP v1
│           ├── auditoria.route.js
│           ├── ayudas.route.js
│           ├── censo_records.route.js
│           ├── censos.route.js
│           ├── eventos.route.js
│           ├── habitants.route.js
│           ├── reports.route.js
│           ├── sectores.route.js
│           ├── stats.route.js
│           └── users.route.js
├── lib/                                 # Aplicación cliente Flutter
│   ├── main.dart                        # Punto de entrada de la aplicación Flutter
│   ├── core/                            # Módulo central agnóstico de negocio
│   │   ├── config/
│   │   │   └── menu_item.dart           # Definición del menú de navegación lateral por rol
│   │   ├── di/
│   │   │   └── injection_container.dart # Contenedor de Inyección de Dependencias (GetIt)
│   │   ├── error/
│   │   │   └── failures.dart            # Jerarquía estandarizada de errores/fallos
│   │   ├── network/
│   │   │   └── network_info.dart        # Monitor de conectividad de red a nivel de socket/interface
│   │   ├── router/
│   │   │   ├── app_router.dart          # Configuración de GoRouter con guardias de navegación
│   │   │   └── auth_notifier.dart       # Notificador reactivo del estado de autenticación
│   │   ├── services/
│   │   │   ├── audit_logger_service.dart # Servicio centralizado de auditoría de acciones
│   │   │   ├── hive_config.dart         # Inicializador de Hive local y clave criptográfica AES-256
│   │   │   ├── image_compression_service.dart # Compresión de imágenes antes de envío
│   │   │   ├── mongodb_service.dart     # Cliente de API remota mediante Dio + JWT Bearer
│   │   │   └── sync_manager.dart        # Motor de Sincronización bidireccional en segundo plano
│   │   ├── theme/
│   │   │   ├── app_theme.dart           # Sistema de diseño, tokens de color, tipografía
│   │   │   └── theme_cubit.dart         # Gestor de estado del tema (Modo Claro / Oscuro)
│   │   ├── usecases/
│   │   │   └── usecase.dart             # Interfaz abstracta base para Casos de Uso
│   │   └── utils/
│   │       ├── file_saver.dart          # Exportador abstracto de archivos (Excel/PDF)
│   │       ├── file_saver_mobile.dart   # Implementación móvil de guardado de archivos
│   │       ├── file_saver_stub.dart     # Stub para firmas de plataforma
│   │       ├── file_saver_web.dart      # Implementación Web de descarga de blobs
│   │       └── user_roles_helper.dart   # Ayudante para gestión de roles y lista de operadores
│   ├── shared/                          # Componentes de UI y utilidades compartidas
│   │   ├── helpers/
│   │   │   └── sectores_helper.dart     # Proveedor de sectores y calles de la comunidad
│   │   └── widgets/
│   │       ├── custom_scaffold.dart     # Estructura visual responsive de la app
│   │       ├── side_menu.dart           # Menú lateral dinámico según permisos
│   │       └── sync_status_banner.dart  # Banner flotante de estado de sincronización
│   └── features/                        # Módulos organizados por arquitectura limpia
│       ├── administracion/              # Administración general de usuarios y roles
│       ├── auditar/                     # Visualizador de registros de auditoría del sistema
│       ├── auth/                        # Autenticación, Login y control de sesión
│       ├── ayudas/                      # Gestión y asignación de beneficios sociales
│       ├── censos/                      # Diseñador dinámico de formularios y toma de censo
│       ├── comuna/                      # Mapa estructural de la Comuna y consejos comunales
│       ├── configuracion/               # Perfil de usuario y parámetros del servidor
│       ├── dashboard/                   # Indicadores KPI, gráficos Syncfusion y línea de tiempo
│       ├── estadisticas/                # Reportes analíticos y exportación de datos
│       ├── eventos/                     # Gestión de eventos comunitarios y convocatorias
│       ├── habitants/                   # Padrón de habitantes y control poblacional
│       ├── reports/                     # Denuncias y reportes comunitarios con imágenes
│       └── street_info/                 # Navegador de calles y manzanas comunitarias
├── informe/                             # Directorio de documentación y análisis exhaustivo
├── pubspec.yaml                         # Configuración y dependencias del proyecto Flutter
├── README.md                            # Documentación general de bienvenida
└── database_implementation_guide.md     # Guía original de la base de datos
```

---

## 4. PATRÓN ARQUITECTÓNICO: CLEAN ARCHITECTURE + BLOC / RIVERPOD

La aplicación Flutter se rige rigurosamente bajo los principios de **Clean Architecture** dividida en tres capas concéntricas claramente delimitadas para garantizan la prueba unitaria, la mantenibilidad y la independencia de frameworks.

```mermaid
graph TD
    subgraph Capa de Presentación (Presentation Layer)
        UI[Páginas / Pages & Modales]
        BLoC[BLoC / Cubit / Notifier]
    end

    subgraph Capa de Dominio (Domain Layer)
        UC[Casos de Uso / UseCases]
        Entities[Entidades / Entities]
        RepoInt[Interfaz Repositorio / Repository Interfaces]
    end

    subgraph Capa de Datos (Data Layer)
        RepoImpl[Implementación Repositorio / Repository Impl]
        LocalDS[Fuente de Datos Local - Hive]
        RemoteDS[Fuente de Datos Remota - Dio MongoDB API]
    end

    UI -->|Despacha Eventos| BLoC
    BLoC -->|Emite Estados| UI
    BLoC -->|Invoca| UC
    UC -->|Consulta| RepoInt
    RepoImpl ..->|Implementa| RepoInt
    RepoImpl -->|Cae a Local por defecto| LocalDS
    RepoImpl -->|Sincroniza cuando hay Red| RemoteDS
    LocalDS --> Entities
    RemoteDS --> Entities
```

### Explicación de Capas:

1. **Capa de Dominio (`domain`)**: Es el núcleo de la lógica de negocio pura. Contiene:
   - **Entities**: Objetos de negocio puros inmutables (ej. `Habitante`, `Reporte`, `User`, `Censo`).
   - **UseCases**: Clases de un solo propósito que ejecutan una acción de negocio específica (ej. `AddHabitante`, `CreateReport`, `Login`).
   - **Repository Interfaces**: Contratos abstractos que definen qué operaciones de datos existen sin saber cómo o dónde se almacenan.

2. **Capa de Datos (`data`)**: Se encarga del acceso a la infraestructura física. Contiene:
   - **Models**: Extensiones de las Entidades de dominio que agregan métodos de serialización `toJson()`, `fromJson()`, `fromEntity()`, y adaptadores de Hive (`@HiveType`).
   - **Data Sources**: Fuentes de datos de bajo nivel (`AuthLocalDataSource`, `HabitantsLocalDataSource`, `MongoDBService`).
   - **Repository Implementations**: Lógica que decide si se lee/escribe localmente en Hive o se consulta el API remoto a través de `MongoDBService` basándose en el estado de red reportado por `NetworkInfo`.

3. **Capa de Presentación (`presentation`)**: Interfaz de usuario e interacción. Contiene:
   - **BLoC / Notifiers**: Gestores de estado reactivos que reciben `Events`, procesan la lógica mediante Casos de Uso y emiten `States` inmutables.
   - **Pages & Widgets**: Componentes visuales construidos con Flutter Material 3 que reaccionan a los cambios de estado (`BlocBuilder`, `BlocConsumer`, `ConsumerWidget`).

---

## 5. FLUJO DE DATOS GLOBAL Y FUNCIONALIDAD OFFLINE-FIRST

El pilar fundamental de Comuniapp es su capacidad de funcionar al **100% sin conexión a Internet**.

1. **Operación de Escritura Local (Offline)**:
   - Cuando un usuario registra un habitante, crea un reporte o llena un censo, el repositorio almacena inmediatamente el registro en la caja local correspondiente de **Hive** (cifrada con AES-256).
   - El campo `isSynced` del modelo se establece en `false` (o `0`).
   - La interfaz de usuario recibe la confirmación instantánea sin esperar latencias de red.

2. **Detección de Red y Sincronización Automática (Online)**:
   - El servicio `SyncManager` mantiene un listener activo sobre la interfaz de red mediante `connectivity_plus`.
   - Tan pronto como el dispositivo detecta conexión Wi-Fi, Ethernet o datos móviles, `SyncManager` activa el ciclo de sincronización en segundo plano.
   - Examina secuencialmente todos los registros con `isSynced == false` en las cajas de habitantes, reportes, censos, registros de censos, eventos y auditoría.
   - Envía las peticiones HTTP POST/PUT al servidor Node.js/MongoDB a través de `MongoDBService` incluyendo el encabezado de autorización JWT.
   - Al recibir una respuesta HTTP `200 OK` o `201 Created`, el registro local se marca como `isSynced = true`.
   - Se notifica a la UI actualizando el `SyncStatusBanner` de estado "Sincronizando..." a "Base de datos sincronizada".

---

## 6. ÍNDICE DE ARCHIVOS DEL INFORME COMPLETO

Para consultar las explicaciones detalladas y sin omisiones, remítase a los siguientes archivos contenidos dentro de esta carpeta `informe/`:

* **`01_LIBRERIAS_Y_DEPENDENCIAS_DETALLADAS.md`**: Análisis de cada librería de Flutter y Node.js.
* **`02_PROTOCOLOS_DE_SEGURIDAD_RED_Y_CONEXION.md`**: Explicación técnica de JWT, Bcrypt, Hive AES-256, Secure Storage, Helmet, Rate-Limiting, Mongo Sanitize, CORS y SyncManager.
* **`03_ANALISIS_CORE_Y_SHARED_SISTEMA.md`**: Desglose línea por línea y función por función de los componentes en `lib/core` y `lib/shared`.
* **`04_ANALISIS_BACKEND_NODEJS_EXPRESS_MONGODB.md`**: Desglose completo del servidor Express, modelos Mongoose, controladores y rutas HTTP.
* **`05_ANALISIS_FEATURES_FRONTEND_PARTE1.md`**: Análisis profundo de los módulos `auth`, `habitants`, `reports` y `censos`.
* **`06_ANALISIS_FEATURES_FRONTEND_PARTE2.md`**: Análisis profundo de los módulos `ayudas`, `auditoria`, `eventos`, `configuracion`, `dashboard`, `comuna`, `street_info`, `administracion` y `estadisticas`.
* **`07_MANUAL_DE_DESPLIEGUE_MANTENIMIENTO_Y_OPERACION.md`**: Guía paso a paso de compilación, despliegue en servidor Render.com, configuración de MongoDB Atlas y mantenimiento preventivo.
