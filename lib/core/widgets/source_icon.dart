import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tamkeen2/core/theme/design_tokens.dart';

/// Only icons verified in their own Figma layer or supplied PNG context.
enum SourceIconName {
  referralFacebook('referral_facebook.png'),
  referralFriend('referral_friend.png'),
  referralSchool('referral_school.png'),
  referralInstagram('referral_instagram.png'),
  referralOther('referral_other.png'),
  contactPhone('contact_phone.png'),
  contactDescription('contact_description.png'),
  profileArrow('profile_arrow.png'),
  registrationMale('registration_male.png'),
  registrationFemale('registration_female.png'),
  registrationSchool('registration_school.png'),
  registrationInstitute('registration_institute.png'),
  registrationScience('registration_science.png'),
  registrationLiterature('registration_literature.png'),
  registrationCommerce('registration_commerce.png'),
  registrationCheck('registration_check.png'),
  notification('iconamoon_notification-thin.svg'),
  edit('lucide_edit.svg'),
  profileCircle('iconoir_profile-circle.svg'),
  cancel('material-symbols_cancel-outline-rounded.svg'),
  arrow('weui_arrow-outlined.svg'),
  faq('profile_faq.png'),
  contact('profile_contact.png'),
  subscription('profile_subscription.png'),
  achievement('profile_achievement.png'),
  about('profile_about.png'),
  privacy('profile_privacy.png'),
  downloads('profile_downloads.png'),
  terms('profile_terms.png'),
  tests('profile_tests.png'),
  profileEdit('profile_edit.png'),
  logout('profile_logout.png');

  const SourceIconName(this.asset);
  final String asset;
}

class SourceIcon extends StatelessWidget {
  const SourceIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = AppIconTokens.standard,
    this.quarterTurns = 0,
  });
  final SourceIconName icon;
  final Color? color;
  final double size;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Colors.black;
    final asset = 'assets/icons/${icon.asset}';
    final filter = ColorFilter.mode(tint, BlendMode.srcIn);
    final visual = icon.asset.endsWith('.svg')
        ? SvgPicture.asset(
            asset,
            width: size,
            height: size,
            colorFilter: filter,
          )
        : ColorFiltered(
            colorFilter: filter,
            child: Image.asset(asset, width: size, height: size),
          );
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox.square(
        dimension: size,
        child: RotatedBox(quarterTurns: quarterTurns, child: visual),
      ),
    );
  }
}
