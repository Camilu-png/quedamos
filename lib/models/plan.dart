import 'package:cloud_firestore/cloud_firestore.dart';

class Plan {
  final String id;
  final String anfitrionID;
  final String anfitrionNombre;
  final String titulo;
  final String? descripcion;
  final String iconoNombre;
  final String iconoColor;
  final String visibilidad;
  
  // Fecha
  final DateTime? fecha;
  final bool fechaEsEncuesta;
  
  // Hora
  final String? hora;
  final bool horaEsEncuesta;
  
  // Ubicación
  final Map<String, dynamic>? ubicacion;
  final bool ubicacionEsEncuesta;
  
  // Participantes
  final List<String> participantesAceptados;
  final List<String> participantesRechazados;
  
  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime cachedAt;
  final bool isSynced;

  Plan({
    required this.id,
    required this.anfitrionID,
    required this.anfitrionNombre,
    required this.titulo,
    this.descripcion,
    required this.iconoNombre,
    required this.iconoColor,
    required this.visibilidad,
    this.fecha,
    required this.fechaEsEncuesta,
    this.hora,
    required this.horaEsEncuesta,
    this.ubicacion,
    required this.ubicacionEsEncuesta,
    required this.participantesAceptados,
    required this.participantesRechazados,
    required this.createdAt,
    this.updatedAt,
    required this.cachedAt,
    this.isSynced = true,
  });

