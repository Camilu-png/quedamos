import 'dart:convert';
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
  final List<Map<String, dynamic>>? fechasEncuesta;
  
  // Hora
  final String? hora;
  final bool horaEsEncuesta;
  final List<Map<String, dynamic>>? horasEncuesta;
  
  // Ubicación
  final Map<String, dynamic>? ubicacion;
  final bool ubicacionEsEncuesta;
  final List<Map<String, dynamic>>? ubicacionesEncuesta;
  
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
    this.fechasEncuesta,
    this.hora,
    required this.horaEsEncuesta,
    this.horasEncuesta,
    this.ubicacion,
    required this.ubicacionEsEncuesta,
    this.ubicacionesEncuesta,
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
      'fechasEncuesta': fechasEncuesta != null ? jsonEncode(
        fechasEncuesta!.map((item) => {
          'fecha': item['fecha'] is DateTime 
            ? (item['fecha'] as DateTime).millisecondsSinceEpoch
            : item['fecha'],
          'votos': item['votos'] ?? [],
        }).toList()
      ) : null,
      'hora': hora,
      'horaEsEncuesta': horaEsEncuesta ? 1 : 0,
      'horasEncuesta': horasEncuesta != null ? jsonEncode(
        horasEncuesta!.map((item) => {
          'hora': item['hora'] ?? '',
          'votos': item['votos'] ?? [],
        }).toList()
      ) : null,
      'ubicacion': ubicacion != null ? _serializeUbicacion(ubicacion!) : null,
      'ubicacionEsEncuesta': ubicacionEsEncuesta ? 1 : 0,
      // Store survey location options in local DB under a different column
      'ubicacionesOpciones': ubicacionesEncuesta != null ? jsonEncode(
        ubicacionesEncuesta!.map((item) => {
          'ubicacion': item['ubicacion'] ?? {},
          'votos': item['votos'] ?? [],
        }).toList()
      ) : null,
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
      fechasEncuesta: map['fechasEncuesta'] != null
        ? List<Map<String, dynamic>>.from(
            jsonDecode(map['fechasEncuesta'] as String)
                .map((e) {
                  final item = Map<String, dynamic>.from(e);
                  // Convert fecha milliseconds back to DateTime
                  if (item['fecha'] is int) {
                    item['fecha'] = DateTime.fromMillisecondsSinceEpoch(item['fecha'] as int);
                  }
                  return item;
                }))
        : [],
      hora: map['hora'] as String?,
      horaEsEncuesta: (map['horaEsEncuesta'] as int) == 1,
      horasEncuesta: map['horasEncuesta'] != null
        ? List<Map<String, dynamic>>.from(
            jsonDecode(map['horasEncuesta'] as String)
                .map((e) => Map<String, dynamic>.from(e)))
        : [],
      ubicacion: map['ubicacion'] != null 
          ? _deserializeUbicacion(map['ubicacion'] as String)
          : null,
      ubicacionEsEncuesta: (map['ubicacionEsEncuesta'] as int) == 1,
      // Read local DB column 'ubicacionesOpciones' and present as ubicacionesEncuesta
      ubicacionesEncuesta: map['ubicacionesOpciones'] != null
        ? List<Map<String, dynamic>>.from(
            jsonDecode(map['ubicacionesOpciones'] as String)
                .map((e) => Map<String, dynamic>.from(e)))
        : [],
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
    // Parse fechasEncuesta if present
    List<Map<String, dynamic>>? fechasEncuestaList;
    if (data['fechasEncuesta'] is List) {
      final rawList = data['fechasEncuesta'] as List<dynamic>;
      fechasEncuestaList = rawList.map<Map<String, dynamic>>((item) {
        if (item is! Map) return {};
        final itemMap = Map<String, dynamic>.from(item);
        
        // Convert fecha if it's a Timestamp
        if (itemMap['fecha'] is Timestamp) {
          itemMap['fecha'] = (itemMap['fecha'] as Timestamp).toDate();
        }
        
        return itemMap;
      }).toList();
    }

    // Parse horasEncuesta if present
    List<Map<String, dynamic>>? horasEncuestaList;
    if (data['horasEncuesta'] is List) {
      final rawList = data['horasEncuesta'] as List<dynamic>;
      horasEncuestaList = rawList.map<Map<String, dynamic>>((item) {
        if (item is! Map) return {};
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    // Parse ubicacionesEncuesta if present
    List<Map<String, dynamic>>? ubicacionesEncuestaList;
    if (data['ubicacionesEncuesta'] is List) {
      final rawList = data['ubicacionesEncuesta'] as List<dynamic>;
      ubicacionesEncuestaList = rawList.map<Map<String, dynamic>>((item) {
        if (item is! Map) return {};
        return Map<String, dynamic>.from(item);
      }).toList();
    }

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
      fechasEncuesta: fechasEncuestaList,
      hora: data['hora'] as String?,
      horaEsEncuesta: data['horaEsEncuesta'] as bool? ?? false,
      horasEncuesta: horasEncuestaList,
      ubicacion: _parseUbicacion(data['ubicacion']),
      ubicacionEsEncuesta: data['ubicacionEsEncuesta'] as bool? ?? false,
      ubicacionesEncuesta: ubicacionesEncuestaList,
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
      'fechasEncuesta': fechasEncuesta,
      'hora': hora,
      'horaEsEncuesta': horaEsEncuesta,
      'horasEncuesta': horasEncuesta,
      'ubicacion': ubicacion,
      'ubicacionEsEncuesta': ubicacionEsEncuesta,
      'ubicacionesEncuesta': ubicacionesEncuesta,
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
    List<Map<String, dynamic>>? fechasEncuesta,
    String? hora,
    bool? horaEsEncuesta,
    List<Map<String, dynamic>>? horasEncuesta,
    Map<String, dynamic>? ubicacion,
    bool? ubicacionEsEncuesta,
    List<Map<String, dynamic>>? ubicacionesEncuesta,
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
      fechasEncuesta: fechasEncuesta ?? this.fechasEncuesta,
      hora: hora ?? this.hora,
      horaEsEncuesta: horaEsEncuesta ?? this.horaEsEncuesta,
      horasEncuesta: horasEncuesta ?? this.horasEncuesta,
      ubicacion: ubicacion ?? this.ubicacion,
      ubicacionEsEncuesta: ubicacionEsEncuesta ?? this.ubicacionEsEncuesta,
      ubicacionesEncuesta: ubicacionesEncuesta ?? this.ubicacionesEncuesta,
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
    final direccion = ubicacion['direccion'] ?? nombre;
    final latitud = ubicacion['latitud']?.toString() ?? '';
    final longitud = ubicacion['longitud']?.toString() ?? '';
    return '$nombre|$direccion|$latitud|$longitud';
  }

  static Map<String, dynamic>? _deserializeUbicacion(String serialized) {
    if (serialized.isEmpty) return null;
    final parts = serialized.split('|');
    if (parts.length == 4) {
      return {
        'nombre': parts[0],
        'direccion': parts[1].isNotEmpty ? parts[1] : parts[0],
        'latitud': parts[2].isNotEmpty ? double.tryParse(parts[2]) : null,
        'longitud': parts[3].isNotEmpty ? double.tryParse(parts[3]) : null,
      };
    }

    // Backwards compatibility: accept old 3-part format (nombre|lat|long)
    if (parts.length == 3) {
      return {
        'nombre': parts[0],
        'direccion': parts[0],
        'latitud': parts[1].isNotEmpty ? double.tryParse(parts[1]) : null,
        'longitud': parts[2].isNotEmpty ? double.tryParse(parts[2]) : null,
      };
    }

    return null;
  }

  // Parse ubicacion from Firestore (can be String or Map)
  static Map<String, dynamic>? _parseUbicacion(dynamic ubicacion) {
    if (ubicacion == null) return null;
    
    if (ubicacion is Map<String, dynamic>) {
      // Ensure direccion exists (firestore may send only nombre previously)
      if (!ubicacion.containsKey('direccion')) {
        ubicacion['direccion'] = ubicacion['nombre'] ?? '';
      }
      return ubicacion;
    }
    
    if (ubicacion is String) {
      // Old format: just a string with the location name
      return {
        'nombre': ubicacion,
        'direccion': ubicacion,
        'latitud': null,
        'longitud': null,
      };
    }
    
    return null;
  }
}
