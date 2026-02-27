import 'package:flutter/material.dart';

import 'package:biofrost/features/project_detail/widgets/project_video_card.dart';

/// Tarjeta de video pitch mejorada con reproductor nativo
class VideoPitchCard extends StatelessWidget {
  const VideoPitchCard({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    // Alias: reutiliza la nueva ProjectVideoCard para evitar duplicación
    return ProjectVideoCard(
      videoUrl: url,
      projectTitle: 'Video Pitch',
      canvasVideoUrls: const [],
    );
  }
}

// VideoPitchCard es un alias ligero a `ProjectVideoCard`.
