void sortList(List<dynamic> list) {
  list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
}
