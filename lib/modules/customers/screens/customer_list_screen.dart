import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_text_field.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiAsync = ref.watch(apiServiceProvider);
    return apiAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text('Failed to initialise API. Please restart the app.',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
      data: (api) => _CustomerListView(api: api),
    );
  }
}

class _CustomerListView extends ConsumerStatefulWidget {
  final ApiService api;
  const _CustomerListView({required this.api});

  @override
  ConsumerState<_CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends ConsumerState<_CustomerListView> {
  final searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, dynamic>> _customers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
    _fetchCustomers();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchQuery = searchController.text.trim());
      _fetchCustomers();
    });
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await widget.api.dio.get(
        '/customers',
        queryParameters: _searchQuery.isEmpty ? null : {'search': _searchQuery},
      );
      if (mounted) {
        setState(() {
          _customers = (response.data as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: CustomTextField(
              controller: searchController,
              label: 'Search Customers',
              icon: Icons.search,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _customers.isEmpty
                ? const Center(child: Text('No customers found'))
                : RefreshIndicator(
                    onRefresh: _fetchCustomers,
                    color: const Color(0xFF1A73E8),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _customers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final c = _customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A73E8),
                            child: Text(
                              (c['name'] ?? '')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(c['name'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            '${c['phone'] ?? ''}${(c['area'] ?? c['city'] ?? '') != '' ? ' • ' : ''}${c['area'] ?? c['city'] ?? ''}',
                          ),
                          trailing: Icon(Icons.chevron_right,
                              color: Theme.of(context).colorScheme.outlinedButton),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Customer: ${c['name']} — Detail view coming soon'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}