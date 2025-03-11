import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:library_project/database/database.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:asn1lib/asn1lib.dart';
import 'package:firebase_database/firebase_database.dart';

class SecureChatService {
  static final SecureChatService instance = SecureChatService._internal();

  SecureChatService._internal();

  final _secureStorage = const FlutterSecureStorage();

  late RSAPrivateKey _privateKey;

  // Storage keys with user-specific prefixes
  String _getPrivateKeyName(String userId) => 'private_key_$userId';

  String _getPublicKeyName(String userId) => 'public_key_$userId';

  static const String _publicKeysPath = 'publicKeys';

  // Initialize the service for a specific user
  Future<void> initialize(String userId) async {
    bool hasKeys = await _checkKeysExist(userId);

    if (hasKeys) {
      await _loadKeysFromStorage(userId);
    } else {
      await _generateAndSaveKeys(userId);
    }
  }

  // Check if keys exist for the specified user
  Future<bool> _checkKeysExist(String userId) async {
    String? privateKeyPEM = await _secureStorage.read(key: _getPrivateKeyName(userId));
    return privateKeyPEM != null;
  }

  // Load keys from storage for the specified user
  Future<void> _loadKeysFromStorage(String userId) async {
    try {
      String? privateKeyPEM = await _secureStorage.read(key: _getPrivateKeyName(userId));
      // String? publicKeyPEM = await _secureStorage.read(key: _getPublicKeyName(userId));

      if (privateKeyPEM == null) {
        throw Exception('Keys not found for user: $userId');
      }

      _privateKey = RSAKeyHelper.parsePrivateKeyFromPem(privateKeyPEM);
      // _publicKey = RSAKeyHelper.parsePublicKeyFromPem(publicKeyPEM);

      debugPrint('Keys loaded from storage for user: $userId');
    } catch (e) {
      throw Exception('Error in loading keys from storage: $e');
    }
  }

  // Generate and save new keys for the specified user
  Future<void> _generateAndSaveKeys(String userId) async {
    try {
      final keyPair = _generateRSAKeyPair(2048);
      _privateKey = keyPair.privateKey as RSAPrivateKey;
      RSAPublicKey publicKey = keyPair.publicKey as RSAPublicKey;

      String privatePEM = RSAKeyHelper.encodePrivateKeyToPem(_privateKey);
      String publicPEM = RSAKeyHelper.encodePublicKeyToPem(publicKey);

      await _secureStorage.write(key: _getPrivateKeyName(userId), value: privatePEM);
      await _secureStorage.write(key: _getPublicKeyName(userId), value: publicPEM);

      // Upload public key to the server
      await _uploadPublicKey(userId, publicPEM);

      debugPrint('Key pairs generated and saved to storage for user: $userId');
    } catch (e) {
      throw Exception('Error in generating and saving key pairs: $e');
    }
  }

  // Upload the public key to the server
  Future<void> _uploadPublicKey(String userId, String publicKeyPEM) async {
    try {
      await dbReference
          .child(_publicKeysPath)
          .child(userId)
          .set({'key': publicKeyPEM, 'timestamp': ServerValue.timestamp});
      debugPrint('Public key uploaded successfully for user: $userId');
    } catch (e) {
      debugPrint('Error in uploading public key: $e');
    }
  }

  // Complete account deletion - removes all user data including keys
  Future<void> deleteAccount(String userId) async {
    try {
      await _secureStorage.delete(key: _getPrivateKeyName(userId));
      await _secureStorage.delete(key: _getPublicKeyName(userId));

      // Also remove keys from the server
      await dbReference.child(_publicKeysPath).child(userId).remove();

      debugPrint('Account data deleted for user: $userId');
    } catch (e) {
      throw Exception('Error in deleting account data: $e');
    }
  }

  // Get public key for a specific user from the server
  Future<RSAPublicKey> getPublicKey(String userId) async {
    try {
      final keyRef = await dbReference.child(_publicKeysPath).child(userId).once();

      if (keyRef.snapshot.value != null) {
        String publicKeyPEM = (keyRef.snapshot.value as Map)['key'];
        return RSAKeyHelper.parsePublicKeyFromPem(publicKeyPEM);
      } else {
        throw Exception('Public key not found for user: $userId');
      }
    } catch (e) {
      throw Exception('Error in getting public key: $e');
    }
  }

