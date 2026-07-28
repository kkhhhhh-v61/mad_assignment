import 'package:flutter/material.dart';
import 'header.dart';
import 'rider_creation.dart';
import 'rider_details.dart';

class AdminRiderManagement extends StatefulWidget {
  const AdminRiderManagement({super.key});

  @override
  State<AdminRiderManagement> createState() => _AdminRiderManagementState();
}

class _AdminRiderManagementState extends State<AdminRiderManagement> {
  //TODO: Retrieve actual rider items from backend
  final List<Map<String, dynamic>> _riderItems = [
    {
      'id': '1',
      'name': 'Ahmad Ali',
      'phone': '012-3456789',
      'email': 'ahmad.ali@example.com',
      'vehicle': 'Motorcycle',
      'plate': 'VBE 1234',
      'icon': Icons.motorcycle,
      'rating': '4.9',
      'status': 'Online',
    },
    {
      'id': '2',
      'name': 'Sarah Lee',
      'phone': '017-9876543',
      'email': 'sarah.lee@example.com',
      'vehicle': 'Motorcycle',
      'plate': 'BCD 5678',
      'icon': Icons.motorcycle,
      'rating': '4.7',
      'status': 'On Delivery',
    },
    {
      'id': '3',
      'name': 'Muthu Kumar',
      'phone': '019-1122334',
      'email': 'muthu.kumar@example.com',
      'vehicle': 'Motorcycle',
      'plate': 'PEN 8888',
      'icon': Icons.motorcycle,
      'rating': '4.5',
      'status': 'Offline',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 160, 122),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminRiderCreation(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          AdminHeader(
            pageTitle: 'Rider Management',
            showSearch: true,
            showFilter: true,
            onFilterTap: _showFilterOverlay,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20.0),
                  _buildRiderList(context, _riderItems),
                  const SizedBox(height: 80.0), // Padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderList(
      BuildContext context, List<Map<String, dynamic>> items) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminRiderDetails(rider: item),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16.0),
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
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 40,
                    color: const Color.fromARGB(255, 158, 158, 158),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(221, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color.fromARGB(255, 255, 193, 7),
                            size: 16,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            item['rating'] as String,
                            style: const TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 117, 117, 117),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          const Icon(
                            Icons.delivery_dining,
                            color: Color.fromARGB(255, 158, 158, 158),
                            size: 16,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${item['vehicle']} - ${item['plate']}',
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: Color.fromARGB(255, 117, 117, 117),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        item['status'] as String,
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: (item['status'] as String) == 'Online'
                              ? const Color.fromARGB(255, 76, 175, 80)
                              : (item['status'] as String) == 'On Delivery'
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
                  child: const Icon(
                    Icons.keyboard_arrow_right,
                    color: Color.fromARGB(255, 158, 158, 158),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ));
      },
    );
  }

  void _showFilterOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        String selectedSort = 'Name (A-Z)';
        final List<String> sortOptions = [
          'Name (A-Z)',
          'Rating (High to Low)',
          'Most Deliveries',
        ];

        String selectedVehicle = 'All';
        final List<String> vehicleOptions = [
          'All',
          'Motorcycle',
          'Car',
          'Bicycle',
        ];

        String selectedStatus = 'All';
        final List<String> statusOptions = [
          'All',
          'Online',
          'Offline',
          'On Delivery',
        ];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20.0),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 224, 224, 224),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter & Sort Riders',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedSort = 'Name (A-Z)';
                                selectedVehicle = 'All';
                                selectedStatus = 'All';
                              });
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(
                                color: Color.fromARGB(255, 229, 57, 53),
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),

                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 245, 245, 245),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSort,
                            isExpanded: true,
                            items: sortOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSort = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      const Text(
                        'Vehicle Type',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: vehicleOptions.map((String type) {
                          final isSelected = selectedVehicle == type;
                          return ChoiceChip(
                            label: Text(
                              type,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color.fromARGB(221, 0, 0, 0),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color.fromARGB(255, 255, 160, 122),
                            backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedVehicle = type;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24.0),

                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: statusOptions.map((String status) {
                          final isSelected = selectedStatus == status;
                          return ChoiceChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color.fromARGB(221, 0, 0, 0),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color.fromARGB(255, 255, 160, 122),
                            backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                            onSelected: (bool selected) {
                              setState(() {
                                selectedStatus = status;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32.0),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            //TODO: Apply filters to list
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 255, 160, 122),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
