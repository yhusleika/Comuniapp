# 04 - ANÁLISIS DETALLADO DEL BACKEND (NODE.JS, EXPRESS, MONGODB)

Este documento detalla minuciosamente la arquitectura, modelos, controladores, rutas, middlewares y configuraciones del servidor API RESTful de **Comuniapp** alojado en el directorio `backend/`.

---

## 1. CONFIGURACIÓN Y SERVIDOR PRINCIPAL (`backend/src/index.js`)

### 1.1 `backend/Procfile`
* **Contenido**: `web: node src/index.js`
* **Propósito**: Indica a plataformas de despliegue en la nube (PaaS como Render.com o Heroku) cómo iniciar el proceso del servidor web de producción.

### 1.2 `backend/src/config/db.js`
* **Propósito**: Gestiona la conexión asíncrona a la base de datos distribuida en la nube **MongoDB Atlas**.
* **Lógica de Conexión**: Lee la URI de conexión desde `process.env.MONGODB_URI`. Utiliza Mongoose con `connectDB()`. Si la URI no está configurada, utiliza un fallback a `mongodb://localhost:27017/comuniapp_db` para entornos de desarrollo local. Captura errores de conexión terminando el proceso con `process.exit(1)`.

### 1.3 `backend/src/index.js`
* **Carga de Entorno**: `dotenv.config()` lee el archivo `.env`.
* **Inicialización DB**: Ejecuta `connectDB()`.
* **Bastionado HTTP**:
  1. `app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }))`: Inyecta 11 cabeceras HTTP de seguridad.
  2. `cors({...})`: Filtra peticiones por dominio autorizados en `ALLOWED_ORIGINS`.
  3. `rateLimit({...})`: Límite de 200 solicitudes por 15 minutos por IP (`apiLimiter`).
  4. `mongoSanitize()`: Elimina operadores de inyección NoSQL (`$` y `.`).
  5. `express.json({ limit: '10mb' })`: Soporta payloads JSON de hasta 10 MB para imágenes o lotes masivos.
* **Archivos Estáticos**: `app.use('/uploads', express.static(...))` sirve fotos de perfil e imágenes de denuncia.
* **Rutas HTTP v1**:
  - `/v1/users`: Públicas (`/login`, `/register`) y protegidas (`/profile`).
  - Protegidas con `verifyToken`: `/v1/habitants`, `/v1/reports`, `/v1/censos`, `/v1/censo_records`, `/v1/ayudas`, `/v1/eventos`, `/v1/stats`, `/v1/auditoria`.
* **Health Check**: Endpoint `GET /health` responde `200 OK` con estampa de tiempo UTC para monitoreo Uptime de Render.com.

---

## 2. MIDDLEWARES DE SEGURIDAD Y CONTROL (`backend/src/middleware/`)

### 2.1 `backend/src/middleware/auth.middleware.js`
* **`verifyToken(req, res, next)`**:
  - Extrae el encabezado `Authorization`.
  - Separa el prefijo `Bearer <token>`. Si no existe, retorna HTTP `401 Unauthorized`.
  - Verifica la firma mediante `jwt.verify(token, JWT_SECRET)`.
  - Inyecta el objeto decodificado en `req.user = { id, username, role }` y transfiere el control con `next()`.
  - Si el token está vencido o alterado, retorna HTTP `403 Forbidden`.
* **`authorizeRoles(...allowedRoles)`**:
  - Recibe una lista de roles autorizados (ej. `'admin'`, `'vocero'`).
  - Evalúa si `req.user.role` está presente en dicha lista. Si no coincide, retorna HTTP `403 Forbidden` con el mensaje: *"No tiene permisos para realizar esta acción"*.

### 2.2 `backend/src/middleware/role.middleware.js`
* Middleware complementario para filtros específicos de permisos a nivel de ruta.

---

## 3. MODELOS DE DATOS MONGOOSE (`backend/src/models/`)

### 3.1 `user.model.js` (Colección `users`)
```javascript
{
  id: { type: String, required: true, unique: true },
  username: { type: String, required: true, unique: true },
  role: { type: String, required: true }, // 'admin', 'vocero', 'operador'
  nombres: { type: String, default: '' },
  apellidos: { type: String, default: '' },
  cedula: { type: String, default: '' },
  email: { type: String, default: '' },
  telefono: { type: String, default: '' },
  photoUrl: { type: String, default: '' },
  passwordHash: { type: String, default: '' }
}
```

### 3.2 `habitante.model.js` (Colección `habitants`)
Almacena el registro del padrón poblacional. Incluye campos: `id`, `nombres`, `apellidos`, `cedula`, `fechaNacimiento`, `genero`, `telefono`, `email`, `sector`, `calle`, `casa`, `jefeFamilia`, `cargaFamiliar`, `discapacidad`, `enfermedadCronica`, `vota`, `isSynced`, timestamps.

### 3.3 `reporte.model.js` (Colección `reports`)
Almacena denuncias comunitarias. Campos: `id`, `titulo`, `descripcion`, `sector`, `categoria` (Agua, Electricidad, Gas, Vialidad, Salud, Seguridad, Otros), `estado` (Pendiente, En Proceso, Resuelto), `imageUrl`, `fecha`, `reportadoPor`, `isSynced`, timestamps.

