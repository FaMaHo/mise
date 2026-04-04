import 'package:drift/drift.dart';

class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()(); // e.g. "kg", "L", "pcs"
  DateTimeColumn get expiryDate => dateTime().nullable()();
  DateTimeColumn get addedAt => dateTime()();
  TextColumn get addedByUserId => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}