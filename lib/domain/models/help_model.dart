class HelpItem {
  final String title;
  final String answer;
  final List<String> keywords;

  const HelpItem({
    required this.title,
    required this.answer,
    required this.keywords,
  });

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();

    // Check title
    if (title.toLowerCase().contains(q)) return true;

    // Check keywords
    for (final keyword in keywords) {
      if (keyword.toLowerCase().contains(q)) return true;
    }

    return false;
  }
}
