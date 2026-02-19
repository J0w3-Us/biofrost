import 'package:json_annotation/json_annotation.dart';

part 'group_read_model.g.dart';

/// ReadModel optimizado para UI. Solo lectura — no reutilizar para escritura (CQRS).
@JsonSerializable()
class GroupReadModel {
  final String id;
  final String nombre;
  final String carrera;
  final String turno;
  final String cicloActivo;
  final bool activo;

  const GroupReadModel({
    required this.id,
    required this.nombre,
    required this.carrera,
    required this.turno,
    required this.cicloActivo,
    required this.activo,
  });

  factory GroupReadModel.fromJson(Map<String, dynamic> json) =>
      _$GroupReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupReadModelToJson(this);
}
