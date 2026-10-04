import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/home/domain/home_repository.dart';

Widget homeMediaImage(
  BuildContext context,
  HomeMedia media, {
  double? height,
  double? width,
  String semanticLabel = AppCopy.latestNews,
}) {
  Widget fallback() => ColoredBox(
    color: context.colors.softBlue,
    child: SizedBox(
      height: height,
      width: width,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: context.colors.muted,
      ),
    ),
  );
  final uri = Uri.tryParse(media.imageUrl);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return fallback();
  }
  return Image.network(
    uri.toString(),
    height: height,
    width: width,
    fit: BoxFit.cover,
    semanticLabel: context.tr(semanticLabel),
    errorBuilder: (_, _, _) => fallback(),
    loadingBuilder: (_, image, progress) =>
        progress == null ? image : fallback(),
  );
}
