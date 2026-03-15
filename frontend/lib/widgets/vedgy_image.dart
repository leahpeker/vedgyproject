import 'package:flutter/material.dart';

/// Standardized network image with consistent placeholder and error widgets.
///
/// Wraps [Image.network] with a surface-colored loading placeholder and a
/// broken-image error widget. Use for thumbnails and cards where a
/// determinate progress indicator is not needed.
///
/// For the main photo gallery image (which shows download progress),
/// use [Image.network] directly with a custom [loadingBuilder].
class VedgyImage extends StatelessWidget {
  const VedgyImage({
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    final iconColor = Theme.of(
      context,
    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: placeholderColor,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, err, st) => Container(
        width: width,
        height: height,
        color: placeholderColor,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: (height != null && height! < 100) ? 24 : 48,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
