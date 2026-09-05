import 'package:flutter/material.dart';
import 'user_role.dart';

class SharedAccountScreen extends StatefulWidget {
  final Widget header;
  final String name;
  final String email;
  final String subtitle;
  final IconData profileIcon;
  final String? avatarUrl;
  final bool showEditIcon;
  final VoidCallback? onEditPressed;
  final VoidCallback onLogout;
  final List<Widget> accountOptions;
  final UserRole role;
  final String vehicleType;
  final String vehiclePlate;
  final bool isOnline;
  final ValueChanged<bool>? onOnlineChanged;

  const SharedAccountScreen({
    super.key,
    required this.header,
    required this.name,
    required this.email,
    required this.subtitle,
    required this.profileIcon,
    this.avatarUrl,
    this.showEditIcon = true,
    this.onEditPressed,
    required this.onLogout,
    this.accountOptions = const [],
    this.role = UserRole.customer,
    this.vehicleType = '',
    this.vehiclePlate = '',
    this.isOnline = false,
    this.onOnlineChanged,
  });

  @override
  State<SharedAccountScreen> createState() => _SharedAccountScreenState();
}

class _SharedAccountScreenState extends State<SharedAccountScreen> {
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.isOnline;
  }

  @override
  void didUpdateWidget(covariant SharedAccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOnline != widget.isOnline) {
      _isOnline = widget.isOnline;
    }
  }

  void _handleOnlineChanged(bool value) {
    setState(() {
      _isOnline = value;
    });

    widget.onOnlineChanged?.call(value);
  }

  bool get _isRider => widget.role == UserRole.rider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.header,
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20.0),
                _buildProfileCard(context),
                if (_isRider) ...[
                  const SizedBox(height: 16.0),
                  _buildRiderInformation(context),
                  const SizedBox(height: 16.0),
                  _buildOnlineStatusCard(context),
                ],
                const SizedBox(height: 24.0),
                if (widget.accountOptions.isNotEmpty)
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
              image: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(widget.avatarUrl!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                ? Icon(
              widget.profileIcon,
              size: 40,
              color: const Color.fromARGB(255, 255, 160, 122),
            )
                : null,
          ),
          const SizedBox(width: 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name.isNotEmpty ? widget.name : 'No Name',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  widget.subtitle.isNotEmpty
                      ? widget.subtitle
                      : _getRoleName(),
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  widget.email.isNotEmpty ? widget.email : 'No Email',
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
          if (widget.showEditIcon)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color.fromARGB(255, 158, 158, 158),
              ),
              onPressed: widget.onEditPressed,
            ),
        ],
      ),
    );
  }

  Widget _buildRiderInformation(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rider Information',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(221, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 16.0),
          _buildInformationRow(
            icon: Icons.two_wheeler_outlined,
            title: 'Vehicle Type',
            value: widget.vehicleType.isNotEmpty
                ? widget.vehicleType
                : 'Not Available',
          ),
          const Divider(
            height: 24.0,
            color: Color.fromARGB(255, 238, 238, 238),
          ),
          _buildInformationRow(
            icon: Icons.confirmation_number_outlined,
            title: 'Vehicle Plate',
            value: widget.vehiclePlate.isNotEmpty
                ? widget.vehiclePlate
                : 'Not Available',
          ),
        ],
      ),
    );
  }

  Widget _buildInformationRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9.0),
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 245, 245, 245),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 21.0,
            color: const Color.fromARGB(255, 117, 117, 117),
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: Color.fromARGB(255, 117, 117, 117),
                ),
              ),
              const SizedBox(height: 3.0),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(221, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.lock_outline,
          size: 17.0,
          color: Color.fromARGB(255, 158, 158, 158),
        ),
      ],
    );
  }

  Widget _buildOnlineStatusCard(BuildContext context) {
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
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: _isOnline
                  ? const Color.fromARGB(255, 76, 175, 80).withValues(alpha: 0.12)
                  : const Color.fromARGB(255, 158, 158, 158).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isOnline
                  ? Icons.delivery_dining
                  : Icons.delivery_dining_outlined,
              color: _isOnline
                  ? const Color.fromARGB(255, 76, 175, 80)
                  : const Color.fromARGB(255, 117, 117, 117),
              size: 24.0,
            ),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'You are Online' : 'Go Online',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _isOnline
                      ? 'You can receive delivery orders'
                      : 'Start accepting delivery orders',
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: Color.fromARGB(255, 117, 117, 117),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOnline,
            activeThumbColor: const Color.fromARGB(255, 76, 175, 80),
            onChanged: _handleOnlineChanged,
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
            blurRadius: 8.0,
            spreadRadius: 1.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ...widget.accountOptions,
          const Divider(
            height: 1.0,
            indent: 60.0,
            endIndent: 20.0,
          ),
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
            blurRadius: 8.0,
            spreadRadius: 1.0,
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
          size: 22.0,
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
      onTap: widget.onLogout,
    );
  }

  String _getRoleName() {
    switch (widget.role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.rider:
        return 'Rider';
      case UserRole.customer:
        return 'Customer';
    }
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
          size: 22.0,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15.0,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16.0,
        color: Color.fromARGB(255, 158, 158, 158),
      ),
      onTap: onTap,
    );
  }
}