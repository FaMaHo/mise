import 'package:drift/drift.dart' as drift;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';

class ShoppingRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  ShoppingRepository(this._db);

  // ── Watch all items for a household ───────────────────────────────────────

  Stream<List<ShoppingListItem>> watchItems(String householdId) {
    return (_db.select(_db.shoppingListItems)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([
            (t) => drift.OrderingTerm(
                  expression: t.addedAt,
                  mode: drift.OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  // ── Add item ──────────────────────────────────────────────────────────────

  Future<void> addItem({
    required String householdId,
    required String name,
    int quantity = 1,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.shoppingListItems).insert(
          ShoppingListItemsCompanion(
            id: drift.Value(id),
            householdId: drift.Value(householdId),
            name: drift.Value(name),
            quantity: drift.Value(quantity),
            isChecked: const drift.Value(false),
            isSynced: const drift.Value(false),
            addedByUserId: const drift.Value(''),
            addedAt: drift.Value(now),
          ),
        );

    // push to Firestore
    _firestore
        .collection('households')
        .doc(householdId)
        .collection('shoppingList')
        .doc(id)
        .set({
      'name': name,
      'quantity': quantity,
      'isChecked': false,
      'addedAt': now.toIso8601String(),
    }).then((_) {
      (_db.update(_db.shoppingListItems)
            ..where((t) => t.id.equals(id)))
          .write(const ShoppingListItemsCompanion(
            isSynced: drift.Value(true),
          ));
    }).catchError((_) {/* stays unsynced, retry later */});
  }

  // ── Check off item → removes from shopping list ───────────────────────────
  // Caller is responsible for adding to pantry after this returns the item name

  Future<ShoppingListItem?> checkOffItem(String itemId) async {
    final items = await (_db.select(_db.shoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .get();
    if (items.isEmpty) return null;
    final item = items.first;

    await (_db.delete(_db.shoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .go();

    _firestore
        .collection('households')
        .doc(item.householdId)
        .collection('shoppingList')
        .doc(itemId)
        .delete()
        .catchError((_) {});

    return item;
  }

  // ── Delete without checking off ───────────────────────────────────────────

  Future<void> deleteItem(String itemId, String householdId) async {
    await (_db.delete(_db.shoppingListItems)
          ..where((t) => t.id.equals(itemId)))
        .go();

    _firestore
        .collection('households')
        .doc(householdId)
        .collection('shoppingList')
        .doc(itemId)
        .delete()
        .catchError((_) {});
  }

  // ── Firestore realtime sync ───────────────────────────────────────────────

  void listenToFirestore(String householdId) {
    _firestore
        .collection('households')
        .doc(householdId)
        .collection('shoppingList')
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;
        final id = change.doc.id;

        if (change.type == DocumentChangeType.removed) {
          await (_db.delete(_db.shoppingListItems)
                ..where((t) => t.id.equals(id)))
              .go();
        } else {
          await _db
              .into(_db.shoppingListItems)
              .insertOnConflictUpdate(ShoppingListItemsCompanion(
                id: drift.Value(id),
                householdId: drift.Value(householdId),
                name: drift.Value(data['name'] as String),
                quantity: drift.Value((data['quantity'] as int?) ?? 1),
                isChecked: drift.Value((data['isChecked'] as bool?) ?? false),
                isSynced: const drift.Value(true),
                addedByUserId: const drift.Value(''),
                addedAt: drift.Value(
                  data['addedAt'] != null
                      ? DateTime.parse(data['addedAt'] as String)
                      : DateTime.now(),
                ),
              ));
        }
      }
    });
  }
}