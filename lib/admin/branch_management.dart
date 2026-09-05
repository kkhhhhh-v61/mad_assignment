import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Order/branch_repository.dart';
import 'header.dart';

const _branchAccent = Color.fromARGB(255, 255, 160, 122);
const _branchBackground = Color.fromARGB(255, 249, 250, 251);

class AdminBranchManagement extends StatefulWidget {
  final BranchAdminRepository? repository;

  const AdminBranchManagement({super.key, this.repository});

  @override
  State<AdminBranchManagement> createState() => _AdminBranchManagementState();
}

class _AdminBranchManagementState extends State<AdminBranchManagement> {
  late final BranchAdminRepository _repository;
  List<BranchRecord> _branches = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        SupabaseBranchAdminRepository(Supabase.instance.client);
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final branches = await _repository.fetchAllBranches();
      if (!mounted) return;
      setState(() {
        _branches = branches;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _branchErrorMessage(error);
      });
    }
  }

  Future<void> _openForm([BranchRecord? branch]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AdminBranchForm(repository: _repository, branch: branch),
      ),
    );
    if (saved == true && mounted) {
      await _loadBranches();
    }
  }

  Future<void> _confirmDelete(BranchRecord branch) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete branch?'),
        content: Text(
          'Delete ${branch.name}? Existing orders keep their saved branch snapshot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await _repository.deleteBranch(branch.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Branch deleted.')));
      await _loadBranches();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_branchErrorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _branchBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _branchAccent,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          const AdminHeader(pageTitle: 'Branch Management'),
          Expanded(
            child: RefreshIndicator(
              color: _branchAccent,
              onRefresh: _loadBranches,
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(
              child: CircularProgressIndicator(color: _branchAccent),
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: [
          const SizedBox(height: 80.0),
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 52,
            color: Colors.grey,
          ),
          const SizedBox(height: 12.0),
          const Text(
            'Unable to load branches',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20.0),
          Center(
            child: OutlinedButton(
              onPressed: _loadBranches,
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_branches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: const [
          SizedBox(height: 100.0),
          Icon(
            Icons.store_mall_directory_outlined,
            size: 52,
            color: Colors.grey,
          ),
          SizedBox(height: 12.0),
          Text(
            'No branches found',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.0),
          Text(
            'Add a branch to make it available for customer delivery selection.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 100.0),
      itemCount: _branches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final branch = _branches[index];
        return _BranchCard(
          branch: branch,
          onEdit: () => _openForm(branch),
          onDelete: () => _confirmDelete(branch),
        );
      },
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchRecord branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 8.0, 14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: _branchAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: const Icon(Icons.store_outlined, color: _branchAccent),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.name,
                          style: const TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusChip(isActive: branch.isActive),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${branch.branchCode}  •  State ${branch.stateCode}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    branch.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87, height: 1.25),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${branch.latitude.toStringAsFixed(5)}, ${branch.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Branch actions',
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AdminBranchForm extends StatefulWidget {
  final BranchAdminRepository repository;
  final BranchRecord? branch;

  const AdminBranchForm({super.key, required this.repository, this.branch});

  @override
  State<AdminBranchForm> createState() => _AdminBranchFormState();
}

class _AdminBranchFormState extends State<AdminBranchForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  int? _stateId;
  bool _isActive = true;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.branch != null;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _codeController = TextEditingController(text: branch?.branchCode ?? '');
    _nameController = TextEditingController(text: branch?.name ?? '');
    _addressController = TextEditingController(text: branch?.address ?? '');
    _latitudeController = TextEditingController(
      text: branch == null ? '' : branch.latitude.toString(),
    );
    _longitudeController = TextEditingController(
      text: branch == null ? '' : branch.longitude.toString(),
    );
    _stateId = branch?.stateId;
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final stateId = _stateId;
      if (stateId == null) {
        throw const BranchRepositoryException('Select a state.');
      }
      final state = branchStateOptions.firstWhere((item) => item.id == stateId);
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final draft = BranchDraft(
        branchCode: _codeController.text,
        name: _nameController.text,
        stateId: state.id,
        stateCode: state.code,
        address: _addressController.text,
        latitude: latitude,
        longitude: longitude,
        isActive: _isActive,
      );
      if (_isEditing) {
        await widget.repository.updateBranch(
          branchId: widget.branch!.id,
          draft: draft,
        );
      } else {
        await widget.repository.createBranch(draft);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = _branchErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _branchBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Branch' : 'Create Branch',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 120.0),
          children: [
            _textField(
              controller: _codeController,
              label: 'Branch Code',
              hint: 'e.g. DD-07-03',
              icon: Icons.qr_code_2,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16.0),
            _textField(
              controller: _nameController,
              label: 'Branch Name',
              hint: 'e.g. DoorDish Bukit Mertajam',
              icon: Icons.store_outlined,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<int>(
              initialValue: _stateId,
              decoration: const InputDecoration(
                labelText: 'State',
                prefixIcon: Icon(Icons.map_outlined),
                border: OutlineInputBorder(),
              ),
              items: branchStateOptions
                  .map(
                    (state) => DropdownMenuItem<int>(
                      value: state.id,
                      child: Text('${state.name} (${state.code})'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _stateId = value),
              validator: (value) => value == null ? 'Select a state.' : null,
            ),
            const SizedBox(height: 16.0),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'State Code',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _stateId == null
                    ? 'Select a state first'
                    : branchStateOptions
                          .firstWhere((state) => state.id == _stateId)
                          .code,
              ),
            ),
            const SizedBox(height: 16.0),
            _textField(
              controller: _addressController,
              label: 'Address',
              hint: 'Full branch address',
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    hint: '3.139000',
                    icon: Icons.north,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _latitudeValidator,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: _textField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    hint: '101.686900',
                    icon: Icons.east,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: _longitudeValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available to customers'),
              subtitle: const Text(
                'Inactive branches stay hidden from checkout.',
              ),
              value: _isActive,
              activeThumbColor: _branchAccent,
              onChanged: _isSaving
                  ? null
                  : (value) => setState(() => _isActive = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12.0),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
          child: SizedBox(
            height: 52.0,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: _branchAccent),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Create Branch'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isSaving,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }
}

String? _requiredValidator(String? value) {
  return value == null || value.trim().isEmpty
      ? 'This field is required.'
      : null;
}

String? _latitudeValidator(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed < -90 || parsed > 90) {
    return 'Enter a latitude from -90 to 90.';
  }
  return null;
}

String? _longitudeValidator(String? value) {
  final parsed = double.tryParse(value?.trim() ?? '');
  if (parsed == null || !parsed.isFinite || parsed < -180 || parsed > 180) {
    return 'Enter a longitude from -180 to 180.';
  }
  return null;
}

String _branchErrorMessage(Object error) {
  if (error is BranchRepositoryException) return error.message;
  return 'Branch operation failed. Check your connection and permissions.';
}
