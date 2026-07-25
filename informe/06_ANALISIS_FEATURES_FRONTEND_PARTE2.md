# 06 - ANÁLISIS DETALLADO DE FEATURES (PARTE 2: AYUDAS, AUDITORÍA, EVENTOS, CONFIGURACIÓN, DASHBOARD, COMUNA, ADMINISTRACIÓN, ESTADÍSTICAS)

Este documento complementa la disección técnica del frontend analizando los nueve módulos de negocio restantes del sistema Comuniapp.

---

## 1. FEATURE: GESTIÓN Y ASIGNACIÓN DE AYUDAS SOCIALES (`lib/features/ayudas/`)

### 1.1 Estructura y Modelado (`AyudaType` y `AyudaTypeModel`)
* **Campos**: `id`, `nombre` (ej. CLAP, Combo Huevo, Gas Bombona 10kg, Medicamentos), `descripcion`, `icono` (String identificador de FontAwesome), `frecuencia` (Mensual, Quincenal, Eventual), `activa` (bool), `fechaUltimaEntrega`, `isSynced`.
* Registrado en Hive con `typeId: 3`.

### 1.2 Componentes Visuales y Modales
* **`ayudas_page.dart`**: Muestra el catálogo de programas sociales activos mediante tarjetas con gradientes visuales, historial de entregas por fecha y estadísticas de alcance poblacional.
* **`ayuda_form_modal.dart`**: Permite a voceros y administradores crear nuevos tipos de beneficios sociales especificando nombre, ícono y frecuencia.
* **`assign_ayuda_modal.dart`**: Modal interactivo para registrar la entrega de una ayuda a una familia o habitante específico, verificando previamente si el beneficiario ya recibió la ayuda en el ciclo actual para evitar entregas duplicadas.

---

## 2. FEATURE: AUDITORÍA Y TRAZABILIDAD DEL SISTEMA (`lib/features/auditoria/`)

### 2.1 Estructura y Modelado (`AuditLog` y `AuditLogModel`)
* **Campos**: `id`, `userId`, `username`, `userRole`, `action` (`'CREATE'`, `'UPDATE'`, `'DELETE'`, `'LOGIN'`, `'LOGOUT'`), `details`, `targetId`, `timestamp`, `isSynced`.
* Registrado en Hive con `typeId: 6`.

### 2.2 Pantalla de Auditoría (`auditoria_page.dart`)
* Exclusiva para usuarios con rol `admin`.
* Renderiza el historial de operaciones de la aplicación utilizando el paquete `timeline_tile`. Cada nodo de la línea de tiempo muestra la foto/nombre del usuario que realizó la acción, el rol con el que operaba, la estampa de tiempo exacta y los detalles técnicos de la modificación realizada.
* Incluye filtros por rango de fechas, tipo de acción y nombre de usuario.

---

## 3. FEATURE: GESTIÓN DE EVENTOS COMUNITARIOS (`lib/features/eventos/`)

### 3.1 Estructura y Modelado (`EventoModel` y `ManagementItem`)
* **Campos**: `id`, `name`, `description`, `date`, `location`, `responsible` (Operador asignado), `status` (`'Planificado'`, `'En Curso'`, `'Finalizado'`), `attendanceCount` (int), `isSynced`.
* Registrado en Hive con `typeId: 7`.

### 3.2 Pantallas (`eventos_page.dart` y `eventos_details_page.dart`)
* **`eventos_page.dart`**: Muestra la agenda comunitaria de asambleas, jornadas de vacunación, venta de gas y reuniones de consejo comunal.
* **`eventos_details_page.dart`**: Muestra el desglose logístico del evento, lista de responsables, contador en tiempo real de asistencia y tareas logísticas.
* **`management_form_modal.dart`**: Modal de creación/edición de actividades con selección de responsable mediante `UserRolesHelper.getOperadores()`.

---

## 4. FEATURE: CONFIGURACIÓN Y PERFIL DE USUARIO (`lib/features/configuracion/`)

### 4.1 Pantalla de Configuración (`configuracion_page.dart`)
* Permite al usuario en sesión:
  1. Modificar sus datos personales (Nombres, Apellidos, Cédula, Correo, Teléfono).
  2. Subir o cambiar su Foto de Perfil (procesada con `image_picker` y `ImageCompressionService`).
  3. Cambiar su Contraseña de acceso (procesada en backend con hashing `bcrypt`).
  4. Consultar el estado de conexión con la API remota (`MongoDBService.baseUrl`).

---

## 5. FEATURE: DASHBOARD E INDICADORES KPI (`lib/features/dashboard/`)

### 5.1 Pantalla Principal (`dashboard_page.dart`)
Es el panel de control central que se despliega tras iniciar sesión. Contiene:
1. **Tarjetas KPI Superiores**:
   - Total Habitantes Registrados.
   - Familias Censadas.
   - Denuncias Pendientes vs Resueltas.
   - Ayudas Entregadas en el Mes.
2. **Medidor Radial (Syncfusion Gauges)**: Muestra gráficamente el porcentaje de cobertura del censo comunitario actual.
3. **Línea de Tiempo Reciente**: Resumen visual de los últimos 5 eventos u operaciones registradas en el sistema.

---

## 6. FEATURES ADICIONALES: COMUNA, CALLES, ADMINISTRACIÓN Y ESTADÍSTICAS

### 6.1 `comuna/` y `street_info/`
* **`comuna_page.dart`**: Muestra la estructura organizativa del Consejo Comunal, vocerías de comités (Agua, Vivienda, Salud, Educación) y delimitación territorial.
* **`street_info_page.dart`**: Navegador geográfico que lista las calles, veredas y manzanas pertenecientes a cada sector, indicando el número de casas y familias residentes por calle.

### 6.2 `administracion/` (`administracion_general_page.dart`)
* Exclusivo para administradores. Permite gestionar las cuentas de usuario de los voceros y operadores de campo, cambiar sus roles de acceso, habilitar/inhabilitar usuarios y restablecer credenciales.

### 6.3 `estadisticas/` (`estadisticas_page.dart`)
* Módulo de inteligencia comunitaria y analítica de datos.
* Renderiza gráficos comparativos de distribución demográfica (edades, género, votantes, personas con discapacidad).
* Ofrece botones de exportación masiva a **PDF** (usando `pdf` y `printing`) y **Excel** (usando `excel` y `file_saver`).
