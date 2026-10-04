import 'package:flutter/material.dart';

import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/core/config/asset_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAssetLicenses();
  configureDependencies();
  runApp(const LearningApp());
}
