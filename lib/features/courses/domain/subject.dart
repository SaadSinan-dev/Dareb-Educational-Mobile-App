class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.isFree,
    required this.isSubscribed,
    this.imageUrl,
  });

  final String id;
  final String name;
  final bool isFree;
  final bool isSubscribed;
  final String? imageUrl;
}
