import 'dart:convert';
import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static final _key = Key.fromUtf8(
      'my32lengthsupersecretnooneknows!'); // 32-char key for AES-256
  static final _encrypter = Encrypter(AES(_key));

  /// Encrypts text and returns base64(iv + ciphertext)
  static String encrypt(String plainText) {
    final iv = IV.fromSecureRandom(16); // Generate random IV
    final encrypted = _encrypter.encrypt(plainText, iv: iv);

    // Combine IV and encrypted data and encode in base64
    final combined = iv.bytes + encrypted.bytes;
    return base64.encode(combined);
  }

  /// Decrypts base64(iv + ciphertext)
  static String decrypt(String encryptedBase64) {
    final encryptedBytes = base64.decode(encryptedBase64);

    // Extract IV and ciphertext
    final iv = IV(encryptedBytes.sublist(0, 16));
    final ciphertext = encryptedBytes.sublist(16);

    final encrypted = Encrypted(ciphertext);
    return _encrypter.decrypt(encrypted, iv: iv);
  }
}
