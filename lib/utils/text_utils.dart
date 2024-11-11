class TextUtils {
  static String ellipsisIfLonger(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
  }

  static String ellipsisNameIfOver10(String name) {
    return name.length > 10 ? '${name.substring(0, 7)}...' : name;
  }
}
