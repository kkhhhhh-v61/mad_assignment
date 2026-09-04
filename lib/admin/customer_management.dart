import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCustomerManagement extends StatefulWidget {
  const AdminCustomerManagement({super.key});

  @override
  State<AdminCustomerManagement> createState() => _AdminCustomerManagementState();
}

class _AdminCustomerManagementState extends State<AdminCustomerManagement> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'customer')
          .order('name', ascending: true);

      setState(() {
        _customers = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      _showSnackBar('Error fetching customers: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;

    return _customers.where((customer) {
      final name = (customer['name'] ?? '').toString().toLowerCase();
      final email = (customer['email'] ?? '').toString().toLowerCase();
      final phone = (customer['phone'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  void _showStatusToggleDialog(String customerId, String customerName, bool isCurrentlyInactive) {
    final targetStatus = isCurrentlyInactive ? 'Active' : 'Inactive';
    final actionTitle = isCurrentlyInactive ? 'Activate Customer' : 'Deactivate Customer';
    final actionColor = isCurrentlyInactive ? Colors.green : Colors.orange;
    final message = isCurrentlyInactive
        ? 'Are you sure you want to activate "$customerName"? They will be able to log in again.'
        : 'Are you sure you want to deactivate "$customerName"? They will not be able to log in.';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: Text(actionTitle, style: TextStyle(fontWeight: FontWeight.bold, color: actionColor)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _supabase.from('profiles').update({'status': targetStatus}).eq('id', customerId);
                  _showSnackBar('Customer status updated to $targetStatus successfully', Colors.green);
                  _fetchCustomers();
                } catch (e) {
                  _showSnackBar('Error updating status: $e', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: actionColor),
              child: Text(isCurrentlyInactive ? 'Activate' : 'Deactivate', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Manage Customers',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14.0),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 238, 238, 238)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 238, 238, 238)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 255, 160, 122), width: 1.5),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
                : _filteredCustomers.isEmpty
                ? const Center(child: Text('No matching customers found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                final String status = customer['status'] ?? 'Active';
                final bool isInactive = status == 'Inactive';
                final String? avatarUrl = customer['avatar_url']?.toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: CircleAvatar(
                      backgroundColor: isInactive
                          ? Colors.grey.withOpacity(0.2)
                          : const Color.fromARGB(255, 255, 160, 122).withOpacity(0.2),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? Icon(isInactive ? Icons.person_off : Icons.person,
                          color: isInactive ? Colors.grey : const Color.fromARGB(255, 255, 160, 122))
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(customer['name'] ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isInactive ? TextDecoration.lineThrough : null,
                                  color: isInactive ? Colors.grey : Colors.black87)),
                        ),
                        if (isInactive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Inactive',
                                style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(customer['email'] ?? 'No Email', style: const TextStyle(fontSize: 12)),
                        Text(customer['phone'] ?? 'No Phone', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isInactive ? Icons.check_circle_outline : Icons.block,
                        color: isInactive ? Colors.green : Colors.orange,
                      ),
                      tooltip: isInactive ? 'Activate' : 'Deactivate',
                      onPressed: () => _showStatusToggleDialog(
                        customer['id'],
                        customer['name'] ?? 'Unknown',
                        isInactive,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}