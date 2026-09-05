import 'package:flutter/material.dart';

import '../Order/branch_repository.dart';
import '../Order/order.dart';

class BranchSelection extends StatelessWidget {
  final BranchRecord? selectedBranch;
  final BranchSnapshot? fallbackSnapshot;
  final List<BranchRecord> branches;
  final bool isLoading;
  final String? error;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  final bool isEnabled;

  const BranchSelection({
    super.key,
    required this.selectedBranch,
    this.fallbackSnapshot,
    required this.branches,
    required this.isLoading,
    required this.error,
    required this.onTap,
    required this.onRetry,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final snapshot = selectedBranch?.snapshot ?? fallbackSnapshot;
    final canSelect = isEnabled && !isLoading && branches.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Restaurant Branch',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 0, 0, 0),
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'Assigned for order',
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12.0),
        InkWell(
          onTap: canSelect ? onTap : null,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: isEnabled
                    ? const Color.fromARGB(255, 238, 238, 238)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? const Color.fromARGB(255, 245, 245, 245)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: isEnabled
                        ? const Color.fromARGB(255, 255, 160, 122)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _BranchSummary(
                    snapshot: snapshot,
                    selectedBranch: selectedBranch,
                    isLoading: isLoading,
                    error: error,
                    hasBranches: branches.isNotEmpty,
                    onRetry: onRetry,
                    isEnabled: isEnabled,
                  ),
                ),
                if (canSelect)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Icon(
                      Icons.chevron_right,
                      color: Color.fromARGB(255, 189, 189, 189),
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

class _BranchSummary extends StatelessWidget {
  final BranchSnapshot? snapshot;
  final BranchRecord? selectedBranch;
  final bool isLoading;
  final String? error;
  final bool hasBranches;
  final VoidCallback onRetry;
  final bool isEnabled;

  const _BranchSummary({
    required this.snapshot,
    required this.selectedBranch,
    required this.isLoading,
    required this.error,
    required this.hasBranches,
    required this.onRetry,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
          SizedBox(width: 10.0),
          Text('Loading branches...'),
        ],
      );
    }

    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error!,
            style: const TextStyle(color: Colors.redAccent, height: 1.3),
          ),
          const SizedBox(height: 4.0),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (snapshot == null) {
      return Text(
        hasBranches
            ? (isEnabled ? 'Select a branch' : 'Branch assigned for order')
            : 'No branches are configured yet',
        style: const TextStyle(
          color: Color.fromARGB(255, 117, 117, 117),
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          snapshot!.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
            color: isEnabled ? Colors.black87 : const Color(0xFF616161),
          ),
        ),
        if (selectedBranch != null) ...[
          const SizedBox(height: 4.0),
          Text(
            selectedBranch!.address,
            style: const TextStyle(
              color: Color.fromARGB(255, 117, 117, 117),
              fontSize: 13.0,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class BranchSelectionBottomSheet extends StatelessWidget {
  final List<BranchRecord> branches;
  final BranchRecord? selectedBranch;
  final ValueChanged<BranchRecord> onSelected;

  const BranchSelectionBottomSheet({
    super.key,
    required this.branches,
    required this.selectedBranch,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 224, 224, 224),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Choose Restaurant Branch',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12.0),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: branches.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10.0),
                itemBuilder: (context, index) {
                  final branch = branches[index];
                  final selected = branch.id == selectedBranch?.id;
                  return InkWell(
                    onTap: () => onSelected(branch),
                    borderRadius: BorderRadius.circular(14.0),
                    child: Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color.fromARGB(
                                255,
                                255,
                                160,
                                122,
                              ).withValues(alpha: 0.1)
                            : Colors.white,
                        border: Border.all(
                          color: selected
                              ? const Color.fromARGB(255, 255, 160, 122)
                              : const Color.fromARGB(255, 238, 238, 238),
                          width: selected ? 2.0 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: Color.fromARGB(255, 255, 160, 122),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  branch.address,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 117, 117, 117),
                                    fontSize: 13.0,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Color.fromARGB(255, 255, 160, 122),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
