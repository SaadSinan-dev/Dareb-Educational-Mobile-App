import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/errors/failure_message.dart';
import 'package:tamkeen2/features/contact/domain/contact_message.dart';
import 'package:tamkeen2/features/contact/domain/contact_repository.dart';

enum ContactStatus { idle, submitting, preview, success, failure }

class ContactState {
  const ContactState({
    this.actionStatus = ContactStatus.idle,
    this.actionMessage,
  });
  final ContactStatus actionStatus;
  final String? actionMessage;
}

/// Independent action state: sending a message cannot cancel profile loading.
class ContactCubit extends Cubit<ContactState> {
  ContactCubit(this._repository) : super(const ContactState());
  final ContactRepository _repository;
  Future<void> submitContact(ContactMessage message) async {
    if (isClosed || state.actionStatus == ContactStatus.submitting) return;
    final validation = message.validationError;
    if (validation != null) {
      emit(
        ContactState(
          actionStatus: ContactStatus.failure,
          actionMessage: validation,
        ),
      );
      return;
    }
    emit(const ContactState(actionStatus: ContactStatus.submitting));
    try {
      final result = await _repository.submitContact(message);
      if (!isClosed) {
        emit(
          ContactState(
            actionStatus: result.delivered
                ? ContactStatus.success
                : ContactStatus.preview,
            actionMessage: result.message,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          ContactState(
            actionStatus: ContactStatus.failure,
            actionMessage: failureMessage(error),
          ),
        );
      }
    }
  }
}
