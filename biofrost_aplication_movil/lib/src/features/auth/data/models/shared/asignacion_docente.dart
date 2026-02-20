import 'package:json_annotation/json_annotation.dart';

part 'asignacion_docente.g.dart';

/// Modelo que representa la asignación de un docente a una materia
/// en grupos específicos de una carrera.
///
/// Debe coincidir exactamente con AsignacionDocente.cs del backend.
@JsonSerializable(includeIfNull: false)
class AsignacionDocente {
  const AsignacionDocente({
    required this.carreraId,
    required this.materiaId,
    required this.gruposIds,
  });

  /// ID de la carrera donde el docente imparte clases
  @JsonKey(name: 'CarreraId')
  final String carreraId;

  /// ID de la materia que imparte el docente
  @JsonKey(name: 'MateriaId')
  final String materiaId;

  /// Lista de IDs de grupos donde imparte esta materia
  @JsonKey(name: 'GruposIds')
  final List<String> gruposIds;

  factory AsignacionDocente.fromJson(Map<String, dynamic> json) =>
      _$AsignacionDocenteFromJson(json);

  Map<String, dynamic> toJson() => _$AsignacionDocenteToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsignacionDocente &&
          runtimeType == other.runtimeType &&
          carreraId == other.carreraId &&
          materiaId == other.materiaId &&
          gruposIds == other.gruposIds;

  @override
  int get hashCode =>
      carreraId.hashCode ^ materiaId.hashCode ^ gruposIds.hashCode;

  @override
  String toString() =>
      'AsignacionDocente(carreraId: $carreraId, '
      'materiaId: $materiaId, gruposIds: $gruposIds)';
}
