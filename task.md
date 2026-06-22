# Integración Completa MongoDB Atlas + Dashboard

## Fase 1: Backend — CRUD completo
- [x] Habitants: agregar PUT/DELETE
- [x] Reports: agregar PUT/DELETE  
- [x] Censos: agregar PUT/DELETE
- [x] CensoRecords: agregar PUT/DELETE
- [x] Ayudas: crear modelo + controller + route (CRUD completo)
- [x] Eventos: crear modelo + controller + route (CRUD completo)
- [x] Stats: endpoint `/v1/stats` para dashboard
- [x] Registrar nuevas rutas en index.js
- [x] Reiniciar backend

## Fase 2: Flutter — Conectar módulos
- [x] Reports: agregar fromJson + descarga remota en getReports()
- [x] Censos: descarga remota en repositorio
- [x] Ayudas: conectar repositorio al backend
- [x] Eventos: reemplazar mock data por llamadas API

## Fase 3: Dashboard dinámico
- [x] Conectar dashboard a endpoint /v1/stats
- [x] Mostrar conteos reales
- [x] Actividad reciente real
