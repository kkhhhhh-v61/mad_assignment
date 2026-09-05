import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mad_assignment/Order/order_repository.dart';
import 'package:mad_assignment/rider/proof_photo_repository.dart';

void main() {
  const orderId = 'f4102b7c-fc36-4d85-8f37-5c0ac54fab79';

  test(
    'rejects a proof photo larger than the Storage limit before upload',
    () async {
      final client = SupabaseClient('http://127.0.0.1:1', 'test-key');
      addTearDown(client.dispose);
      final repository = SupabaseProofPhotoRepository(client: client);
      final photo = XFile.fromData(
        Uint8List(SupabaseProofPhotoRepository.maxProofPhotoBytes + 1),
        name: 'proof.jpg',
      );

      await expectLater(
        repository.upload(orderId: orderId, photo: photo),
        throwsA(
          isA<ProofPhotoRepositoryException>().having(
            (error) => error.message,
            'message',
            'Proof photo must be 5 MB or smaller.',
          ),
        ),
      );
    },
  );

  test('turns a stalled completion RPC into a typed timeout', () async {
    final client = SupabaseClient(
      'http://completion.test',
      'test-key',
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return http.Response('{}', 200);
      }),
    );
    addTearDown(client.dispose);
    final repository = SupabaseOrderRepository(
      client,
      completionTimeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      repository.completeDelivery(
        orderId: orderId,
        proofPhotoPath: '$orderId/00000000-0000-4000-8000-000000000000.jpg',
      ),
      throwsA(
        isA<OrderRepositoryException>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
}
