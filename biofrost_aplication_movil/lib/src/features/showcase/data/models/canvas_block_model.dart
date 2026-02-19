// Bloque de canvas de un proyecto — mapeado desde CanvasBlock del backend.
// Tipos: text | h1 | h2 | h3 | bullet | todo | image | video | code | quote | divider
class CanvasBlockModel {
  const CanvasBlockModel({
    required this.id,
    required this.type,
    required this.content,
    required this.order,
    this.metadata,
  });

  final String id;
  final String type;
  final String content;
  final int order;
  final Map<String, dynamic>? metadata;

  /// Tipos de contenido textual (aportan descripción legible)
  static const textTypes = {'text', 'h1', 'h2', 'h3', 'quote'};
  static const listTypes = {'bullet', 'todo'};
  static const mediaTypes = {'image', 'video'};

  bool get isText => textTypes.contains(type);
  bool get isList => listTypes.contains(type);
  bool get isMedia => mediaTypes.contains(type);
  bool get isDivider => type == 'divider';
  bool get isCode => type == 'code';

  String? get imageUrl => metadata?['url'] as String?;

  factory CanvasBlockModel.fromJson(Map<String, dynamic> json) {
    return CanvasBlockModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      content: json['content'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'content': content,
    'order': order,
    if (metadata != null) 'metadata': metadata,
  };
}
