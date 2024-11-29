class TextUtils {
  static String ellipsisIfLonger(String text, {int maxLength = 10}) {
    text = text.replaceAll('\n', ' ');
    return text.length > maxLength
        ? '${text.substring(0, maxLength - 3)}...'
        : text;
  }

  static String replaceNewlineWithSpace(String text) {
    return text.replaceAll('\n', ' ');
  }

  static String truncateNameMax25(String name) {
    if (name.length <= 25) {
      return name;
    }

    return '${name.substring(0, 15)}...${name.substring(name.length - 10)}';
  }
}