  // Convert to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'anfitrionID': anfitrionID,
      'anfitrionNombre': anfitrionNombre,
      'titulo': titulo,
      'descripcion': descripcion,
      'iconoNombre': iconoNombre,
      'iconoColor': iconoColor,
      'visibilidad': visibilidad,
      'fecha': fecha?.millisecondsSinceEpoch,
      'fechaEsEncuesta': fechaEsEncuesta ? 1 : 0,
      'hora': hora,
      'horaEsEncuesta': horaEsEncuesta ? 1 : 0,
      'ubicacion': ubicacion != null ? _serializeUbicacion(ubicacion!) : null,
      'ubicacionEsEncuesta': ubicacionEsEncuesta ? 1 : 0,
      'participantesAceptados': participantesAceptados.join(','),
      'participantesRechazados': participantesRechazados.join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  // Create from SQLite Map
  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'] as String,
      anfitrionID: map['anfitrionID'] as String,
      anfitrionNombre: map['anfitrionNombre'] as String,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String?,
      iconoNombre: map['iconoNombre'] as String,
      iconoColor: map['iconoColor'] as String,
      visibilidad: map['visibilidad'] as String,
      fecha: map['fecha'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['fecha'] as int)
          : null,
      fechaEsEncuesta: (map['fechaEsEncuesta'] as int) == 1,
      hora: map['hora'] as String?,
      horaEsEncuesta: (map['horaEsEncuesta'] as int) == 1,
      ubicacion: map['ubicacion'] != null 
          ? _deserializeUbicacion(map['ubicacion'] as String)
          : null,
      ubicacionEsEncuesta: (map['ubicacionEsEncuesta'] as int) == 1,
      participantesAceptados: (map['participantesAceptados'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ?? [],
      participantesRechazados: (map['participantesRechazados'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(map['cachedAt'] as int),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  // Create from Firestore document
  factory Plan.fromFirestore(String docId, Map<String, dynamic> data) {
    return Plan(
      id: docId,
      anfitrionID: data['anfitrionID'] as String? ?? '',
      anfitrionNombre: data['anfitrionNombre'] as String? ?? '',
      titulo: data['titulo'] as String? ?? '',
      descripcion: data['descripcion'] as String?,
      iconoNombre: data['iconoNombre'] as String? ?? 'event',
      iconoColor: data['iconoColor'] as String? ?? 'secondary',
      visibilidad: data['visibilidad'] as String? ?? 'Público',
      fecha: data['fecha'] is Timestamp
          ? (data['fecha'] as Timestamp).toDate()
          : null,
      fechaEsEncuesta: data['fechaEsEncuesta'] as bool? ?? false,
      hora: data['hora'] as String?,
      horaEsEncuesta: data['horaEsEncuesta'] as bool? ?? false,
      ubicacion: _parseUbicacion(data['ubicacion']),
      ubicacionEsEncuesta: data['ubicacionEsEncuesta'] as bool? ?? false,
      participantesAceptados: (data['participantesAceptados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      participantesRechazados: (data['participantesRechazados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      createdAt: data['fecha_creacion'] is Timestamp
          ? (data['fecha_creacion'] as Timestamp).toDate()
          : (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      cachedAt: DateTime.now(),
      isSynced: true,
    );
  }

  // Convert to Map for display (compatible with existing UI)
  Map<String, dynamic> toDisplayMap() {
    return {
      'id': id,
      'planID': id,
      'anfitrionID': anfitrionID,
      'anfitrionNombre': anfitrionNombre,
      'titulo': titulo,
      'descripcion': descripcion,
      'iconoNombre': iconoNombre,
      'iconoColor': iconoColor,
      'visibilidad': visibilidad,
      'fecha': fecha != null ? Timestamp.fromDate(fecha!) : null,
      'fechaEsEncuesta': fechaEsEncuesta,
      'hora': hora,
      'horaEsEncuesta': horaEsEncuesta,
      'ubicacion': ubicacion,
      'ubicacionEsEncuesta': ubicacionEsEncuesta,
      'participantesAceptados': participantesAceptados,
      'participantesRechazados': participantesRechazados,
    };
  }

  Plan copyWith({
    String? id,
    String? anfitrionID,
    String? anfitrionNombre,
    String? titulo,
    String? descripcion,
    String? iconoNombre,
    String? iconoColor,
    String? visibilidad,
    DateTime? fecha,
    bool? fechaEsEncuesta,
    String? hora,
    bool? horaEsEncuesta,
    Map<String, dynamic>? ubicacion,
    bool? ubicacionEsEncuesta,
    List<String>? participantesAceptados,
    List<String>? participantesRechazados,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? isSynced,
  }) {
    return Plan(
      id: id ?? this.id,
      anfitrionID: anfitrionID ?? this.anfitrionID,
      anfitrionNombre: anfitrionNombre ?? this.anfitrionNombre,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      iconoNombre: iconoNombre ?? this.iconoNombre,
      iconoColor: iconoColor ?? this.iconoColor,
      visibilidad: visibilidad ?? this.visibilidad,
      fecha: fecha ?? this.fecha,
      fechaEsEncuesta: fechaEsEncuesta ?? this.fechaEsEncuesta,
      hora: hora ?? this.hora,
      horaEsEncuesta: horaEsEncuesta ?? this.horaEsEncuesta,
      ubicacion: ubicacion ?? this.ubicacion,
      ubicacionEsEncuesta: ubicacionEsEncuesta ?? this.ubicacionEsEncuesta,
      participantesAceptados: participantesAceptados ?? this.participantesAceptados,
      participantesRechazados: participantesRechazados ?? this.participantesRechazados,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Helper methods for serialization
  static String _serializeUbicacion(Map<String, dynamic> ubicacion) {
    final nombre = ubicacion['nombre'] ?? '';
    final latitud = ubicacion['latitud']?.toString() ?? '';
    final longitud = ubicacion['longitud']?.toString() ?? '';
    return '$nombre|$latitud|$longitud';
  }

  static Map<String, dynamic>? _deserializeUbicacion(String serialized) {
    if (serialized.isEmpty) return null;
    final parts = serialized.split('|');
    if (parts.length != 3) return null;
    
    return {
      'nombre': parts[0],
      'latitud': parts[1].isNotEmpty ? double.tryParse(parts[1]) : null,
      'longitud': parts[2].isNotEmpty ? double.tryParse(parts[2]) : null,
    };
  }

  // Parse ubicacion from Firestore (can be String or Map)
  static Map<String, dynamic>? _parseUbicacion(dynamic ubicacion) {
    if (ubicacion == null) return null;
    
    if (ubicacion is Map<String, dynamic>) {
      return ubicacion;
    }
    
    if (ubicacion is String) {
      // Old format: just a string with the location name
      return {
        'nombre': ubicacion,
        'latitud': null,
        'longitud': null,
      };
    }
    
    return null;
  }
}
