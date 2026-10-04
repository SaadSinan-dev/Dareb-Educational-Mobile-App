import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tamkeen2/core/errors/app_failure.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/faq/presentation/faq_cubit.dart';

class _FaqRepository implements AccountContentRepository {
  Completer<List<AccountFaq>> response = Completer<List<AccountFaq>>();

  @override
  Future<List<AccountFaq>> loadFaqs() => response.future;

  @override
  Future<AccountContactInfo> loadContactInfo() => throw UnimplementedError();
  @override
  Future<List<AccountGallerySummary>> loadGallerySummaries() =>
      throw UnimplementedError();
  @override
  Future<AccountPage> loadPage(AccountPageKind kind) =>
      throw UnimplementedError();
}

void main() {
  test('FAQ Cubit shows loading then verified content', () async {
    final repository = _FaqRepository();
    final cubit = FaqCubit(repository);
    final pending = cubit.load();
    expect(cubit.state.status, FaqStatus.loading);
    repository.response.complete(const [
      AccountFaq(id: 1, question: 'Question', answer: 'Answer'),
    ]);
    await pending;
    expect(cubit.state.status, FaqStatus.ready);
    expect(cubit.state.items.single.answer, 'Answer');
    await cubit.close();
  });

  test('FAQ Cubit retains failure and retries', () async {
    final repository = _FaqRepository();
    final cubit = FaqCubit(repository);
    final first = cubit.load();
    repository.response.completeError(const AppFailure.unavailable());
    await first;
    expect(cubit.state.status, FaqStatus.failure);
    expect(cubit.state.error, const AppFailure.unavailable().message);
    repository.response = Completer<List<AccountFaq>>()..complete(const []);
    await cubit.load();
    expect(cubit.state.status, FaqStatus.ready);
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });
}
