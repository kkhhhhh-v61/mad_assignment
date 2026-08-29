import 'package:flutter/material.dart';

class SharedAccountScreen extends StatelessWidget {
  final Widget header;
  final String name;
  final String email;
  final String subtitle;
  final IconData profileIcon;
  final bool showEditIcon;
  final VoidCallback? onEditPressed;
  final VoidCallback onLogout;
  final List<Widget> accountOptions;

  const SharedAccountScreen({
    super.key,
    required this.header,
    required this.name,
    required this.email,
    required this.subtitle,
    required this.profileIcon,
    this.showEditIcon = true,
    this.onEditPressed,
    required this.onLogout,
    this.accountOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        header,
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                _buildProfileCard(context),
                const SizedBox(height: 24.0),
                if (accountOptions.isNotEmpty)
                  _buildOptionsContainer(context)
                else
                  _buildStandaloneLogout(context),
                const SizedBox(height: 32.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
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
            child: Icon(
              profileIcon,
              size: 40,
              color: const Color.fromARGB(255, 255, 160, 122),
            ),
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'No Name',
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle.isNotEmpty ? subtitle : 'No Details',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'No Email',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
          if (showEditIcon)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color.fromARGB(255, 158, 158, 158),
              ),
              onPressed: onEditPressed,
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsContainer(BuildContext context) {
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
      child: Column(
        children: [
          ...accountOptions,
          const Divider(height: 1, indent: 60, endIndent: 20.0),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildStandaloneLogout(BuildContext context) {
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
      child: _buildLogoutTile(context),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
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
      onTap: onLogout,
    );
  }
}

class SharedOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const SharedOptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 4.0,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 245, 245, 245),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color.fromARGB(255, 117, 117, 117),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.0),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color.fromARGB(255, 158, 158, 158),
      ),
      onTap: onTap,
    );
  }
}