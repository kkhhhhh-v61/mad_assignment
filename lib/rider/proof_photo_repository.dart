import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class ProofPhotoRepository {
  Future<String> upload({required String orderId, required XFile photo});

  Future<void> remove(String path);

  Future<String> createSignedUrl(
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  });
}

class ProofPhotoRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const ProofPhotoRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SupabaseProofPhotoRepository implements ProofPhotoRepository {
  static const bucket = 'delivery-proofs';

  final SupabaseClient client;
  final Uuid uuid;

  const SupabaseProofPhotoRepository({
    required this.client,
    this.uuid = const Uuid(),
  });

  @override
  Future<String> upload({required String orderId, required XFile photo}) async {
    if (!_isUuid(orderId)) {
      throw const ProofPhotoRepositoryException('Order ID is invalid.');
    }
    final path = '$orderId/${uuid.v4()}.jpg';
    try {
      final bytes = await photo.readAsBytes();
      if (bytes.isEmpty) {
        throw const ProofPhotoRepositoryException(
          'The selected photo is empty.',
        );
      }
      await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      return path;
    } on ProofPhotoRepositoryException {
      rethrow;
    } catch (error) {
      throw ProofPhotoRepositoryException('Proof photo upload failed.', error);
    }
  }

  @override
  Future<void> remove(String path) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (error) {
      throw ProofPhotoRepositoryException('Proof photo cleanup failed.', error);
    }
  }

  @override
  Future<String> createSignedUrl(
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async {
    if (expiresIn <= Duration.zero) {
      throw const ProofPhotoRepositoryException(
        'Signed URL expiry must be positive.',
      );
    }
    try {
      return await client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn.inSeconds);
    } catch (error) {
      throw ProofPhotoRepositoryException(
        'Proof photo access was denied.',
        error,
      );
    }
  }
}

bool _isUuid(String value) {
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