### 3.4 `censo.model.js` y `censo_record.model.js` (Colecciones `censos` y `censo_records`)
* **`censo.model.js`**: Modela la estructura dinámica del formulario de censo (Título, Descripción, FechaInicio, FechaFin, `campos`: Arreglo de preguntas con tipo de campo, opciones y obligatoriedad).
* **`censo_record.model.js`**: Modela la respuesta enviada por una familia encuestada (CensoId, JefeFamilia, Cedula, Sector, IntegrantesCount, Respuestas map/JSON).

### 3.5 `ayuda.model.js` (Colección `ayudas_types`)
Modela los tipos de beneficios sociales distribuibles. Campos: `id`, `nombre`, `descripcion`, `icono`, `frecuencia`, `activa`, `fechaUltimaEntrega`.

### 3.6 `evento.model.js` (Colección `eventos`)
Modela actividades comunitarias. Campos: `id`, `name`, `description`, `date`, `location`, `responsible`, `status` (Planificado, En Curso, Finalizado), `attendanceCount`.

### 3.7 `auditoria.model.js` (Colección `auditoria_logs`)
Modela los registros de auditoría. Campos: `id`, `userId`, `username`, `userRole`, `action` (CREATE, UPDATE, DELETE, LOGIN), `details`, `targetId`, `timestamp`.

### 3.8 `sector.model.js` (Colección `sectores`)
Modela la división territorial de la comunidad. Campos: `id`, `nombre`, `descripcion`, `totalCasas`.

---

## 4. CONTROLADORES RESTFUL (`backend/src/controllers/`)

### 4.1 `auth.controller.js`
* **`register(req, res)`**: Valida entradas, verifica duplicados de `username`, aplica `bcrypt.hash(password, 12)`, guarda el nuevo usuario y retorna HTTP `201` con el Token JWT recién firmado.
* **`login(req, res)`**: Busca el usuario por `username`. Compara contraseñas usando `bcrypt.compare(password, user.passwordHash)`. Si la autenticación es correcta, emite y retorna el Token JWT.

### 4.2 `users.controller.js`
* **`updateProfile(req, res)`**: Actualiza información personal y avatar del usuario autenticado (`req.user.username`). Si se incluye campo `password`, aplica hashing bcrypt con salado de 12 rondas.
* **`getProfile(req, res)`**: Retorna los datos del perfil sin exponer el `passwordHash`.

### 4.3 `habitants.controller.js`
* **`getHabitants`**: Soporta paginación y filtros por sector/calle.
* **`createHabitante`**: Inserción o upsert de habitantes desde sincronización local.
* **`updateHabitante` / `deleteHabitante`**: Modificación y eliminación.

### 4.4 `reports.controller.js`
* Operaciones CRUD para denuncias comunitarias y manejo de cambios de estado (Pendiente -> Resuelto).

### 4.5 `censos.controller.js` y `censo_records.controller.js`
* Creación de encuestas dinámicas y procesamiento masivo de censos poblacionales.

### 4.6 `ayudas.controller.js`, `eventos.controller.js`, `auditoria.controller.js`, `stats.controller.js`
* Controladores dedicados para gestión de beneficios, eventos comunitarios, logs de trazabilidad y métricas agregadas de MongoDB.

---

## 5. RUTA COMPLETA DE ENPOINTS HTTP (API V1 MAP)

| Método | Endpoint | Middleware Protegido | Descripción |
| :--- | :--- | :--- | :--- |
| `POST` | `/v1/users/register` | No (Público) | Registro de nuevos usuarios y emisión de JWT |
| `POST` | `/v1/users/login` | No (Público) | Autenticación de credenciales y retorno de JWT |
| `GET` | `/v1/users/profile/:username` | JWT (`verifyToken`) | Consulta de datos del perfil de usuario |
| `PUT` | `/v1/users/profile` | JWT (`verifyToken`) | Actualización de perfil e imagen de avatar |
| `GET` | `/v1/habitants` | JWT (`verifyToken`) | Obtener padrón poblacional completo o filtrado |
| `POST` | `/v1/habitants` | JWT (`verifyToken`) | Registrar/sincronizar habitante |
| `PUT` | `/v1/habitants/:id` | JWT (`verifyToken`) | Actualizar datos de habitante |
| `DELETE`| `/v1/habitants/:id` | JWT + Admin | Eliminar habitante del padrón |
| `GET` | `/v1/reports` | JWT (`verifyToken`) | Obtener denuncias comunitarias |
| `POST` | `/v1/reports` | JWT (`verifyToken`) | Crear denuncia con imagen adjunta |
| `GET` | `/v1/censos` | JWT (`verifyToken`) | Listar formularios de censos |
| `POST` | `/v1/censos` | JWT (`verifyToken`) | Crear diseñador de censo dinámico |
| `GET` | `/v1/stats` | JWT (`verifyToken`) | Agregaciones estadísticas del dashboard |
| `GET` | `/v1/auditoria` | JWT + Admin | Consultar historial de logs de auditoría |
| `GET` | `/health` | No (Público) | Monitor de Uptime del servidor Render.com |
