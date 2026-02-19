// Payload para POST /api/projects/{id}/members
class AddMemberCommand {
  const AddMemberCommand({
    required this.leaderId,
    required this.emailOrMatricula,
  });

  final String leaderId;
  final String emailOrMatricula;

  bool get isValid =>
      leaderId.trim().isNotEmpty && emailOrMatricula.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
    'leaderId': leaderId,
    'emailOrMatricula': emailOrMatricula.trim(),
  };
}
