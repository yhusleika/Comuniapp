# Guía de Implementación: Flujo de Datos y Conexión con MongoDB Atlas

Este documento detalla paso a paso cómo la aplicación Comuniapp maneja actualmente el guardado de datos locales usando Hive, y provee la ruta de trabajo (roadmap) exacta para enlazar este flujo con tu base de datos central en MongoDB Atlas.

## Fase 1: Entendiendo el Guardado Local (Hive)

Actualmente, el código de la aplicación ya tiene implementada la lógica para guardar datos de manera local (offline). Entender este flujo es crucial, ya que tu backend recibirá los datos exactamente de esta manera.

El flujo de guardado sigue la estructura de **Clean Architecture**:

1. **La Interfaz de Usuario (UI):** El usuario llena un formulario (por ejemplo, para agregar un Habitante) y presiona "Guardar".
2. **El Gestor de Estado (Bloc/Cubit):** La UI envía un evento al `Bloc` (ej. `AddHabitanteEvent`).
3. **El Caso de Uso (UseCase):** El Bloc llama a un caso de uso (ej. `SaveHabitanteUseCase`), que encapsula la regla de negocio.
4. **El Repositorio (`HabitantsRepositoryImpl`):** El caso de uso le pasa el objeto de datos (modelo) al repositorio. El repositorio es el cerebro que decide qué hacer. En este caso, su primera tarea siempre es guardarlo localmente, y además, lo marca como `isSynced = false`.
5. **El Origen de Datos Local (`HabitantsLocalDataSourceImpl`):**
   - El repositorio llama al Local Data Source.
   - Aquí entra **Hive**. Se abre la "caja" (box) correspondiente: `Hive.openBox(HiveConfig.habitantsBox)`.
   - Se guarda el registro usando una llave única (ID): `await box.put(habitante.id, habitante);`.

> [!NOTE]
> Todo este flujo (Puntos 1 al 5) ya funciona en la aplicación. Si apagas el internet del teléfono o emulador y guardas un registro, este se guardará exitosamente en el disco duro del dispositivo.

---

## Fase 2: El Puente hacia la Nube (`SyncManager`)

Una vez que el dato está en el teléfono (marcado como `isSynced: false`), la aplicación necesita enviarlo a tu servidor. Aquí entra el **SyncManager**.

1. **Detección de Red:** El `SyncManager` escucha constantemente los cambios de red.
2. **Disparo:** Cuando detecta conexión a internet (Wifi o Datos), ejecuta la función `syncData()`.
3. **Lectura Local:** Le pide al repositorio: "Dame todos los registros donde `isSynced == false`".
4. **Envío a la API (`MongoDBService`):** Por cada registro pendiente, llama a `mongoDBService.createRecord()`, pasándole el dato convertido a formato JSON (`model.toJson()`).
5. **Confirmación:** Si la API responde con éxito (HTTP 200/201), el `SyncManager` actualiza el registro en Hive, cambiándolo a `isSynced: true`. 

---

## Fase 3: Tu Trabajo (Conexión real a MongoDB Atlas)

Actualmente, el paso 4 y 5 de la Fase 2 están **simulados**. La aplicación hace creer que lo envía, pero en realidad un "Mock Interceptor" bloquea la petición y responde "Éxito" automáticamente. 

Para que los datos lleguen a MongoDB Atlas, estos son los pasos exactos que llevaremos a cabo:

### Paso 1: Levantar tu Backend (API REST)
Dado que los móviles no deben conectarse a Atlas directamente con el driver por motivos de seguridad, debes programar un servidor intermedio.
- **Tecnología Sugerida:** Node.js (Express o NestJS), Python (FastAPI o Django), o Dart (Dart Frog).
- **Conexión:** Este backend usará el URI de conexión de tu cluster de MongoDB Atlas (ej. `mongodb+srv://usuario:password@cluster0.mongodb.net/comuniapp?retryWrites=true&w=majority`).
- **Definición de Endpoints:** Deberás crear rutas que reciban peticiones JSON. Según el código actual (`MongoDBService`), la app espera hacer llamadas como:
  - `POST /habitants` (Recibe el JSON del habitante en el body).
  - `POST /reports`
  - `POST /censos`
  - `POST /censo_records`
- **Lógica de Base de Datos:** Cuando tu API reciba el `POST`, insertará o actualizará (Upsert) el documento en la colección correspondiente de MongoDB Atlas.
- **Respuesta:** Tu API deberá devolver un HTTP 201 (Created) o 200 (OK) con un JSON que idealmente contenga `{"success": true}` para que el `SyncManager` de la app sepa que todo salió bien.

### Paso 2: Desvincular el Mock en la App
Una vez que tu API esté viva y corriendo (ya sea localmente en tu red o desplegada en un servidor en la nube):
1. Iremos al archivo [mongodb_service.dart](file:///c:/Users/Altph4/Desktop/comuniapp/lib/core/services/mongodb_service.dart).
2. Borraremos todo el bloque `_dio.interceptors.add(...)` que actualmente finge la conexión.
3. Cambiaremos el `baseUrl: 'https://api.comuniapp.org/v1'` a la URL real de tu API (ej. `http://192.168.1.5:3000/v1` para pruebas locales, o `https://tu-api.com/v1` en producción).

### Paso 3: Probar el flujo completo (End-to-End)
1. Iniciar la app sin internet.
2. Crear un Habitante (se guarda en Hive).
3. Encender el internet.
4. El `SyncManager` detectará la red.
5. El `MongoDBService` enviará el `POST /habitants` a tu API.
6. Tu API recibirá la petición y la guardará en MongoDB Atlas.
7. La API responderá a la app.
8. La app marcará el registro como sincronizado.

## Resumen del Plan de Acción
Para comenzar a trabajar, **tu primer objetivo** debe ser desarrollar la API REST (Paso 1). No necesitamos tocar código Flutter hasta que tengas esa API lista para recibir peticiones en formato JSON. Una vez la tengas, haremos el Paso 2 y 3 juntos en el código de la app.
