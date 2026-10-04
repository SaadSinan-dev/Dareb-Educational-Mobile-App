class RemoteAnswer {
  const RemoteAnswer(this.id, this.title, this.correct);
  final String id, title;
  final bool? correct;
}

class RemoteQuestion {
  const RemoteQuestion(this.id, this.title, this.answers);
  final String id, title;
  final List<RemoteAnswer> answers;
}

/// Actual search/result fields. Counters are nullable until the server sends
/// them; the client never computes a production score from answer flags.
class RemoteAssessment {
  const RemoteAssessment({
    required this.id,
    required this.title,
    required this.questions,
    this.professor,
    this.correctAnswers,
    this.failedAnswers,
    this.questionCount,
    this.isFree,
    this.isSubscribed,
  });
  final String id, title;
  final String? professor;
  final List<RemoteQuestion> questions;
  final int? correctAnswers, failedAnswers, questionCount;
  final bool? isFree, isSubscribed;
}
