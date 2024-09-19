import 'dart:convert';

bool isBase64Encoded(String input) {
  // Base64 decoding 후 다시 인코딩하여 원래 문자열과 비교하여 확인
  try {
    String decoded = utf8.decode(base64.decode(input));
    String reEncoded = base64.encode(utf8.encode(decoded));
    return input == reEncoded;
  } catch (e) {
    return false; // 디코딩 중 에러 발생 시 false 반환
  }
}
