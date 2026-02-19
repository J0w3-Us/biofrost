import 'package:json_annotation/json_annotation.dart';

part 'carrera_read_model.g.dart';

/// ReadModel optimizado para UI. Solo lectura — no reutilizar para escritura (CQRS).
@JsonSerializable()
class CarreraReadModel {
  final String id;
  final String nombre;
  final String nivel;

  const CarreraReadModel({
    required this.id,
    required this.nombre,
    required this.nivel,
  });

  factory CarreraReadModel.fromJson(Map<String, dynamic> json) =>
      _$CarreraReadModelFromJson(json);

  Map<String, dynamic> toJson() => _$CarreraReadModelToJson(this);
}
