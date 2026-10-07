import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<List<int>> _pbkdf2Task(List<Object> args) async {
  final algo = Pbkdf2(
      macAlgorithm: Hmac.sha256(), iterations: 60000, bits: 256);
  final key = await algo.deriveKeyFromPassword(
    password: args[0] as String,
    nonce: [...(args[1] as List).cast<int>(), ...(args[2] as List).cast<int>()],
  );
  return key.extractBytes();
}

class PendingPin {
  PendingPin._(this.key, this.salt, this.device, this.verifier);
  final SecretKey key;
  final List<int> salt;
  final List<int> device;
  final String verifier;
}

/// PIN + encryption for private notes.
///
/// Key = PBKDF2-HMAC-SHA256(PIN, salt || deviceSecret), 60k iterations.
/// The device secret is random and lives in Android Keystore-backed storage,
/// so the PIN alone is not enough to derive the key. Notes use AES-256-GCM.
/// The PIN is never stored; a PIN is "correct" only if it decrypts a small
/// verifier blob. Forgetting the PIN makes private notes unrecoverable.
class PrivacyService extends ChangeNotifier {
  static const _kSalt = 'qn_salt';
  static const _kDevice = 'qn_device';
  static const _kVerifier = 'qn_verifier';
  static const _kFails = 'qn_fails';
  static const _kUntil = 'qn_until';
  static const _verifierText = 'quicknote-private-v1';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final AesGcm _aes = AesGcm.with256bits();

  SecretKey? _key;
  bool _hasPin = false;

  bool get hasPin => _hasPin;
  bool get isUnlocked => _key != null;
  SecretKey? get currentKey => _key;

  Future<void> init() async {
    try {
      _hasPin = (await _storage.read(key: _kVerifier)) != null;
    } catch (_) {
      _hasPin = false;
    }
    notifyListeners();
  }

  static Future<String> sealWith(String text, SecretKey key) async {
    final box = await _aes.encrypt(utf8.encode(text), secretKey: key);
    return base64Encode(box.concatenation());
  }

  static Future<String> openWith(String data, SecretKey key) async {
    final box = SecretBox.fromConcatenation(base64Decode(data),
        nonceLength: 12, macLength: 16);
    return utf8.decode(await _aes.decrypt(box, secretKey: key));
  }

  Future<String> encrypt(String text) {
    final k = _key;
    if (k == null) throw StateError('Private notes are locked.');
    return sealWith(text, k);
  }

  Future<String> decrypt(String data) {
    final k = _key;
    if (k == null) throw StateError('Private notes are locked.');
    return openWith(data, k);
  }

  List<int> _rand(int n) {
    final r = Random.secure();
    return List<int>.generate(n, (_) => r.nextInt(256));
  }

  Future<SecretKey> _derive(String pin, List<int> salt, List<int> device) async {
    final bytes = await compute(_pbkdf2Task, <Object>[pin, salt, device]);
    return SecretKey(bytes);
  }

  Future<PendingPin> preparePin(String pin) async {
    final salt = _rand(16);
    final device = _rand(32);
    final key = await _derive(pin, salt, device);
    final verifier = await sealWith(_verifierText, key);
    return PendingPin._(key, salt, device, verifier);
  }

  Future<void> commitPin(PendingPin p) async {
    await _storage.write(key: _kSalt, value: base64Encode(p.salt));
    await _storage.write(key: _kDevice, value: base64Encode(p.device));
    await _storage.write(key: _kVerifier, value: p.verifier);
    await _storage.write(key: _kFails, value: '0');
    await _storage.write(key: _kUntil, value: '0');
    _key = p.key;
    _hasPin = true;
    notifyListeners();
  }

  String _fmt(int secs) =>
      secs >= 60 ? '${(secs / 60).ceil()} min' : '$secs s';

  /// Returns null on success, otherwise a user-facing error message.
  Future<String?> unlock(String pin) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final until = int.tryParse(await _storage.read(key: _kUntil) ?? '') ?? 0;
      if (until > now) {
        return 'Too many attempts. Try again in ${_fmt(((until - now) / 1000).ceil())}.';
      }
      final salt = await _storage.read(key: _kSalt);
      final dev = await _storage.read(key: _kDevice);
      final ver = await _storage.read(key: _kVerifier);
      if (salt == null || dev == null || ver == null) {
        return 'PIN data is missing. You can reset private notes in Settings.';
      }
      final key = await _derive(pin, base64Decode(salt), base64Decode(dev));
      try {
        if (await openWith(ver, key) == _verifierText) {
          _key = key;
          await _storage.write(key: _kFails, value: '0');
          await _storage.write(key: _kUntil, value: '0');
          notifyListeners();
          return null;
        }
      } catch (_) {}
      final fails =
          (int.tryParse(await _storage.read(key: _kFails) ?? '') ?? 0) + 1;
      await _storage.write(key: _kFails, value: '$fails');
      if (fails >= 5) {
        final delay = min(30 * (1 << min(fails - 5, 7)), 3600);
        await _storage.write(
            key: _kUntil, value: '${now + delay * 1000}');
        return 'Incorrect PIN. Too many attempts — wait ${_fmt(delay)}.';
      }
      return 'Incorrect PIN. ${5 - fails} ${5 - fails == 1 ? 'try' : 'tries'} left before a short lock.';
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void lock() {
    if (_key != null) {
      _key = null;
      notifyListeners();
    }
  }

  /// Removes the PIN and all key material. Private notes become unreadable,
  /// so callers must delete them first.
  Future<void> wipe() async {
    for (final k in [_kSalt, _kDevice, _kVerifier, _kFails, _kUntil]) {
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
    _key = null;
    _hasPin = false;
    notifyListeners();
  }
}
