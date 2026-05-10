import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_card.dart';
import '../../core/widgets/mise_pill.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../pantry/bloc/pantry_bloc.dart';
import '../pantry/bloc/pantry_state.dart';
import '../shopping/bloc/shopping_bloc.dart';
import '../shopping/bloc/shopping_state.dart';
import '../shopping/bloc/shopping_event.dart';
import '../../core/di/household_id_provider.dart';
import '../../core/widgets/add_item_bottom_sheet.dart';
import 'package:flutter/services.dart';
import '../pantry/bloc/pantry_event.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: const [
            _Header(),
            SizedBox(height: 24),
            _OverviewCard(),
            SizedBox(height: 28),
            _ExpiringSection(),
            SizedBox(height: 28),
            _ShoppingPreview(),
            SizedBox(height: 28),
            _QuickActions(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  Future<Map<String, dynamic>> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {
        'name': 'User',
        'householdName': 'No household',
        'memberCount': 0,
      };
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final householdId = userDoc.data()?['householdId'];

    final householdDoc = await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .get();

    final householdData = householdDoc.data() ?? {};

    return {
      'name': _extractName(user.email),
      'householdName': householdData['name'] ?? '',
      'memberCount': (householdData['members'] as List?)?.length ?? 0,
    };
  }

  String _extractName(String? email) {
    if (email == null) return 'User';

    final name = email.split('@').first;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning,\n$name!';
    }

    if (hour < 17) {
      return 'Good afternoon,\n$name!';
    }

    return 'Good evening,\n$name!';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting(data['name']), style: AppTextStyles.greeting),
                  const SizedBox(height: 4),
                  Text(
                    '${data['householdName']} • ${data['memberCount']} members',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                _IconButton(icon: Icons.notifications_outlined, onTap: () {}),
                const SizedBox(width: 8),
                _IconButton(icon: Icons.add, onTap: () {}),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PantryBloc, PantryState>(
      builder: (context, pantryState) {
        return BlocBuilder<ShoppingBloc, ShoppingState>(
          builder: (context, shoppingState) {
            int pantryCount = 0;
            int expiringCount = 0;
            int shoppingCount = 0;

            if (pantryState is PantryLoaded) {
              pantryCount = pantryState.items.length;
              expiringCount = pantryState.expiringItems.length;
            }

            if (shoppingState is ShoppingLoaded) {
              shoppingCount = shoppingState.items.length;
            }

            return MiseCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(label: 'Pantry', value: pantryCount.toString()),
                  _Stat(label: 'Expiring', value: expiringCount.toString()),
                  _Stat(label: 'Shopping', value: shoppingCount.toString()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }
}

class _ShoppingPreview extends StatelessWidget {
  const _ShoppingPreview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShoppingBloc, ShoppingState>(
      builder: (context, state) {
        if (state is! ShoppingLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final previewItems = state.items.take(4).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Shopping list'),
            const SizedBox(height: 8),
            MiseCard(
              child: Column(
                children: List.generate(previewItems.length, (index) {
                  final item = previewItems[index];

                  return Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.read<ShoppingBloc>().add(
                                ShoppingItemCheckedOff(item.id),
                              );
                            },
                            child: const Icon(Icons.circle_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.name)),
                          Text('×${item.quantity}'),
                        ],
                      ),
                      if (index != previewItems.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShoppingRow extends StatelessWidget {
  final String item;

  const _ShoppingRow(this.item);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle_outlined),
        const SizedBox(width: 12),
        Text(item),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  Future<void> _addShoppingItem(BuildContext context) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add shopping item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g. Milk'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();

              if (text.isNotEmpty) {
                context.read<ShoppingBloc>().add(ShoppingItemAdded(text));
              }

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPantryItem(BuildContext context) async {
    final householdId = HouseholdIdProvider.of(context);

    if (householdId == null) return;

    final result = await showAddItemBottomSheet(context);

    if (result == null) return;

    context.read<PantryBloc>().add(
      PantryItemAdded(
        householdId: householdId,
        name: result.name,
        quantity: result.quantity,
        expiryDate: result.expiry,
      ),
    );
  }

  Future<void> _inviteRoommate(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final householdId = userDoc.data()?['householdId'];

    if (householdId == null) return;

    final householdDoc = await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .get();

    final inviteCode = householdDoc.data()?['inviteCode'];

    if (inviteCode == null) return;

    await Clipboard.setData(ClipboardData(text: inviteCode));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite code copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Quick actions'),
        const SizedBox(height: 8),
        MiseCard(
          child: Column(
            children: [
              _ActionTile(
                icon: Icons.kitchen_outlined,
                title: 'Add pantry item',
                onTap: () => _addPantryItem(context),
              ),
              const Divider(),

              _ActionTile(
                icon: Icons.shopping_cart_outlined,
                title: 'Add shopping item',
                onTap: () => _addShoppingItem(context),
              ),
              const Divider(),

              _ActionTile(
                icon: Icons.people_outline,
                title: 'Invite roommate',
                onTap: () => _inviteRoommate(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [Icon(icon), const SizedBox(width: 14), Text(title)],
        ),
      ),
    );
  }
}

class _ExpiringSection extends StatelessWidget {
  const _ExpiringSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PantryBloc, PantryState>(
      builder: (context, state) {
        if (state is! PantryLoaded || state.expiringItems.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = state.expiringItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('Expiring soon'),
            const SizedBox(height: 8),
            MiseCard(
              child: Column(
                children: items.map((item) {
                  final daysLeft = item.expiryDate!
                      .difference(DateTime.now())
                      .inDays;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name)),
                        MisePill(
                          label: '$daysLeft days',
                          variant: PillVariant.warning,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppTextStyles.label);
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSecondary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      ),
    );
  }
}
