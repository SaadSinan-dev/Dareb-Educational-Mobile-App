import 'package:tamkeen2/core/validation/app_validators.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';

class ContactMessage {
  const ContactMessage({
    required this.name,
    required this.lastName,
    required this.phone,
    required this.description,
  });
  final String name;
  final String lastName;
  final String phone;
  final String description;

  String? get validationError {
    if (AppValidators.name(name) != null ||
        AppValidators.name(lastName) != null) {
      return AppCopy.enterFirstAndLastName;
    }
    if (AppValidators.phone(phone) != null) {
      return AppCopy.phoneLengthValidation;
    }
    if (AppValidators.contactMessage(description) != null) {
      return AppCopy.enterMessageDescription;
    }
    return null;
  }
}

class ContactResult {
  const ContactResult({required this.delivered, required this.message});
  final bool delivered;
  final String message;
}
