# 05 - ANÁLISIS DETALLADO DE FEATURES (PARTE 1: AUTH, HABITANTS, REPORTS, CENSOS)

Este documento contiene la disección técnica completa de las primeras cuatro características fundamentales del cliente Flutter de Comuniapp.

---

## 1. FEATURE: AUTENTICACIÓN Y SESIÓN (`lib/features/auth/`)

### 1.1 Estructura del Módulo
```
lib/features/auth/
├── data/
│   ├── datasources/auth_local_data_source.dart
│   ├── models/user_model.dart & user_model.g.dart
│   └── repositories/auth_repository_impl.dart
├── domain/
│   ├── entities/user.dart
│   ├── repositories/auth_repository.dart
│   └── usecases/
│       ├── check_auth_status_usecase.dart
│       ├── login_usecase.dart
│       └── logout_usecase.dart
└── presentation/
    ├── bloc/ (auth_bloc.dart, auth_event.dart, auth_state.dart)
    └── pages/login_page.dart
```

### 1.2 Entidad y Modelo de Datos
* **`User` (Domain Entity)**: Inmutable (`Equatable`). Propiedades: `id`, `username`, `role` (`'admin'`, `'vocero'`, `'operador'`), `nombres`, `apellidos`, `cedula`, `email`, `telefono`, `photoUrl`.
* **`UserModel` (Data Model)**: Extiende `User`. Incluye anotaciones Hive (`@HiveType(typeId: 0)`), adaptador `@HiveAdapter`, y métodos de serialización `fromJson()` / `toJson()`.

### 1.3 Lógica de Negocio y BLoC (`AuthBloc`)
* **Eventos (`AuthEvent`)**:
  - `LoginRequested(username, password)`: Despachado al enviar el formulario de login.
  - `LogoutRequested()`: Limpia la sesión y token JWT guardados.
  - `AuthCheckRequested()`: Se ejecuta al abrir la aplicación para verificar si hay una sesión activa persistida en Hive.
* **Estados (`AuthState`)**:
  - `AuthInitial`: Estado por defecto.
  - `AuthLoading`: Muestra spinner de carga en el botón de login.
  - `AuthAuthenticated(user)`: Usuario validado con éxito. Activa la redirección a `/dashboard`.
  - `AuthUnauthenticated()`: Sin sesión activa. Redirige a `/login`.
  - `AuthFailure(message)`: Muestra mensaje de error en Snackbar si las credenciales son inválidas.

### 1.4 Interfaz de Usuario (`login_page.dart`)
* Construido con diseño responsivo usando tarjetas de glassmorphism sobre un fondo con logotipo institucional de Comuniapp.
* Contiene campos validados para Usuario y Contraseña, botón de visibilidad de contraseña (ojo), e integración con `BlocConsumer<AuthBloc, AuthState>` para reaccionar inmediatamente a los cambios de autenticación.

---

## 2. FEATURE: PADRÓN DE HABITANTES (`lib/features/habitants/`)

### 2.1 Estructura del Módulo
Contiene la gestión integral del padrón electoral y poblacional de la comunidad.

### 2.2 Entidad y Modelo (`Habitante` y `HabitanteModel`)
* **Campos**: `id`, `nombres`, `apellidos`, `cedula`, `fechaNacimiento`, `genero`, `telefono`, `email`, `sector`, `calle`, `casa`, `jefeFamilia` (bool), `cargaFamiliar` (int), `discapacidad` (bool), `enfermedadCronica` (String), `vota` (bool), `isSynced` (bool).
* Registrado en Hive con `typeId: 1`.

### 2.3 Casos de Uso (`domain/usecases/`)
- `GetHabitants`: Retorna el listado completo o filtrado.
- `AddHabitante`: Valida cédula no duplicada e inserta registro local.
- `UpdateHabitante`: Modifica campos de residencia o condición social.
- `DeleteHabitante`: Elimina un habitante con registro previo en auditoría.

### 2.4 Componentes Visuales y Pantallas
* **`habitants_page.dart`**: Pantalla principal. Renderiza la lista con tarjetas avanzadas, indicador de estado de votación/discapacidad, barra de búsqueda en tiempo real, filtro rápido por Sector/Calle y botón de exportación a formato Excel (`.xlsx`).
* **`add_habitante_page.dart`**: Formulario estructurado en secciones: Datos Personales, Ubicación Comunitaria (dropdown dinámico de `SectoresHelper`), Condición Socio-Salud y Estatus Político.
* **`search_habitante_modal.dart`**: Modal de búsqueda rápida por Cédula o Nombre para vinculación rápida en censos o entrega de ayudas.

---

## 3. FEATURE: DENUNCIAS Y REPORTES COMUNITARIOS (`lib/features/reports/`)

### 3.1 Estructura del Módulo
Gestión de incidencias de servicios públicos e infraestructura (Agua, Electricidad, Gas, Vialidad, Salud, Seguridad).

### 3.2 Entidad y Modelo (`Reporte` y `ReporteModel`)
* **Campos**: `id`, `titulo`, `descripcion`, `sector`, `categoria`, `estado` (`'Pendiente'`, `'En Proceso'`, `'Resuelto'`), `imageUrl`, `fecha`, `reportadoPor`, `isSynced`.
* Registrado en Hive con `typeId: 2`.

### 3.3 Flujo de Creación de Reportes (`create_report_page.dart`)
1. El usuario ingresa Título, Descripción, Categoria y Sector.
2. Presiona el botón de cámara/galería.
3. Se invoca `ImageCompressionService.compressImage()` para reducir la foto seleccionada.
4. El reporte se guarda localmente en Hive y se marca para sincronización.

---

## 4. FEATURE: CENSOS POBLACIONALES DINÁMICOS (`lib/features/censos/`)

### 4.1 Diseñador de Formulario Dinámico (`censo_form_builder_modal.dart`)
Permite a los administradores y voceros crear encuestas comunitarias a medida sin necesidad de programar.
* **Tipos de Campo Soportados**: Texto libre, Número entero, Selección única (Radio), Selección múltiple (Checkbox), Fecha.

### 4.2 Toma de Censo en Campo (`censo_record_form_modal.dart`)
Formulario adaptativo que lee la definición de `Censo` y genera dinámicamente las entradas de UI para registrar los datos socioeconómicos de la familia encuestada (`CensoRecord`).

### 4.3 Diccionario de Campos (`censo_fields_dictionary.dart`)
Estandariza los nombres y claves de las preguntas del censo para facilitar análisis estadísticos posteriores (ej. *"¿Cuenta con servicio de gas doméstico directo?"* -> `gas_directo`).
