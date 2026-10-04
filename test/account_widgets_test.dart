import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/profile/presentation/widgets/account_summary.dart';
import 'package:tamkeen2/features/auth/data/unavailable_auth_repository.dart';
import 'package:tamkeen2/features/auth/presentation/auth_cubit.dart';

void main() {
  testWidgets(
    'profile uses the complete design avatar instead of backend image',
    (tester) async {
      final auth = AuthCubit(UnavailableAuthRepository());
      addTearDown(auth.close);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: auth,
            child: Scaffold(
              body: AccountSummary(
                data: const AccountData(
                  profile: AccountProfile(
                    firstName: 'Backend',
                    lastName: 'Name',
                    school: 'School',
                    imageUrl: 'https://example.test/backend-avatar.png',
                  ),
                ),
                onPhotoTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Image && widget.image is NetworkImage,
        ),
        findsNothing,
      );
      final avatar = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/images/avatar.png',
      );
      expect(
        tester.widget<Image>(avatar).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'asset',
          'assets/images/avatar.png',
        ),
      );
      expect(tester.widget<Image>(avatar).fit, BoxFit.contain);
      expect(tester.getSize(avatar), const Size(190, 166));
      expect(
        find.ancestor(of: avatar, matching: find.byType(ClipOval)),
        findsNothing,
      );
      expect(find.text('Backend Name'), findsOneWidget);
      await tester.tap(avatar);
      expect(taps, 1);
    },
  );

  testWidgets('profile statistics render the repository values', (
    tester,
  ) async {
    final auth = AuthCubit(UnavailableAuthRepository());
    addTearDown(auth.close);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: auth,
          child: const Scaffold(
            body: AccountSummary(
              data: AccountData(
                summary: AccountSummaryStats(
                  badges: 1,
                  lessons: 2,
                  courses: 3,
                  points: 999,
                  chapters: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('999'), findsOneWidget);
    expect(find.text('22'), findsNothing);
  });
}
