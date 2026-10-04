import 'package:tamkeen2/features/contact/domain/contact_message.dart';

/// Narrow capability of the backend account API used by the contact feature.
abstract interface class ContactRepository {
  Future<ContactResult> submitContact(ContactMessage message);
}
