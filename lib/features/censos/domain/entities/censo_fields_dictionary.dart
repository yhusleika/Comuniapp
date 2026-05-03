enum FieldType { text, number, date, dropdown, checkboxList, radio, checkboxListWithQuantity }

class CensoFieldDef {
  final String id;
  final String label;
  final String category;
  final FieldType type;
  final List<String>? options;
  final bool isRequired;

  const CensoFieldDef({
    required this.id,
    required this.label,
    required this.category,
    required this.type,
    this.options,
    this.isRequired = false,
  });
}

class CensoDictionary {
  static const List<CensoFieldDef> fields = [
    // Datos de Identificación del Censo
    CensoFieldDef(
      id: 'no_casa_existente',
      label: 'No. Casa Existente',
      category: 'Datos de Identificación del Censo',
      type: FieldType.number,
    ),
    CensoFieldDef(
      id: 'fecha_identificacion',
      label: 'Fecha',
      category: 'Datos de Identificación del Censo',
      type: FieldType.date,
    ),
    CensoFieldDef(
      id: 'sector',
      label: 'Sector',
      category: 'Datos de Identificación del Censo',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'no_casa_censo',
      label: 'No. Casa Censo',
      category: 'Datos de Identificación del Censo',
      type: FieldType.number,
    ),
    CensoFieldDef(
      id: 'encuesta_n',
      label: 'Encuesta Nº',
      category: 'Datos de Identificación del Censo',
      type: FieldType.number,
    ),
    CensoFieldDef(
      id: 'plano_real',
      label: 'Plano Real',
      category: 'Datos de Identificación del Censo',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'encuestador',
      label: 'Encuestador',
      category: 'Datos de Identificación del Censo',
      type: FieldType.text,
    ),

    // Datos de Personas
    CensoFieldDef(
      id: 'es_jefe_familia',
      label: '¿Es Jefe de Familia?',
      category: 'Datos de Personas',
      type: FieldType.dropdown,
      options: ['Sí', 'No'],
      isRequired: true,
    ),
    CensoFieldDef(
      id: 'jefeFamilia',
      label: 'Nombres y Apellidos',
      category: 'Datos de Personas',
      type: FieldType.text,
      isRequired: true,
    ),
    CensoFieldDef(
      id: 'parentesco',
      label: 'Parentesco',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'cedula',
      label: 'Identidad / Cédula',
      category: 'Datos de Personas',
      type: FieldType.text,
      isRequired: true,
    ),
    CensoFieldDef(
      id: 'lugar_nacimiento',
      label: 'Lugar de Nacimiento',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'fecha_nacimiento',
      label: 'Fecha de Nacimiento',
      category: 'Datos de Personas',
      type: FieldType.date,
    ),
    CensoFieldDef(
      id: 'edad',
      label: 'Edad',
      category: 'Datos de Personas',
      type: FieldType.number,
    ),
    CensoFieldDef(
      id: 'estado_civil',
      label: 'Estado Civil',
      category: 'Datos de Personas',
      type: FieldType.dropdown,
      options: ['Soltero(a)', 'Casado(a)', 'Divorciado(a)', 'Viudo(a)', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'escolaridad',
      label: 'Escolaridad',
      category: 'Datos de Personas',
      type: FieldType.dropdown,
      options: ['Analfabeta', 'Primaria', 'Secundaria', 'Técnica', 'Universitaria', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'profesion_oficio',
      label: 'Profesión u Oficio',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'ocupacion_actual',
      label: 'Ocupación Actual',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'lugar_trabajo',
      label: 'Lugar de Trabajo',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'ingreso_mensual',
      label: 'Ingreso Mensual',
      category: 'Datos de Personas',
      type: FieldType.number,
    ),
    CensoFieldDef(
      id: 'correo',
      label: 'Correo Electrónico',
      category: 'Datos de Personas',
      type: FieldType.text,
    ),

    // Características de la Vivienda
    CensoFieldDef(
      id: 'tipo_vivienda',
      label: 'Tipo de Vivienda',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Casa', 'Apartamento', 'Habitación', 'Rancho', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'tenencia_vivienda',
      label: 'Tenencia',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Propia pagada', 'Propia pagando', 'Propia construida', 'Propia en construcción', 'Alquilada', 'Cedida', 'Compartida', 'Invadida', 'Prestada', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'paredes_exteriores',
      label: 'Materiales - Paredes Exteriores',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Bloque o ladrillo frisado', 'Sin frisar', 'Concreto (prefabricado)', 'Madera', 'Bahareque frisado', 'Sin frisar (Bahareque)', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'techo',
      label: 'Materiales - Techo',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Platabanda', 'Tejas', 'Asbesto', 'Láminas metálicas', 'Caña, Tablas', 'Bolsas', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'pisos',
      label: 'Materiales - Pisos',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Mosaico, Granito', 'Vinil', 'Ladrillos', 'Terracota', 'Parquet', 'Alfombras', 'Cemento', 'Tierra', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'numero_pisos',
      label: 'Estructura (No. Pisos)',
      category: 'Características de la Vivienda',
      type: FieldType.dropdown,
      options: ['1 Piso', '2 Piso', '3 Piso', '4 Piso', 'Más de 4 pisos'],
    ),
    CensoFieldDef(
      id: 'tiempo_residencia',
      label: 'Tiempo de Residencia',
      category: 'Características de la Vivienda',
      type: FieldType.dropdown,
      options: ['1 a 3 años', '4 a 6 años', '7 a 10 años', 'Más años'],
    ),
    CensoFieldDef(
      id: 'numero_familias',
      label: 'Nº Familias en Estructura',
      category: 'Características de la Vivienda',
      type: FieldType.dropdown,
      options: ['1 Familia', '2 Familia', '3 Familia', '4 Familia', 'Más de 4 familias'],
    ),
    CensoFieldDef(
      id: 'distribucion_vivienda',
      label: 'Distribución',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxListWithQuantity, 
      options: ['Dormitorios', 'Cocina', 'Baño', 'Comedor', 'Sala', 'Sala-Comedor', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'donde_duermen',
      label: 'Donde Duermen',
      category: 'Características de la Vivienda',
      type: FieldType.checkboxListWithQuantity,
      options: ['Cama', 'Catre', 'Hamaca', 'Colchón/Colchoneta', 'Litera', 'Suelo', 'Ambos', 'Otro (Mencionar)'],
    ),

    // Servicios de la Vivienda
    CensoFieldDef(
      id: 'servicios_vivienda_agrupados',
      label: 'Servicios de la Vivienda',
      category: 'Servicios de la Vivienda',
      type: FieldType.checkboxList,
      options: [
        'AGUA',
        'ELECTRICIDAD CON MEDIDOR',
        'ELECTRICIDAD SIN MEDIDOR',
        'LINEA TELEF CANTV',
        'CELULAR FIJO',
        'CELULAR'
      ],
    ),
    CensoFieldDef(
      id: 'tenencia_terreno',
      label: 'Tenencia del Terreno',
      category: 'Servicios de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Propio', 'Municipal', 'Privado', 'Otro', 'No sabe'],
    ),
    CensoFieldDef(
      id: 'posee_documento',
      label: 'Posee Documento Legal de Vivienda',
      category: 'Servicios de la Vivienda',
      type: FieldType.dropdown,
      options: ['Si', 'No', 'En trámites', 'No sabe'],
    ),
    CensoFieldDef(
      id: 'tipo_documento',
      label: 'Tipo de Documento',
      category: 'Servicios de la Vivienda',
      type: FieldType.checkboxList,
      options: ['Título Propiedad', 'Título Supletorio', 'Título de Asignación', 'Arrendamiento', 'Otros (Mencionar)'],
    ),

    // Dotación de Servicios
    CensoFieldDef(
      id: 'dotacion_agua',
      label: 'Agua (Origen)',
      category: 'Dotación de Servicios',
      type: FieldType.checkboxList,
      options: ['Intradomiciliario', 'Pila Pública', 'De la calle', 'Camión Cisterna', 'Manantial', 'Manguera', 'Tobo', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'dotacion_electricidad',
      label: 'Electricidad (Origen)',
      category: 'Dotación de Servicios',
      type: FieldType.checkboxList,
      options: ['Instalada', 'Tomada', 'Planta Casera', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'tuberias_aguas_negras',
      label: '1. Tuberías de Aguas Negras',
      category: 'Dotación de Servicios',
      type: FieldType.dropdown,
      options: ['Conectadas a cloacas de la calle', 'Descarga libre al barrio o quebrada', 'No posee tuberías de aguas negras', 'Otras (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'excretas',
      label: '2. Excretas',
      category: 'Dotación de Servicios',
      type: FieldType.dropdown,
      options: ['Poceta a cloaca', 'Pozo séptico', 'Excusado de hoyo', 'Letrina', 'Ninguna (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'recoleccion_basura',
      label: 'Recolección de Basura',
      category: 'Dotación de Servicios',
      type: FieldType.checkboxList,
      options: ['Directa en camiones', 'Relleno Sanitario', 'Acumulada', 'Quemada', 'Container', 'Otro (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'organizaciones_pertenece',
      label: 'Organizaciones a las que perteneces',
      category: 'Dotación de Servicios',
      type: FieldType.checkboxList,
      options: ['Asociación de Vecinos', 'Juntas Comunales', 'Clubes Deportivos', 'Grupos de Rescate', 'Centros Culturales', 'Grupos Religiosos', 'Ninguna'],
    ),

    // Descripción de la Comunidad
    CensoFieldDef(
      id: 'ubicacion_geografica',
      label: 'Ubicación Geográfica de la Vivienda',
      category: 'Descripción de la Comunidad',
      type: FieldType.text,
    ),
    CensoFieldDef(
      id: 'vias_comunicacion',
      label: 'Vías de Comunicación',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Carretera Pavimentada', 'Carretera de Tierra', 'Caminos', 'Veredas', 'Callejones', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'condicion_calles',
      label: 'Condiciones de las Calles',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Pavimentada', 'Granzón', 'Tierra'],
    ),
    CensoFieldDef(
      id: 'medios_transporte',
      label: 'Medios de Transporte',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Jeep', 'Autobuses', 'Camionetas', 'Automóviles', 'Otros (Mencionar)'],
    ),
    CensoFieldDef(
      id: 'recursos_educacional',
      label: 'Recursos Educacionales',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Etapa Pre-escolar', 'Básica', 'Técnica', 'Superior'],
    ),
    CensoFieldDef(
      id: 'recursos_asistencial',
      label: 'Medios Asistenciales',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Dispensario', 'Ambulatorio', 'Módulo Policial', 'Farmacias'],
    ),
    CensoFieldDef(
      id: 'recursos_comercial',
      label: 'Comercio (Abastecimiento)',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Abastos', 'Bodegas', 'Panadería', 'Librerías', 'Ferretería', 'Lavandería'],
    ),
    CensoFieldDef(
      id: 'recursos_recreacion',
      label: 'Recreación y Deporte',
      category: 'Descripción de la Comunidad',
      type: FieldType.checkboxList,
      options: ['Plazas', 'Parques', 'Canchas Deportivas', 'Deportes'],
    ),
    CensoFieldDef(
      id: 'otros_recursos',
      label: 'Otros Recursos',
      category: 'Descripción de la Comunidad',
      type: FieldType.text,
    ),

    // Observaciones
    CensoFieldDef(
      id: 'observaciones',
      label: 'Observaciones',
      category: 'Observaciones',
      type: FieldType.text,
    ),

    // Salud
    CensoFieldDef(
      id: 'salud_discapacidad',
      label: 'Integrantes con Discapacidad',
      category: 'Salud',
      type: FieldType.checkboxList,
      options: ['Intelectual', 'Visual', 'Auditiva', 'Motora', 'Ninguna'],
    ),
    CensoFieldDef(
      id: 'salud_enfermedades',
      label: 'Enfermedades Crónicas',
      category: 'Salud',
      type: FieldType.checkboxList,
      options: ['Hipertensión', 'Diabetes', 'Asma', 'Cardiopatía', 'Cáncer', 'Ninguna'],
    ),
    CensoFieldDef(
      id: 'salud_mujeres_embarazadas',
      label: 'Mujeres en Gestación',
      category: 'Salud',
      type: FieldType.dropdown,
      options: ['0', '1', '2', '3 o más'],
    ),
    CensoFieldDef(
      id: 'salud_requiere_asistencia_medica',
      label: '¿Requiere Asistencia Médica Inmediata?',
      category: 'Salud',
      type: FieldType.dropdown,
      options: ['No', 'Sí (Especifique en observaciones)'],
    ),
  ];

  static Map<String, List<CensoFieldDef>> getCategorizedFields() {
    final Map<String, List<CensoFieldDef>> map = {};
    for (var f in fields) {
      if (!map.containsKey(f.category)) {
        map[f.category] = [];
      }
      map[f.category]!.add(f);
    }
    return map;
  }
}
