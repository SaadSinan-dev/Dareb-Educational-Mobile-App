class QuizQuestion {
  const QuizQuestion({
    required this.title,
    required this.answers,
    required this.correctIndex,
    this.expression,
  });
  final String title;
  final List<String> answers;
  final int correctIndex;
  final String? expression;
}
