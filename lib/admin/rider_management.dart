import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rider_creation.dart';
import 'rider_details.dart';

class AdminRiderManagement extends StatefulWidget {
  const AdminRiderManagement({super.key});

  @override
  State<AdminRiderManagement> createState() => _AdminRiderManagementState();
}

class _AdminRiderManagementState extends State<AdminRiderManagement> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _riderItems = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _currentSort = 'Name (A-Z)';
  String _currentStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiders() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('riders')
          .select('*, profiles(name, phone, email, avatar_url), branches(name)')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 10));

      setState(() {
        _riderItems = (data as List).map((e) {
          final item = e as Map<String, dynamic>;
          final profile = item['profiles'] as Map<String, dynamic>? ?? {};
          final branch = item['branches'] as Map<String, dynamic>? ?? {};

          final Map<String, dynamic> flattenedItem = Map<String, dynamic>.from(item);
          flattenedItem['name'] = profile['name'];
          flattenedItem['phone'] = profile['phone'];
          flattenedItem['email'] = profile['email'];
          flattenedItem['avatar_url'] = profile['avatar_url'];
          flattenedItem['branch_name'] = branch['name'] ?? 'Unassigned';

          return flattenedItem;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching riders: $e');
      setState(() {
        _riderItems = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRiders {
    List<Map<String, dynamic>> result = List.from(_riderItems);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((rider) {
        final name = (rider['name'] ?? '').toString().toLowerCase();
        final email = (rider['email'] ?? '').toString().toLowerCase();
        final phone = (rider['phone'] ?? '').toString().toLowerCase();
        final vehicle = (rider['vehicle'] ?? '').toString().toLowerCase();
        final plate = (rider['plate'] ?? '').toString().toLowerCase();
        final branchName = (rider['branch_name'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query) ||
            phone.contains(query) || vehicle.contains(query) || plate.contains(query) || branchName.contains(query);
      }).toList();
    }

    if (_currentStatusFilter != 'All') {
      result = result.where((rider) => rider['status'] == _currentStatusFilter).toList();
    }

    if (_currentSort == 'Name (A-Z)') {
      result.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
    } else if (_currentSort == 'Name (Z-A)') {
      result.sort((a, b) => (b['name'] ?? '').toString().compareTo((a['name'] ?? '').toString()));
    }

    return result;
  }

  void _showFilterOverlay() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (BuildContext context) {
        return RiderFilterSheet(
          initialSort: _currentSort,
          initialStatus: _currentStatusFilter,
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentSort = result['sort']!;
        _currentStatusFilter = result['status']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 249, 250, 251),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminRiderCreation()),
          ).then((shouldRefresh) {
            if (shouldRefresh == true) _fetchRiders();
          });
        },
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16.0,
              left: 20.0,
              right: 20.0,
              bottom: 20.0,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25.0)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(15, 0, 0, 0),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rider Management',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search name, phone, plate, branch...',
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
                          fillColor: const Color.fromARGB(255, 245, 245, 245),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color.fromARGB(255, 238, 238, 238)),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Color.fromARGB(255, 255, 160, 122)),
                        onPressed: _showFilterOverlay,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 255, 160, 122)))
                : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16.0),
                  RiderList(items: _filteredRiders, onRefresh: _fetchRiders),
                  const SizedBox(height: 80.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RiderList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final VoidCallback onRefresh;

  const RiderList({super.key, required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(15, 0, 0, 0),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(40, 255, 160, 122),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Color.fromARGB(255, 255, 160, 122),
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'No Riders Found',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Try adjusting your search criteria.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return RiderItemCard(item: items[index], onRefresh: onRefresh);
      },
    );
  }
}

class RiderItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRefresh;

  const RiderItemCard({super.key, required this.item, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminRiderDetails(rider: item),
          ),
        ).then((shouldRefresh) {
          if (shouldRefresh == true) onRefresh();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: const [
            BoxShadow(color: Color.fromARGB(15, 0, 0, 0), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 245, 245, 245),
                  borderRadius: BorderRadius.circular(15.0),
                  image: item['avatar_url'] != null && item['avatar_url'].toString().isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(item['avatar_url']),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: item['avatar_url'] == null || item['avatar_url'].toString().isEmpty
                    ? const Icon(
                  Icons.person,
                  size: 40,
                  color: Color.fromARGB(255, 158, 158, 158),
                )
                    : null,
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['name'] as String? ?? 'Unknown',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Color.fromARGB(221, 0, 0, 0)),
                    ),
                    const SizedBox(height: 8.0),

                    Row(
                      children: [
                        const Icon(Icons.store_outlined, color: Color.fromARGB(255, 158, 158, 158), size: 16),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            item['branch_name'] as String? ?? 'Unassigned',
                            style: const TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler, color: Color.fromARGB(255, 158, 158, 158), size: 16),
                        const SizedBox(width: 6.0),
                        Expanded(
                          child: Text(
                            'Motorcycle - ${item['plate'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 13.0, color: Color.fromARGB(255, 117, 117, 117)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      item['status'] as String? ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: (item['status'] as String?) == 'Online'
                            ? const Color.fromARGB(255, 76, 175, 80)
                            : (item['status'] as String?) == 'On Delivery'
                            ? const Color.fromARGB(255, 33, 150, 243)
                            : const Color.fromARGB(255, 158, 158, 158),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 245, 245, 245),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.keyboard_arrow_right, color: Color.fromARGB(255, 158, 158, 158), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RiderFilterSheet extends StatefulWidget {
  final String initialSort;
  final String initialStatus;

  const RiderFilterSheet({
    super.key,
    required this.initialSort,
    required this.initialStatus,
  });

  @override
  State<RiderFilterSheet> createState() => _RiderFilterSheetState();
}

class _RiderFilterSheetState extends State<RiderFilterSheet> {
  late String selectedSort;
  late String selectedStatus;

  final List<String> sortOptions = ['Name (A-Z)', 'Name (Z-A)'];
  final List<String> statusOptions = ['All', 'Online', 'Offline', 'On Delivery'];

  @override
  void initState() {
    super.initState();
    selectedSort = widget.initialSort;
    selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: const Color.fromARGB(255, 224, 224, 224), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter & Sort Riders', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedSort = 'Name (A-Z)';
                        selectedStatus = 'All';
                      });
                    },
                    child: const Text('Clear', style: TextStyle(color: Color.fromARGB(255, 229, 57, 53), fontWeight: FontWeight.bold, fontSize: 16.0)),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Text('Sort By', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(color: const Color.fromARGB(255, 245, 245, 245), borderRadius: BorderRadius.circular(12.0)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSort,
                    isExpanded: true,
                    items: sortOptions.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => selectedSort = newValue);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              const Text('Status', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0, runSpacing: 8.0,
                children: statusOptions.map((String status) {
                  final isSelected = selectedStatus == status;
                  return ChoiceChip(
                    label: Text(status, style: TextStyle(color: isSelected ? Colors.white : const Color.fromARGB(221, 0, 0, 0), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                    selected: isSelected,
                    selectedColor: const Color.fromARGB(255, 255, 160, 122),
                    backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                    onSelected: (bool selected) => setState(() => selectedStatus = status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32.0),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'sort': selectedSort,
                      'status': selectedStatus,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
                    elevation: 0,
                  ),
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}