import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api/api_failure.dart';
import '../../../core/app_theme.dart';
import '../../../core/state/providers.dart';
import '../../../core/widgets/app_feedback.dart';
import '../domain/assignee.dart';
import '../domain/client_type.dart';
import '../state/persons_controller.dart';

/// Add Client, from the telecaller app.
///
/// This telecaller becomes the client's telecaller — the server takes that
/// from the token — and the MR is chosen here. The region is not asked for:
/// the server files the client in the chosen MR's territory, because the MR
/// is the one who has one, and a telecaller covering several could not
/// identify it.
///
/// Both dropdowns come from the server: the kinds of client are a master an
/// admin edits, and the MR list is every active one, because handing a client
/// across territories is the point of the feature.
class ClientFormScreen extends ConsumerStatefulWidget {
  const ClientFormScreen({super.key});

  @override
  ConsumerState<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends ConsumerState<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _specialization = TextEditingController();

  ClientType? _type;
  Assignee? _mr;

  bool _busy = false;

  /// Field errors the server sent back, keyed as it named them.
  Map<String, List<String>> _serverErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _city.dispose();
    _address.dispose();
    _specialization.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busy = true;
      _serverErrors = const {};
    });

    try {
      await ref.read(personsRepositoryProvider).create(
        name: _name.text,
        type: _type!.slug,
        mobile: _mobile.text,
        mrId: _mr!.id,
        email: _email.text,
        city: _city.text,
        address: _address.text,
        // Only sent for a kind that keeps one; the server nulls it on the
        // others anyway, and this keeps the two from disagreeing.
        specialization: _type!.hasSpecialization ? _specialization.text : null,
      );

      invalidateClientLists(ref);

      if (mounted) {
        showNotice(context, 'Client added.');
        Navigator.of(context).pop();
      }
    } on ApiFailure catch (failure) {
      setState(() => _serverErrors = failure.fieldErrors);
      if (mounted) showNotice(context, failure.message, isError: true);
    } on Object catch (error) {
      if (mounted) showNotice(context, describeError(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = ref.watch(clientTypesProvider);
    final mrs = ref.watch(assignableMrsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add client')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  errorText: _serverErrors['name']?.first,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter the client\'s name'
                    : null,
              ),
              const SizedBox(height: 14),
              types.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () => ref.invalidate(clientTypesProvider),
                ),
                data: (list) => DropdownButtonFormField<ClientType>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    prefixIcon: const Icon(Icons.category_outlined),
                    errorText: _serverErrors['type']?.first,
                  ),
                  items: [
                    for (final type in list)
                      DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _type = value),
                  validator: (value) =>
                      value == null ? 'Pick what kind of client this is' : null,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  // The server refuses a number already on the books; that
                  // arrives here rather than only in a snackbar.
                  errorText: _serverErrors['mobile']?.first,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? 'Enter a mobile number'
                    : null,
              ),
              // Only the kinds flagged for it carry one — a doctor does, a
              // medical store does not.
              if (_type?.hasSpecialization ?? false) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _specialization,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Specialization (optional)',
                    prefixIcon: const Icon(Icons.medical_services_outlined),
                    errorText: _serverErrors['specialization']?.first,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: const Icon(Icons.mail_outline),
                  errorText: _serverErrors['email']?.first,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'City (optional)',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  errorText: _serverErrors['city']?.first,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _address,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: 'Address (optional)',
                  alignLabelWithHint: true,
                  errorText: _serverErrors['address']?.first,
                ),
              ),
              const SizedBox(height: 4),
              mrs.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => ErrorPanel(
                  error: error,
                  onRetry: () => ref.invalidate(assignableMrsProvider),
                ),
                data: (list) => DropdownButtonFormField<Assignee>(
                  initialValue: _mr,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Assign to medical rep',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    errorText: _serverErrors['assigned_mr_id']?.first,
                  ),
                  items: [
                    for (final person in list)
                      DropdownMenuItem(
                        value: person,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              person.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Where they work. This matters more here than in
                            // the other app: the client is filed in the
                            // region of whichever rep is chosen.
                            Text(
                              person.subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _mr = value),
                  validator: (value) => value == null
                      ? 'Pick the medical rep who will visit this client'
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save client'),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be the telecaller on this client, and it will be '
                'filed in the region of the rep you choose.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
