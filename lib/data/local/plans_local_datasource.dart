import 'package:sqflite/sqflite.dart';
import '../../models/plan.dart';
import 'database_helper.dart';

class PlansLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert single plan
  Future<void> insertPlan(Plan plan) async {
    final db = await _dbHelper.database;
    await db.insert(
      'plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert multiple plans (batch operation)
  Future<void> insertPlans(List<Plan> plans) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var plan in plans) {
      batch.insert(
        'plans',
        plan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Get all plans
  Future<List<Plan>> getAllPlans() async {
    final db = await _dbHelper.database;
    final result = await db.query('plans', orderBy: 'cachedAt DESC');
    return result.map((map) => Plan.fromMap(map)).toList();
  }

  // Get plans by visibility
  Future<List<Plan>> getPlansByVisibility(String visibilidad) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'plans',
      where: 'visibilidad = ?',
      whereArgs: [visibilidad],
      orderBy: 'cachedAt DESC',
    );
    return result.map((map) => Plan.fromMap(map)).toList();
  }

  // Get plans by anfitrion (host)
  Future<List<Plan>> getPlansByAnfitrion(String anfitrionID) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'plans',
      where: 'anfitrionID = ?',
      whereArgs: [anfitrionID],
      orderBy: 'cachedAt DESC',
    );
    return result.map((map) => Plan.fromMap(map)).toList();
  }

  // Get plan by ID
  Future<Plan?> getPlanById(String id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Plan.fromMap(result.first);
  }

  // Update plan
  Future<void> updatePlan(Plan plan) async {
    final db = await _dbHelper.database;
    await db.update(
      'plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // Delete plan
  Future<void> deletePlan(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all plans
  Future<void> deleteAllPlans() async {
    final db = await _dbHelper.database;
    await db.delete('plans');
  }

  // Delete plans by visibility
  Future<void> deletePlansByVisibility(String visibilidad) async {
    final db = await _dbHelper.database;
    await db.delete(
      'plans',
      where: 'visibilidad = ?',
      whereArgs: [visibilidad],
    );
  }

  // Delete plans by anfitrion
  Future<void> deletePlansByAnfitrion(String anfitrionID) async {
    final db = await _dbHelper.database;
    await db.delete(
      'plans',
      where: 'anfitrionID = ?',
      whereArgs: [anfitrionID],
    );
  }

  // Delete old cached plans (older than specified duration)
  Future<void> deleteOldCachedPlans(Duration maxAge) async {
    final db = await _dbHelper.database;
    final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    await db.delete(
      'plans',
      where: 'cachedAt < ?',
      whereArgs: [cutoffTime],
    );
  }

  // Get cache age for a specific visibility type
  Future<DateTime?> getCacheAge(String visibilidad) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'plans',
      columns: ['cachedAt'],
      where: 'visibilidad = ?',
      whereArgs: [visibilidad],
      orderBy: 'cachedAt DESC',
      limit: 1,
    );
    
    if (result.isEmpty) return null;
    return DateTime.fromMillisecondsSinceEpoch(result.first['cachedAt'] as int);
  }

  // Check if cache is fresh (within specified duration)
  Future<bool> isCacheFresh(String visibilidad, Duration maxAge) async {
    final cacheAge = await getCacheAge(visibilidad);
    if (cacheAge == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(cacheAge);
    return difference < maxAge;
  }
}
