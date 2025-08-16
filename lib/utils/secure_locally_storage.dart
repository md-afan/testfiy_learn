import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// class SecureLocalStorage {
//   // Create a static secure storage instance
//   static final FlutterSecureStorage _secureStorage =
//       const FlutterSecureStorage();

//   /// Save encrypted role
//   static Future<void> saveEncryptedDatalocally(String key, String value) async {
//     await _secureStorage.write(key: key, value: value);
//   }

//   /// Get encrypted role
//   static Future<String?> getEncryptedDatalocally(String key) async {
//     return await _secureStorage.read(key: key);
//   }

//   /// Delete encrypted role
//   static Future<void> deleteEncryptedRole(key) async {
//     await _secureStorage.delete(key: key);
//   }

//   //  clear encryped data

//   static Future<void> clearEncryptedData() async {
//     final allKeys = await _secureStorage.readAll();
//     for (String key in allKeys.keys) {
//       await _secureStorage.delete(key: key);
//     }
//   }
// }

class LocalStorage {
  /// Save a value with a key
  static Future<void> saveLocalStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// Get a value by key
  static Future<String?> getLocalStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  /// Remove a key-value pair
  static Future<void> removeLocalStorage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Clear all storage
  static Future<void> clearLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
