/// Tarjeta de proyecto reutilizable — diseño thumbnail 2-columnas.
///
/// Usada en [ShowcasePage] y [DocenteProjectsPage].
/// Diseño: imagen de portada (60%) + badge PÚBLICO/PRIVADO overlay +
///         título en negrita + dot de estado con label.
library project_card;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:biofrost/core/models/project_read_model.dart';
import 'package:biofrost/core/theme/app_theme.dart';

// ── ProjectCard ───────────────────────────────────────────────────────────

/// Tarjeta de proyecto con thumbnail, badge de visibilidad y dot de estado.
///
/// Apta para grids de 2 columnas (childAspectRatio ≈ 0.72).
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  final ProjectReadModel project;
  final VoidCallback onTap;

  Color get _statusColor {
    switch (project.estado) {
      case 'Completado':
        return AppTheme.success;
      case 'Activo':
        return AppTheme.info;
      default:
        return AppTheme.warning;
    }
  }

  String get _statusLabel {
    switch (project.estado) {
      case 'Completado':
        return 'Completado';
      case 'Activo':
        return 'Activo';
      default:
        return 'Borrador';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        decoration: BoxDecoration(
          color: AppTheme.surface1,
          borderRadius: AppTheme.bLG,
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.shadowCard,
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail + badge overlay ──────────────────────────
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProjectThumbnail(
                    url: project.thumbnailUrl,
                    titulo: project.titulo,
                  ),
                  // Gradiente de fusión inferior
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppTheme.surface1.withAlpha(200),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge visibilidad
                  Positioned(
                    top: AppTheme.sp8,
                    right: AppTheme.sp8,
                    child: ProjectVisibilityBadge(esPublico: project.esPublico),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Título
                    Text(
                      project.titulo,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Status dot + label
                    ProjectStatusDot(
                      color: _statusColor,
                      label: _statusLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ProjectThumbnail ──────────────────────────────────────────────────────

/// Imagen de portada del proyecto con fallback de iniciales y color
/// determinista basado en el título.
class ProjectThumbnail extends StatelessWidget {
  const ProjectThumbnail({
    super.key,
    required this.url,
    required this.titulo,
  });

  final String? url;
  final String titulo;

  /// Color de fondo determinista derivado del título.
  Color get _bgColor {
    final code = titulo.codeUnits.fold(0, (a, b) => a + b);
    const palette = [
      Color(0xFF1A2D1A), // verde oscuro
      Color(0xFF0D1F2D), // azul oscuro
      Color(0xFF2D1A0D), // naranja oscuro
      Color(0xFF1A0D2D), // morado oscuro
      Color(0xFF1F1F0D), // amarillo oscuro
    ];
    return palette[code % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            _ProjectThumbnailPlaceholder(titulo: titulo, color: _bgColor),
        errorWidget: (_, __, ___) =>
            _ProjectThumbnailPlaceholder(titulo: titulo, color: _bgColor),
      );
    }
    return _ProjectThumbnailPlaceholder(titulo: titulo, color: _bgColor);
  }
}

class _ProjectThumbnailPlaceholder extends StatelessWidget {
  const _ProjectThumbnailPlaceholder({
    required this.titulo,
    required this.color,
  });

  final String titulo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = titulo.isNotEmpty
        ? titulo.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : '?';

    return Container(
      color: color,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }
}

// ── ProjectVisibilityBadge ────────────────────────────────────────────────

/// Pill badge "PÚBLICO" / "PRIVADO" para mostrar sobre thumbnails.
class ProjectVisibilityBadge extends StatelessWidget {
  const ProjectVisibilityBadge({super.key, required this.esPublico});

  final bool esPublico;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(160),
        borderRadius: AppTheme.bFull,
        border: Border.all(
          color: esPublico
              ? AppTheme.badgeGreenText.withAlpha(100)
              : AppTheme.border,
        ),
      ),
      child: Text(
        esPublico ? 'PÚBLICO' : 'PRIVADO',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: esPublico ? AppTheme.badgeGreenText : AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── ProjectStatusDot ──────────────────────────────────────────────────────

/// Dot de color + etiqueta de estado del proyecto.
class ProjectStatusDot extends StatelessWidget {
  const ProjectStatusDot({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
