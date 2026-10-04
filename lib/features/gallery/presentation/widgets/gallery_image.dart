import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

/// Remote gallery media has its own loading/retry UI and never receives tokens.
class GalleryImage extends StatefulWidget {
  const GalleryImage(this.url, {super.key, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  State<GalleryImage> createState() => _GalleryImageState();
}

class _GalleryImageState extends State<GalleryImage> {
  int _attempt = 0;

  @override
  Widget build(BuildContext context) => Image.network(
    widget.url,
    key: ValueKey((widget.url, _attempt)),
    width: double.infinity,
    height: double.infinity,
    fit: widget.fit,
    loadingBuilder: (context, image, progress) => progress == null
        ? image
        : const Center(child: CircularProgressIndicator()),
    errorBuilder: (context, error, stack) => ColoredBox(
      color: context.colors.border,
      child: Center(
        child: IconButton(
          tooltip: context.tr(AppCopy.retryAction),
          icon: Icon(Icons.broken_image_outlined, color: context.colors.muted),
          onPressed: () => setState(() => _attempt++),
        ),
      ),
    ),
  );
}

void showGalleryImage(BuildContext context, String url) => showDialog<void>(
  context: context,
  barrierColor: Colors.black.withValues(alpha: .67),
  builder: (dialogContext) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 18),
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1.1,
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: GalleryImage(url, fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: IconButton(
            tooltip: context.tr(AppCopy.closeAction),
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ],
    ),
  ),
);
