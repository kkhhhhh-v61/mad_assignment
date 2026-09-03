import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CustomerProofPhotoRepository {
  Future<String> createSignedUrl(
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  });
}

class CustomerProofPhotoRepositoryException implements Exception {
  final String message;
  final Object? cause;

  const CustomerProofPhotoRepositoryException(this.message, [this.cause]);

  @override
  String toString() => message;
}

class SupabaseCustomerProofPhotoRepository
    implements CustomerProofPhotoRepository {
  static const bucket = 'delivery-proofs';

  final SupabaseClient client;

  const SupabaseCustomerProofPhotoRepository(this.client);

  @override
  Future<String> createSignedUrl(
    String path, {
    Duration expiresIn = const Duration(minutes: 5),
  }) async {
    final normalizedPath = path.trim();
    if (!_isProofPath(normalizedPath)) {
      throw const CustomerProofPhotoRepositoryException(
        'Proof photo path is invalid.',
      );
    }
    if (expiresIn <= Duration.zero) {
      throw const CustomerProofPhotoRepositoryException(
        'Signed URL expiry must be positive.',
      );
    }
    try {
      return await client.storage
          .from(bucket)
          .createSignedUrl(normalizedPath, expiresIn.inSeconds);
    } catch (error) {
      throw CustomerProofPhotoRepositoryException(
        'Proof photo access was denied.',
        error,
      );
    }
  }
}

bool _isProofPath(String value) {
  return RegExp(r'^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}\.jpg$').hasMatch(value);
}
