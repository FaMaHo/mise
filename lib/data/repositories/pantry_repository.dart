import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../local/database.dart';
import 'package:drift/drift.dart' as drift;

class PantryRepository {
  final AppDatabase _db;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  PantryRepository(this._db);

  String? get _householdId => null; // wired in step 5

  // ── Watch all pantry items (stream from Drift) ──────────────────────────
  Stream<List<PantryItem>> watchItems(String householdId) {
    return (_db.select(_db.pantryItems)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => drift.OrderingTerm.asc(t.addedAt)]))
        .watch();
  }

  // ── Watch expiring items (within N days) ─────────────────────────────────
  Stream<List<PantryItem>> watchExpiringItems(
    String householdId, {
    int withinDays = 3,
  }) {
    final cutoff = DateTime.now().add(Duration(days: withinDays));
    return (_db.select(_db.pantryItems)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.expiryDate.isSmallerOrEqualValue(cutoff) &
                t.expiryDate.isNotNull(),
          )
          ..orderBy([(t) => drift.OrderingTerm.asc(t.expiryDate)]))
        .watch();
  }

  // ── Add item (offline-first) ─────────────────────────────────────────────
  Future<void> addItem({
    required String householdId,
    required String name,
    String? barcode,
    int quantity = 1,
    String? unit,
    DateTime? expiryDate,
  }) async {
    final userId = _auth.currentUser?.uid ?? 'unknown';
    final id = const Uuid().v4();
    final now = DateTime.now();

    // 1. Write to Drift immediately (isSynced = false)
    await _db.into(_db.pantryItems).insert(
      PantryItemsCompanion.insert(
        id: id,
        householdId: householdId,
        name: name,
        barcode: barcode != null
            ? drift.Value(barcode)
            : const drift.Value.absent(),
        quantity: drift.Value(quantity),
        unit: unit != null ? drift.Value(unit) : const drift.Value.absent(),
        expiryDate: expiryDate != null
            ? drift.Value(expiryDate)
            : const drift.Value.absent(),
        addedAt: now,
        addedByUserId: userId,
        isSynced: const drift.Value(false),
      ),
    );

    // 2. Push to Firestore
    try {
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('pantryItems')
          .doc(id)
          .set({
        'id': id,
        'householdId': householdId,
        'name': name,
        'barcode': barcode,
        'quantity': quantity,
        'unit': unit,
        'expiryDate':
            expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
        'addedAt': Timestamp.fromDate(now),
        'addedByUserId': userId,
      });

      // 3. Mark as synced
      await (_db.update(_db.pantryItems)
            ..where((t) => t.id.equals(id)))
          .write(const PantryItemsCompanion(
        isSynced: drift.Value(true),
      ));
    } catch (_) {
      // Offline — stays isSynced=false, will sync later
    }
  }

  // ── Remove item ───────────────────────────────────────────────────────────
  Future<void> removeItem(String itemId, String householdId) async {
    await (_db.delete(_db.pantryItems)
          ..where((t) => t.id.equals(itemId)))
        .go();

    try {
      await _firestore
          .collection('households')
          .doc(householdId)
          .collection('pantryItems')
          .doc(itemId)
          .delete();
    } catch (_) {}
  }

  // ── Sync unsynced items (call on reconnect) ───────────────────────────────
  Future<void> syncPending(String householdId) async {
    final unsynced = await (_db.select(_db.pantryItems)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.isSynced.equals(false),
          ))
        .get();

    for (final item in unsynced) {
      try {
        await _firestore
            .collection('households')
            .doc(householdId)
            .collection('pantryItems')
            .doc(item.id)
            .set({
          'id': item.id,
          'householdId': item.householdId,
          'name': item.name,
          'barcode': item.barcode,
          'quantity': item.quantity,
          'unit': item.unit,
          'expiryDate': item.expiryDate != null
              ? Timestamp.fromDate(item.expiryDate!)
              : null,
          'addedAt': Timestamp.fromDate(item.addedAt),
          'addedByUserId': item.addedByUserId,
        });

        await (_db.update(_db.pantryItems)
              ..where((t) => t.id.equals(item.id)))
            .write(const PantryItemsCompanion(
          isSynced: drift.Value(true),
        ));
      } catch (_) {}
    }
  }

  // ── Listen to Firestore and sync to Drift (realtime) ─────────────────────
  Stream<void> listenToFirestore(String householdId) {
    return _firestore
        .collection('households')
        .doc(householdId)
        .collection('pantryItems')
        .snapshots()
        .asyncMap((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existing = await (_db.select(_db.pantryItems)
              ..where((t) => t.id.equals(doc.id)))
            .getSingleOrNull();

        if (existing == null) {
          await _db.into(_db.pantryItems).insertOnConflictUpdate(
            PantryItemsCompanion.insert(
              id: data['id'],
              householdId: data['householdId'],
              name: data['name'],
              barcode: data['barcode'] != null
                  ? drift.Value(data['barcode'])
                  : const drift.Value.absent(),
              quantity: drift.Value(data['quantity'] ?? 1),
              unit: data['unit'] != null
                  ? drift.Value(data['unit'])
                  : const drift.Value.absent(),
              expiryDate: data['expiryDate'] != null
                  ? drift.Value(
                      (data['expiryDate'] as Timestamp).toDate(),
                    )
                  : const drift.Value.absent(),
              addedAt: (data['addedAt'] as Timestamp).toDate(),
              addedByUserId: data['addedByUserId'] ?? '',
              isSynced: const drift.Value(true),
            ),
          );
        }
      }
    });
  }
  Stream<List<ShoppingListItem>> watchShoppingItems(String householdId) {
  return (_db.select(_db.shoppingListItems)
        ..where((t) => t.householdId.equals(householdId))
        ..orderBy([(t) => drift.OrderingTerm.asc(t.addedAt)]))
      .watch();
}

Future<void> toggleShoppingItem(String itemId, bool isChecked) async {
  await (_db.update(_db.shoppingListItems)
        ..where((t) => t.id.equals(itemId)))
      .write(ShoppingListItemsCompanion(isChecked: drift.Value(isChecked)));
}
}
