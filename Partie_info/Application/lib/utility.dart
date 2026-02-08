void sortList(List<dynamic> list) {
  list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
}

String formatDuration(double seconds) {
  final minutes = (seconds / 60).floor();
  final remainingSeconds = (seconds % 60).floor();
  return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
}
