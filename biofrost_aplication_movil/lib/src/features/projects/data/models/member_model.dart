// MemberDto del backend → MemberModel en Flutter.
class MemberModel {
  const MemberModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.fotoUrl,
  });

  final String id;
  final String nombre;
  final String email;
  final String rol;
  final String? fotoUrl;

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String? ?? '',
      fotoUrl: json['fotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    if (fotoUrl != null) 'fotoUrl': fotoUrl,
  };
}
