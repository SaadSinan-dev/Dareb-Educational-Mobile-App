/// Static content paths confirmed by the supplied Postman collection.
enum AccountPageKind { privacyPolicy, termsConditions, aboutApplication }

/// The API returns [value] as text; it may contain HTML (terms currently does).
class AccountPage {
  const AccountPage({required this.id, required this.value});

  const AccountPage.empty() : id = null, value = '';

  final int? id;
  final String value;
}

/// An album and its embedded remote images from GET /galleries/all.
class AccountGallerySummary {
  const AccountGallerySummary({
    required this.id,
    required this.name,
    this.images = const [],
  });

  final int id;
  final String name;
  final List<String> images;
  int get imageCount => images.length;
}

/// Public support details observed at GET /infos/all.
class AccountContactInfo {
  const AccountContactInfo({required this.email, required this.phone});

  final String email;
  final String phone;
}

class AccountFaq {
  const AccountFaq({
    required this.id,
    required this.question,
    required this.answer,
  });

  final int id;
  final String question;
  final String answer;
}
