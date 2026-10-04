import 'package:tamkeen2/features/assessments/presentation/preview_quiz_cubit.dart';
import 'package:tamkeen2/core/theme/app_theme.dart';
import 'package:tamkeen2/features/auth/presentation/screens/splash_page.dart';
// Reproduce: flutter test tool/capture_visual_audit.dart --dart-define=APP_DEMO_MODE=true
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tamkeen2/app.dart';
import 'package:tamkeen2/core/di/service_locator.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';
import 'package:tamkeen2/features/courses/presentation/course_cubit.dart';
import '../test/support/memory_store.dart';

void main() {
  _VisualAuditBinding();
  testWidgets('capture supplied designs and responsive client states', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'NotoSansArabic',
      )..addFont(rootBundle.load('assets/fonts/NotoSansArabic.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final widths = const String.fromEnvironment(
      'AUDIT_WIDTHS',
      defaultValue: '320,360,390,430,600,768',
    ).split(',').map(double.parse);
    final height = double.parse(
      const String.fromEnvironment('AUDIT_HEIGHT', defaultValue: '932'),
    );
    final textScale = double.parse(
      const String.fromEnvironment('AUDIT_TEXT_SCALE', defaultValue: '1'),
    );
    const routeOnly = bool.fromEnvironment('AUDIT_ROUTE_ONLY');
    const phase = String.fromEnvironment(
      'AUDIT_PHASE',
      defaultValue: 'current',
    );
    final records = <Map<String, Object?>>[];
    final errors = <String>[];
    final boundaryKey = GlobalKey();
    addTearDown(tester.view.reset);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    for (final width in widths) {
      await services.reset();
      configureDependencies(demoMode: true, store: MemoryStore());
      tester.view.devicePixelRatio = 1;
      tester.binding.platformDispatcher.textScaleFactorTestValue = textScale;
      tester.view.physicalSize = Size(width, height);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 16);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 16);
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: const LearningApp()),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).last);
      await tester.runAsync(() async {
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        for (final path in manifest.listAssets().where(
          (path) => path.endsWith('.png'),
        )) {
          await precacheImage(AssetImage(path), context);
        }
      });
      await tester.pumpAndSettle();
      final router = GoRouter.of(context);
      final auth = context.read<AuthCubit>();
      final learning = context.read<CourseCubit>();
      final quiz = context.read<PreviewQuizCubit>();
      Future<void> visit(String path) async {
        router.go(path);
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name, {String? source}) async {
        await tester.pump();
        await tester.pumpAndSettle();
        Object? exception;
        while ((exception = tester.takeException()) != null) {
          errors.add('$name/$width: $exception');
        }
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        void repaint(RenderObject object) {
          object.markNeedsPaint();
          object.visitChildren(repaint);
        }

        repaint(boundary);
        await tester.pump();
        await tester.runAsync(() async {
          final rendered = await boundary.toImage(pixelRatio: 1);
          final bytes = await rendered.toByteData(
            format: ui.ImageByteFormat.png,
          );
          final file = File(
            'build/visual-audit/$phase/${width.toInt()}/$name.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          rendered.dispose();
        });
        records.add({
          'screen': name,
          'source': source,
          'width': width,
          'height': height,
          'textScale': textScale,
          'route': router.routeInformationProvider.value.uri.toString(),
        });
      }

      Future<void> tapText(String text) async {
        final target = find.text(text).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      Future<void> dismissDialog() async {
        final dialog = find.byType(Dialog).last;
        Navigator.of(tester.element(dialog)).pop(false);
        await tester.pumpAndSettle();
      }

      if (routeOnly) {
        await visit('/login');
        await capture('route_login');
        await auth.requestCode('0912345678');
        await visit('/verify');
        await capture('route_otp');
        await auth.verifyCode('1234');
        await tester.pumpAndSettle();
        for (final path in const [
          '/home',
          '/categories',
          '/my-learning',
          '/search',
          '/assessments',
          '/activities',
          '/gallery',
          '/gallery/art',
          '/profile',
          '/profile/edit',
          '/detail/math',
          '/lesson/math/0',
          '/checkout/arabic',
          '/plans',
          '/quiz/math',
          '/notifications',
          '/downloads',
          '/achievements',
          '/faq',
          '/privacy',
          '/terms',
          '/about',
          '/contact',
        ]) {
          await visit(path);
          await capture(
            'route_${path.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').replaceFirst(RegExp(r'^_'), '')}',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await services.reset();
        continue;
      }

      await visit('/login');
      await capture('login', source: 'Log In.png');
      await auth.requestCode('0912345678', forRegistration: true);
      await auth.verifyCode('1234');
      await visit('/register');
      await capture('register_age', source: 'Register-1.png');
      await tapText('التالي');
      await tapText('أنثى');
      await capture('register_gender', source: 'Register.png');
      await tapText('التالي');
      await tapText('صديق');
      await capture('register_referral', source: 'Register-6.png');
      await tapText('التالي');
      await tapText('مدرسة');
      await capture('register_institution', source: 'Register-2.png');
      await tapText('التالي');
      await tapText('بكالوريا علمي');
      await tester.tap(find.byType(DropdownButtonFormField<int>).first);
      await tester.pumpAndSettle();
      await tapText('الفرع التجريبي');
      await capture('register_study', source: 'Register-3.png');
      await tapText('التأكيد');
      await capture('register_details', source: 'Register-5.png');
      final fields = find.byType(TextField);
      final values = ['أحمد', 'النابلسي', 'preview@example.invalid'];
      for (var i = 0; i < 3; i++) {
        await tester.enterText(fields.at(i), values[i]);
      }
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tapText('دمشق');
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tapText('المدرسة التجريبية');
      await tapText('التالي');
      await tapText('قراءة الشروط والأحكام');
      await capture('register_terms', source: 'Register-7.png');
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tapText('إنشاء الحساب');
      await capture('registration_success', source: 'Register-4.png');
      await auth.logout();
      await visit('/login');
      await auth.requestCode('0912345678');
      await visit('/verify');
      await capture('otp', source: 'Reset Password.png');
      await tester.pump(const Duration(seconds: 61));
      await capture('otp_expired', source: 'Reset Password-1.png');
      await auth.verifyCode('1234');
      await tester.pumpAndSettle();
      for (final entry in const <String, List<String>>{
        'home': ['/home', 'Home Page.png'],
        'my_learning': ['/my-learning', 'Home Page-4.png'],
        'assessments': ['/assessments', 'Home Page-7.png'],
        'activities': ['/activities', 'Home Page-8.png'],
        'categories': ['/categories', 'Cateogries page.png'],
        'search': ['/search', 'Cateogries page-6.png'],
        'plans': ['/plans', 'Cateogries page-2.png'],
        'checkout': ['/checkout/plan-year', 'Checkout page.png'],
        'details': ['/detail/math', 'Detail Page.png'],
        'lesson': ['/lesson/math/0', 'Detail Page-6.png'],
        'quiz': ['/quiz/math', 'Quizze Pages.png'],
        'gallery': ['/gallery', 'Gallery Page-2.png'],
        'album': ['/gallery/art', 'Gallery Page.png'],
        'profile': ['/profile', 'Profile Page.png'],
        'profile_edit': ['/profile/edit', 'Profile Page-3.png'],
        'about': ['/about', 'Profile Page-1.png'],
        'contact': ['/contact', 'Profile Page-2.png'],
        'notifications': ['/notifications', 'Notification Page.png'],
        'achievements': ['/achievements', 'My Achievments.png'],
        'faq': ['/faq', 'questions.png'],
        'terms': ['/terms', 'questions-1.png'],
        'privacy': ['/privacy', 'questions-2.png'],
        'logout': ['/logout', 'logout.png'],
      }.entries) {
        await visit(entry.value[0]);
        await capture(entry.key, source: entry.value[1]);
      }
      await visit('/plans');
      await tapText('تفاصيل');
      expect(find.byType(AlertDialog), findsOneWidget);
      await capture('plan_details', source: 'Cateogries page-3.png');
      await dismissDialog();
      await visit('/detail/math');
      await tapText('مقدمة الإحصاء 4');
      expect(find.byType(AlertDialog), findsOneWidget);
      await capture('lesson_intro_dialog', source: 'Detail Page-3.png');
      await dismissDialog();
      await visit('/detail/math');
      await tapText('مقدمة الجبر 4');
      expect(find.text('أكمل الدرس السابق'), findsOneWidget);
      await capture('lesson_prerequisite_dialog', source: 'Detail Page-5.png');
      await dismissDialog();
      await visit('/detail/arabic');
      await tapText('ابدأ التعلم');
      expect(find.text('اشترك الآن واحصل عليه'), findsOneWidget);
      await capture('lesson_subscription_dialog', source: 'Detail Page-4.png');
      await dismissDialog();
      await visit('/home');
      await visit('/detail/math');
      await capture('detail_unwatched', source: 'Detail Page-1.png');
      learning.completeLesson('math', 0);
      await tester.pumpAndSettle();
      await capture('detail_completed', source: 'Detail Page-2.png');
      await visit('/my-learning');
      await tapText('الفصول');
      await capture('my_chapters', source: 'Home Page-5.png');
      await tapText('الباقات');
      await capture('my_plans', source: 'Home Page-6.png');
      learning.selectCategory('الرياضيات');
      await visit('/categories');
      await capture('subject', source: 'Cateogries page-1.png');
      await tapText('اختبارات');
      await capture('subject_quizzes', source: 'Cateogries page-4.png');
      await tapText('نشاطات يومية');
      await capture('subject_activities', source: 'Cateogries page-5.png');
      await visit('/quiz/math');
      quiz.answerQuestion(0, 0);
      quiz.answerQuestion(1, 1);
      quiz.submitQuiz();
      await tester.pumpAndSettle();
      await capture('quiz_result', source: 'Quizze Pages-2.png');
      await visit('/quiz-review');
      await capture('quiz_review', source: 'Quizze Pages-1.png');
      learning.download('math');
      await visit('/downloads');
      await capture('downloads', source: 'download curses.png');
      await visit('/home');
      await tester.drag(find.byType(PageView), const Offset(250, 0));
      await tester.pumpAndSettle();
      await capture('home_banner', source: 'Home Page-1.png');
      await tapText('تفقد حسابك الآن');
      await capture('profile_prompt', source: 'Home Page-3.png');
      await tapText('أكمل');
      await capture('complete_profile', source: 'Home Page-2.png');
      await visit('/gallery/art');
      final firstPhoto = find.byKey(const ValueKey('album-photo-1'));
      await tester.ensureVisible(firstPhoto);
      await tester.tap(firstPhoto);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      await capture('photo_preview', source: 'Gallery Page-1.png');
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(theme: AppTheme.light, home: const SplashPage()),
        ),
      );
      await tester.pumpAndSettle();
      await capture('splash', source: 'Splash screen.png');
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const SplashPage(light: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await capture('splash_light', source: 'Splash screen-1.png');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await services.reset();
    }
    await tester.runAsync(() async {
      await File(
        'build/visual-audit/$phase/metadata.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(records));
      await File(
        'build/visual-audit/$phase/errors.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(errors));
    });
    expect(errors, isEmpty);
  });
}

class _VisualAuditBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get disableShadows => false;
}
