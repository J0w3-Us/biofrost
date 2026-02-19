import 'package:json_annotation/json_annotation.dart';

part 'materia_read_model.g.dart';

/// ReadModel optimizado para UI. Solo lectura — no reutilizar para escritura (CQRS).
@JsonSerializable()
class MateriaReadModel {
  final String id;
  final String nombre;
  final String clave;
  final String carreraId;
  final int cuatrimestre;
  final bool esAltaPrioridad;
  final bool activo;

  const MateriaReadModel({
    required this.id,
    required this.nombre,
    required this.clave,
    required this.carreraId,
    required this.cuatrimestre,
    required this.esAltaPrioridad,
    required this.activo,
  });

  factory MateriaReadModel.fromJson(Map<String, dynamic> json) =>
      _$MateriaReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$MateriaReadModelToJson(this);
}
