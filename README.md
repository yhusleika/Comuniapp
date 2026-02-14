# Social Management Pro

App de Gestión Social Pro (Offline-First) desarrollada en Flutter con Clean Architecture.

## Características

- **Offline-First**: Base de datos local con Hive.
- **Sincronización**: Cola de sincronización automática con Connectivity Plus.
- **Gestión de Habitantes**: Registro detallado (Salud, Vivienda).
- **Reportes Comunitarios**: Reporte de incidencias con fotos comprimidas.
- **Autenticación**: Login simple con persistencia de sesión.

## Configuración del Proyecto

Debido a que el código utiliza generación de código para Hive (bases de datos) y JSON serialization (si aplica), es necesario ejecutar los siguientes comandos antes de iniciar la app:

1.  **Instalar dependencias**:
    ```bash
    flutter pub get
    ```

2.  **Generar adaptadores de Hive**:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

3.  **Ejecutar la App**:
    ```bash
    flutter run
    ```

## Estructura del Proyecto

- `lib/core`: Componentes compartidos, utilidades, DI, red.
- `lib/features`: Módulos principales (Auth, Habitants, Reports, Dashboard).
- `test`: Pruebas unitarias.

## Notas Adicionales

- Las imágenes se comprimen localmente antes de guardarse para ahorrar espacio.
- La sincronización se activa automáticamente cuando se detecta conexión a internet (WiFi o Datos).
