import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:tamkeen2/features/courses/domain/course.dart';

Widget courseAsset(
  String name, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.contain,
}) => Image.asset(
  'assets/$name.png',
  height: height,
  width: width,
  fit: fit,
  errorBuilder: (_, _, _) => SizedBox(height: height, width: width),
);

Widget courseArtwork(
  Course course, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.contain,
}) {
  final uri = Uri.tryParse(course.imageUrl ?? '');
  Widget fallback() => courseAsset(
    'illustrations/teacher',
    height: height,
    width: width,
    fit: fit,
  );
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
    fit: fit,
    semanticLabel: course.title,
    errorBuilder: (_, _, _) => fallback(),
    loadingBuilder: (_, image, progress) =>
        progress == null ? image : fallback(),
  );
}

String subjectAssetName(String category) => switch (category) {
  AppCopy.mathematicsSubject => 'math',
  AppCopy.scienceSubject => 'science',
  _ => 'social',
};
