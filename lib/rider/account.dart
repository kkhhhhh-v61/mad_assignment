import 'package:flutter/material.dart';

import 'header.dart';
import 'profile.dart';

class RiderAccount extends StatelessWidget {
  const RiderAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const RiderHeader(
          pageTitle: 'My Account',
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                buildProfileCard(context),
                const SizedBox(height: 24.0),
                buildLogoutTile(context),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildProfileCard(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20.0),
    padding: const EdgeInsets.all(20.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.0),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(20, 0, 0, 0),
          blurRadius: 8,
          spreadRadius: 1,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 160, 122).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: Color.fromARGB(255, 255, 160, 122),
          ),
        ),
        const SizedBox(width: 20.0),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //TODO: Retrieve rider profile details dynamically from backend
              Text(
                'Rider Ahmad',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.0),
              Text(
                '+60 12-345 6789',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ahmad_rider@example.com',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.edit_outlined,
            color: Color.fromARGB(255, 158, 158, 158),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RiderProfile(),
              ),
            );
          },
        ),
      ],
    ),
  );
}

Widget buildLogoutTile(BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.0),
      boxShadow: const [
        BoxShadow(
          color: Color.fromARGB(20, 0, 0, 0),
          blurRadius: 8,
          spreadRadius: 1,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 229, 57, 53).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.logout,
          color: Color.fromARGB(255, 229, 57, 53),
          size: 22,
        ),
      ),
      title: const Text(
        'Log Out',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15.0,
          color: Color.fromARGB(255, 229, 57, 53),
        ),
      ),
      onTap: () {
        // Redirect back to the customer side login page
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logged out successfully',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color.fromARGB(255, 239, 83, 80),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      },
    ),
  );
}