  // Generate RSA key pair
  AsymmetricKeyPair<PublicKey, PrivateKey> _generateRSAKeyPair(int bitLength) {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(255));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));

    return keyGen.generateKeyPair();
  }

  // Encrypt a message for a specific recipient
  Future<String> encryptMessage(String message, String recipientId) async {
    try {
      RSAPublicKey recipientPublicKey = await getPublicKey(recipientId);

      final cipher = RSAEngine()..init(true, PublicKeyParameter<RSAPublicKey>(recipientPublicKey));

      final data = Uint8List.fromList(utf8.encode(message));

      // RSA can only encrypt data up to a certain size, so we split it into chunks
      final blockSize = cipher.inputBlockSize - 11; // 11 bytes for PKCS#1 padding
      final output = <int>[];

      for (var i = 0; i < data.length; i += blockSize) {
        final chunkSize = i + blockSize < data.length ? blockSize : data.length - i;
        final chunk = data.sublist(i, i + chunkSize);
        output.addAll(cipher.process(Uint8List.fromList(chunk)));
      }

      return base64.encode(output);
    } catch (e) {
      throw Exception('Error in encrypting message: $e');
    }
  }

  // Decrypt a message with the current user's private key
  String decryptMessage(String encryptedMessage) {
    try {
      final cipher = RSAEngine()..init(false, PrivateKeyParameter<RSAPrivateKey>(_privateKey));

      final data = base64.decode(encryptedMessage);

      // Process the encrypted data in chunks
      final blockSize = cipher.inputBlockSize;
      final output = <int>[];

      for (var i = 0; i < data.length; i += blockSize) {
        final chunkSize = i + blockSize < data.length ? blockSize : data.length - i;
        final chunk = data.sublist(i, i + chunkSize);
        output.addAll(cipher.process(Uint8List.fromList(chunk)));
      }

      return utf8.decode(output);
    } catch (e) {
      throw Exception('Error in decrypting message: $e');
    }
  }
}

// Helper class for RSA key operations
class RSAKeyHelper {
  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    var topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(BigInt.zero));
    topLevel.add(ASN1Integer(privateKey.n!));
    topLevel.add(ASN1Integer(privateKey.exponent!));
    topLevel.add(ASN1Integer(privateKey.p!));
    topLevel.add(ASN1Integer(privateKey.q!));

    var dataBase64 = base64.encode(topLevel.encodedBytes);

    return '''-----BEGIN RSA PRIVATE KEY-----\r\n$dataBase64\r\n-----END RSA PRIVATE KEY-----''';
  }

  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    var topLevel = ASN1Sequence();

    topLevel.add(ASN1Integer(publicKey.modulus!));
    topLevel.add(ASN1Integer(publicKey.exponent!));

    var dataBase64 = base64.encode(topLevel.encodedBytes);

    return '''-----BEGIN RSA PUBLIC KEY-----\r\n$dataBase64\r\n-----END RSA PUBLIC KEY-----''';
  }

  static RSAPrivateKey parsePrivateKeyFromPem(String pemString) {
    pemString = pemString
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '');

    var asn1 = ASN1Parser(base64.decode(pemString));
    var topLevel = asn1.nextObject() as ASN1Sequence;

    var values = topLevel.elements.map((e) => (e as ASN1Integer).valueAsBigInteger).toList();

    return RSAPrivateKey(
      values[1], // modulus (n)
      values[2], // exponent
      values[3], // p
      values[4], // q
    );
  }

  static RSAPublicKey parsePublicKeyFromPem(String pemString) {
    pemString = pemString
        .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
        .replaceAll('-----END RSA PUBLIC KEY-----', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '');

    var asn1 = ASN1Parser(base64.decode(pemString));
    var topLevel = asn1.nextObject() as ASN1Sequence;

    var values = topLevel.elements.map((e) => (e as ASN1Integer).valueAsBigInteger).toList();

    return RSAPublicKey(
      values[0], // modulus (n)
      values[1], // exponent
    );
  }
}
