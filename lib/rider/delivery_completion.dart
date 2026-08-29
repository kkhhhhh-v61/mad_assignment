import 'package:flutter/material.dart';

import 'delivery_confirmation.dart';

class DeliveryCompletion extends StatefulWidget {
  final Map<String, dynamic> delivery;

  const DeliveryCompletion({super.key, required this.delivery});

  @override
  State<DeliveryCompletion> createState() => _DeliveryCompletionState();
}

class _DeliveryCompletionState extends State<DeliveryCompletion> {
  final TextEditingController _commentsController = TextEditingController();

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(248, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(221, 0, 0, 0),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Delivery',
          style: TextStyle(
            color: Color.fromARGB(221, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 18.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PhotoEvidenceSection(),
                    const SizedBox(height: 32.0),
                    CommentsSection(controller: _commentsController),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ConfirmButton(delivery: widget.delivery),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

class PhotoEvidenceSection extends StatelessWidget {
  const PhotoEvidenceSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photo Evidence',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 8.0),
        const Text(
          'Please take a picture of the delivered order as proof.',
          style: TextStyle(
            fontSize: 14.0,
            color: Color.fromARGB(255, 117, 117, 117),
          ),
        ),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: () {
            //TODO: Implement camera logic
          },
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 245, 245, 245),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color.fromARGB(255, 224, 224, 224),
                width: 1.5,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 48,
                  color: Color.fromARGB(255, 158, 158, 158),
                ),
                SizedBox(height: 12.0),
                Text(
                  'Tap to take a picture',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CommentsSection extends StatelessWidget {
  final TextEditingController controller;

  const CommentsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Comments (Optional)',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12.0),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
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
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Any issues or notes about this delivery?',
              hintStyle: const TextStyle(
                color: Color.fromARGB(255, 158, 158, 158),
                fontSize: 15.0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16.0),
            ),
          ),
        ),
      ],
    );
  }
}

class ConfirmButton extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const ConfirmButton({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          //TODO: Submit delivery completion data (photo, comments) to backend
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryConfirmation(delivery: delivery),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 76, 175, 80),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Confirm Delivery',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
