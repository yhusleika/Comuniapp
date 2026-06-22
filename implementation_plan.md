# Implementación del Módulo de Auditoría (Audit Logs)

El objetivo es reemplazar los datos estáticos de la pantalla de Auditoría por un flujo completo que guarde cada acción realizada por los usuarios tanto en la base de datos local (Hive) como en la nube (MongoDB Atlas).

## User Review Required
> [!IMPORTANT]
> **Punto clave:** Para registrar cada acción, crearé un `AuditLoggerService`. Este servicio será llamado automáticamente desde cada Bloc (por ejemplo, cuando se crea un censo, cuando se edita un reporte, etc.). Tomará el usuario que está logueado en ese momento y enviará el registro a Hive y a MongoDB de forma silenciosa.
> 
> ¿Estás de acuerdo con este enfoque?

## Proposed Changes

### Backend (Node.js)

#### [NEW] backend/src/models/auditoria.model.js
Esquema de Mongoose para guardar: `id` (String único), `user` (String), `role` (String), `action` (String) y `dateTime` (Date).

#### [NEW] backend/src/controllers/auditoria.controller.js
Controladores CRUD básicos (principalmente `POST` para registrar y `GET` para obtener la lista).

#### [NEW] backend/src/routes/auditoria.route.js
Definición de las rutas correspondientes.

#### [MODIFY] backend/src/index.js
Registrar la ruta `/v1/auditoria`.

---

### Frontend (Flutter)

#### [NEW] lib/features/auditoria/domain/
- `entities/audit_log.dart`: Entidad base.
- `repositories/auditoria_repository.dart`: Interfaz del repositorio.
- `usecases/auditoria_usecases.dart`: Casos de uso `GetAuditLogs` y `AddAuditLog`.

#### [NEW] lib/features/auditoria/data/
- `models/audit_log_model.dart`: Modelo Hive (`@HiveType`) con sus métodos `toJson` y `fromJson`.
- `datasources/auditoria_local_data_source.dart`: Operaciones con la caja de Hive (`box<AuditLogModel>`).
- `repositories/auditoria_repository_impl.dart`: Implementación offline-first. Intenta guardar/obtener de MongoDB Atlas y luego persiste en Hive.

#### [NEW] lib/features/auditoria/presentation/bloc/auditoria_bloc.dart
Gestión del estado de la página de auditoría (`AuditoriaLoading`, `AuditoriaLoaded`, etc.).

#### [MODIFY] lib/features/auditoria/presentation/pages/auditoria_page.dart
Conectar la UI con el `AuditoriaBloc` para mostrar la tabla de logs reales.

#### [NEW] lib/core/services/audit_logger_service.dart
Servicio inyectable que encapsulará la lógica de agregar un log fácilmente desde cualquier parte del sistema. Tomará el estado actual del `AuthBloc` para saber qué usuario está ejecutando la acción.

#### [MODIFY] lib/core/di/injection_container.dart
Registrar todo lo nuevo: DataSource, Repository, UseCases, Bloc y `AuditLoggerService`. Registrar la caja de Hive para auditoría.

#### [MODIFY] Múltiples Blocs (Habitants, Reports, Censos, etc.)
Llamar a `sl<AuditLoggerService>().log('Agregó un nuevo habitante')` después de que una operación sea exitosa.

## Verification Plan
1. Crear el backend de auditoría y reiniciar el servidor Node.
2. Inyectar todo en Flutter y levantar la app.
3. Iniciar sesión, realizar una acción (ej. editar un reporte).
4. Navegar a la pantalla de Auditoría y verificar que el log aparezca.
5. Revisar la colección de MongoDB para asegurar que el registro llegó a la nube.
