import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../Order/order.dart';
import '../Order/order_repository.dart';
import '../main.dart';
import 'delivery_confirmation.dart';
import 'proof_photo_repository.dart';
import 'rider_delivery.dart';

class DeliveryCompletion extends StatefulWidget {
  final RiderDelivery delivery;
  final ProofPhotoRepository? proofPhotoRepository;
  final OrderRepository? orderRepository;
  final VoidCallback? onCompleted;

  const DeliveryCompletion({
    super.key,
    required this.delivery,
    this.proofPhotoRepository,
    this.orderRepository,
    this.onCompleted,
  });

  @override
  State<DeliveryCompletion> createState() => _DeliveryCompletionState();
}

class _DeliveryCompletionState extends State<DeliveryCompletion> {
  final TextEditingController _commentsController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _photo;
  Future<Uint8List>? _previewBytes;
  bool _picking = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<ImageSource?> _choosePhotoSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from device'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickPhoto() async {
    if (_picking || _submitting) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final source = await _choosePhotoSource();
      if (!mounted || source == null) return;
      final photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (!mounted) return;
      if (photo != null) {
        setState(() {
          _photo = photo;
          _previewBytes = photo.readAsBytes();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Camera could not be opened.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) {
      setState(() => _error = 'Take a photo before confirming delivery.');
      return;
    }
    if (_submitting) return;
    final proofRepository =
        widget.proofPhotoRepository ?? _defaultProofRepository();
    final orderRepository = widget.orderRepository ?? _defaultOrderRepository();
    if (proofRepository == null || orderRepository == null) {
      setState(() => _error = 'Delivery completion is not configured yet.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    String? uploadedPath;
    try {
      uploadedPath = await proofRepository.upload(
        orderId: widget.delivery.order.id,
        photo: photo,
      );
      final order = await orderRepository.completeDelivery(
        orderId: widget.delivery.order.id,
        proofPhotoPath: uploadedPath,
        deliveryComments: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
      );
      if (!mounted) return;
      widget.onCompleted?.call();
      final completedDelivery = RiderDelivery(
        order: order,
        customerName: widget.delivery.customerName,
        customerPhone: widget.delivery.customerPhone,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryConfirmation(delivery: completedDelivery),
        ),
      );
    } catch (error) {
      if (uploadedPath != null) {
        try {
          await proofRepository
              .remove(uploadedPath)
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _completionErrorMessage(error);
        });
      }
    }
  }

  String _completionErrorMessage(Object error) {
    if (error is ProofPhotoRepositoryException) {
      return error.message;
    }
    if (error is OrderRepositoryException) {
      return error.message;
    }
    if (error is OrderDataException) {
      return error.message;
    }
    return 'Delivery could not be completed. Check the photo and try again.';
  }

  ProofPhotoRepository? _defaultProofRepository() {
    try {
      return SupabaseProofPhotoRepository(client: supabase);
    } catch (_) {
      return null;
    }
  }

  OrderRepository? _defaultOrderRepository() {
    try {
      return SupabaseOrderRepository(supabase);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xf8ffffff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xdd000000),
            size: 20,
          ),
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Delivery',
          style: TextStyle(
            color: Color(0xdd000000),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PhotoEvidenceSection(
                      photo: _photo,
                      previewBytes: _previewBytes,
                      picking: _picking,
                      onPick: _pickPhoto,
                    ),
                    const SizedBox(height: 32),
                    CommentsSection(
                      controller: _commentsController,
                      enabled: !_submitting,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xffd32f2f),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConfirmButton(
                onPressed: _submit,
                busy: _submitting,
                enabled: _photo != null,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class PhotoEvidenceSection extends StatelessWidget {
  final XFile? photo;
  final Future<Uint8List>? previewBytes;
  final bool picking;
  final VoidCallback onPick;

  const PhotoEvidenceSection({
    super.key,
    required this.photo,
    required this.previewBytes,
    required this.picking,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photo != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo Evidence',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xdd000000),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Take a picture or choose one from the device as proof.',
          style: TextStyle(fontSize: 14, color: Color(0xff757575)),
        ),
        const SizedBox(height: 16),
        Semantics(
          button: true,
          label: hasPhoto ? 'Change proof photo' : 'Add proof photo',
          child: GestureDetector(
            onTap: picking ? null : onPick,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xfff5f5f5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffe0e0e0), width: 1.5),
              ),
              child: picking
                  ? const Center(child: CircularProgressIndicator())
                  : hasPhoto
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FutureBuilder<Uint8List>(
                        future: previewBytes,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(snapshot.data!, fit: BoxFit.cover),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    color: Colors.black54,
                                    padding: const EdgeInsets.all(8),
                                    child: const Text(
                                      'Tap to change photo',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 48,
                          color: Color(0xff9e9e9e),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tap to add a picture',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff757575),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class CommentsSection extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const CommentsSection({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Comments (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xdd000000),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(20, 0, 0, 0),
                blurRadius: 8,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Any issues or notes about this delivery?',
              hintStyle: const TextStyle(
                color: Color(0xff9e9e9e),
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}

class ConfirmButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool busy;
  final bool enabled;

  const ConfirmButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: busy || !enabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff4caf50),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xffa5d6a7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Confirm Delivery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
