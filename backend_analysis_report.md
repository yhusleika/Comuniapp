# Análisis del Backend y Base de Datos - Comuniapp

A continuación, se presenta un informe detallado sobre cómo está estructurado el manejo de datos y la comunicación con el backend en el proyecto actual. Esto te servirá como base sólida para levantar y configurar la base de datos central en MongoDB Atlas.

## 1. Arquitectura General (Offline-First)

El proyecto utiliza un enfoque arquitectónico **Offline-First**. Esto significa que la aplicación está diseñada para funcionar sin problemas sin conexión a internet, guardando toda la información localmente primero. 

El flujo de datos principal es el siguiente:
1. El usuario interactúa con la app y genera/modifica datos (ej. censos, habitantes, reportes).
2. Los datos se guardan **siempre** primero en la base de datos local (**Hive**).
3. Un administrador de sincronización (`SyncManager`) monitorea la conexión a internet.
4. Cuando hay conexión, se envían los datos pendientes al backend (REST API) que a su vez los guardará en **MongoDB Atlas**.

## 2. Base de Datos Local: Hive

Hive es el motor de base de datos local (NoSQL y muy rápido) usado en el proyecto. 
Puedes encontrar la configuración principal en [hive_config.dart](file:///c:/Users/Altph4/Desktop/comuniapp/lib/core/services/hive_config.dart).

### Entidades y Cajas (Boxes) definidas:
La app divide la información local en las siguientes "cajas" (equivalentes a colecciones/tablas):
- `user_session`: Para almacenar los datos de la sesión del usuario autenticado.
- `habitants`: Colección de habitantes de la comunidad.
- `reports`: Reportes o incidencias.
- `ayudas_types`: Catálogo de tipos de ayudas.
- `censos`: Definición de las campañas de censos.
- `censo_records`: Los registros individuales o encuestas completadas para un censo.
- `sync_queue`: (Mencionada en la configuración, posiblemente pensada para encolar transacciones futuras).

Cada una de estas cajas está respaldada por un modelo de datos específico en las carpetas de `features` (ej. `HabitanteModel`, `ReporteModel`), los cuales están adaptados para serializarse en Hive.

## 3. Conexión al Backend y MongoDB Atlas

La comunicación con la base de datos remota no se hace a través de un driver directo a MongoDB desde el móvil (lo cual es una buena práctica de seguridad), sino a través de una **API REST**.

### El Servicio HTTP (`MongoDBService`)
Ubicado en [mongodb_service.dart](file:///c:/Users/Altph4/Desktop/comuniapp/lib/core/services/mongodb_service.dart).
- Utiliza la librería **Dio** para realizar peticiones HTTP.
- **URL Base Actual:** `https://api.comuniapp.org/v1`.
- **Rutas esperadas:** El servicio está configurado para realizar operaciones CRUD básicas directamente usando el nombre de la colección. Por ejemplo:
  - `POST /habitants` (Crear habitante)
  - `PUT /reports/{id}` (Actualizar reporte)
  - `GET /censos` (Obtener censos)
  - `DELETE /habitants/{id}` (Eliminar)

> [!WARNING]
> **ESTADO ACTUAL: API Simulada (Mock)**
> Actualmente, en `mongodb_service.dart`, el cliente de Dio tiene un *interceptor mockeado*. Esto significa que **las peticiones a internet están siendo interceptadas y simuladas localmente**. El código retrasa la respuesta 300ms y devuelve un HTTP 200/201 exitoso sin hacer la llamada real. 
> 
> **Tu tarea principal:** Al levantar el backend en Node.js, Python o el lenguaje que elijas para conectar con tu cluster de MongoDB Atlas, deberás eliminar este interceptor (`_dio.interceptors.add(...)` en las líneas 13-35 de `mongodb_service.dart`) para que la app apunte a tu API real.

## 4. Administrador de Sincronización (`SyncManager`)

Ubicado en [sync_manager.dart](file:///c:/Users/Altph4/Desktop/comuniapp/lib/core/services/sync_manager.dart).
Este archivo es el puente entre Hive y MongoDB.

- **Monitoreo de Red:** Usa `connectivity_plus` para escuchar cambios en la red (Wifi, Datos móviles).
- **Lógica de Sincronización:** Cuando detecta conexión, ejecuta la función `syncData()`.
- **Entidades actuales soportadas en la sincronización:** 
  Actualmente, el código tiene implementada explícitamente la lógica para sincronizar **Habitantes** (`_syncHabitants()`) y **Reportes** (`_syncReports()`).
- **Mecanismo:**
  1. Consulta a la base de datos local (Hive) por registros que tengan un estado "no sincronizado".
  2. Envía esos registros a través de `MongoDBService` (la API).
  3. Si la respuesta es exitosa (`success: true`), marca el registro local en Hive como "sincronizado" para no volver a enviarlo.

## 5. Resumen de lo que necesitas implementar para el Backend

Para que la base de datos central en MongoDB Atlas funcione con esta aplicación, necesitarás:

1. **Crear una API REST**: (Ej: con Express.js, NestJS, o Python/FastAPI) que se conecte a tu cluster de MongoDB Atlas mediante el driver oficial (`mongodb` o Mongoose/Motor).
2. **Definir los Endpoints Base**: La API debe recibir peticiones en el formato `/{colección}` (ej. `/habitants`, `/reports`, `/censos`, `/censo_records`).
3. **Manejar la Lógica de Inserción/Actualización**: La API debe recibir los JSON enviados por la app y guardarlos en las colecciones correspondientes de Atlas.
4. **Respuesta Estándar**: La app espera que el backend responda con un formato JSON similar a este en caso de éxito:
   ```json
   {
     "success": true,
     "message": "Mensaje descriptivo",
     "data": { ... } 
   }
   ```
5. **Ajustar la App**: Eliminar el Mock en `mongodb_service.dart` y cambiar la `baseUrl` para que apunte a la IP/Dominio de tu nuevo backend real.

## Conclusión
La arquitectura del lado del cliente está bastante estructurada y pensada para manejar la falta de conexión. Tu trabajo se centrará principalmente en crear la capa API REST que reciba estos datos y los persista finalmente en tu cluster de MongoDB Atlas, manteniendo los esquemas (JSON) que ya están definidos en los modelos locales de la aplicación.
