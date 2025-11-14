import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plan.dart';
import '../data/local/plans_local_datasource.dart';

class PlansService {
  final PlansLocalDataSource _localDataSource;
  final FirebaseFirestore _firestore;
  
  // Cache duration - plans older than this will be refreshed
  static const Duration cacheMaxAge = Duration(minutes: 2);

  PlansService({
    PlansLocalDataSource? localDataSource,
    FirebaseFirestore? firestore,
  })  : _localDataSource = localDataSource ?? PlansLocalDataSource(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get plans with caching strategy (offline-first)
  /// 
  /// This method:
  /// 1. Always tries to return cached data first (even if stale)
  /// 2. If cache is stale or forceRefresh, attempts to fetch from Firestore
  /// 3. If Firestore fetch fails (no connection), returns stale cache
  /// 4. If no cache and no connection, returns empty list
  Future<List<Map<String, dynamic>>> getPlans({
    required String userId,
    required String visibilidad,
    required List<String> friendIds,
    bool forceRefresh = false,
  }) async {
    // Check if cache is fresh
    final isCacheFresh = await _localDataSource.isCacheFresh(
      visibilidad,
      cacheMaxAge,
    );

    // Get cached plans (even if stale) for offline-first approach
    final cachedPlans = await _localDataSource.getPlansByVisibility(visibilidad);

    // If cache is fresh and not forcing refresh, return cached data immediately
    if (isCacheFresh && !forceRefresh) {
      print('[🐧 plans service] Using fresh cached plans for $visibilidad');
      // Filter out user's own plans
      final filteredPlans = cachedPlans.where((plan) => plan.anfitrionID != userId).toList();
      return filteredPlans.map((plan) => plan.toDisplayMap()).toList();
    }

    // Cache is stale or force refresh - try to fetch from Firestore
    try {
      // Sync pending plans before fetching
      try {
        await syncPendingPlanCreations();
      } catch (e) {
        print('[🐧 plans service] Failed to sync pending plans: $e');
      }
      
      print('[🐧 plans service] Fetching plans from Firestore for $visibilidad');
      final plans = await _fetchPlansFromFirestore(
        userId: userId,
        visibilidad: visibilidad,
        friendIds: friendIds,
      );

      // Update cache with fresh data
      await _updateCache(visibilidad, plans);

      // Filter out user's own plans before returning
      final filteredPlans = plans.where((plan) => plan.anfitrionID != userId).toList();
      return filteredPlans.map((plan) => plan.toDisplayMap()).toList();
    } catch (e) {
      // Network error or Firestore error - use stale cache if available
      print('[🐧 plans service] Error fetching from Firestore: $e');
      
      if (cachedPlans.isNotEmpty) {
        print('[🐧 plans service] Using stale cache due to error (${cachedPlans.length} plans)');
        // Filter out user's own plans
        final filteredPlans = cachedPlans.where((plan) => plan.anfitrionID != userId).toList();
        return filteredPlans.map((plan) => plan.toDisplayMap()).toList();
      }
      
      // No cache available and network failed
      print('[🐧 plans service] No cache available and network failed');
      rethrow;
    }
  }

  /// Fetch plans from Firestore
  Future<List<Plan>> _fetchPlansFromFirestore({
    required String userId,
    required String visibilidad,
    required List<String> friendIds,
  }) async {
    final List<Plan> plans = [];
    final Set<String> planIds = {}; // To avoid duplicates

    if (visibilidad == "Amigos") {
      // Get plans from friends in batches (excluding user's own plans)
      if (friendIds.isNotEmpty) {
        for (var i = 0; i < friendIds.length; i += 10) {
          final batch = friendIds.sublist(
            i,
            (i + 10 > friendIds.length) ? friendIds.length : i + 10,
          );
          if (batch.isEmpty) continue;

          try {
            final snapshot = await _firestore
                .collection("planes")
                .where("visibilidad", isEqualTo: "Amigos")
                .where("anfitrionID", whereIn: batch)
                .get();

            for (var doc in snapshot.docs) {
              try {
                if (!planIds.contains(doc.id)) {
                  planIds.add(doc.id);
                  plans.add(Plan.fromFirestore(doc.id, doc.data()));
                }
              } catch (e) {
                print('[🐧 plans service] Error parsing plan ${doc.id}: $e');
              }
            }
          } catch (e) {
            print('[🐧 plans service] Error fetching batch: $e');
          }
        }
      }
    } else if (visibilidad == "Público") {
      try {
        final snapshot = await _firestore
            .collection("planes")
            .where("visibilidad", isEqualTo: "Público")
            .where("anfitrionID", isNotEqualTo: userId)
            .get();

        for (var doc in snapshot.docs) {
          try {
            plans.add(Plan.fromFirestore(doc.id, doc.data()));
          } catch (e) {
            print('[🐧 plans service] Error parsing plan ${doc.id}: $e');
          }
        }
      } catch (e) {
        print('[🐧 plans service] Error fetching public plans: $e');
      }
    }

    return plans;
  }

  /// Update cache with new plans
  Future<void> _updateCache(String visibilidad, List<Plan> plans) async {
    // Delete old plans of this visibility
    await _localDataSource.deletePlansByVisibility(visibilidad);
    
    // Insert new plans
    if (plans.isNotEmpty) {
      await _localDataSource.insertPlans(plans);
    }
    
    print('[🐧 plans service] Cache updated with ${plans.length} plans for $visibilidad');
  }

  /// Get a single plan by ID (checks cache first, then Firestore)
  Future<Map<String, dynamic>?> getPlanById(String planId) async {
    // Check cache first
    final cachedPlan = await _localDataSource.getPlanById(planId);
    if (cachedPlan != null) {
      print('[🐧 plans service] Using cached plan $planId');
      return cachedPlan.toDisplayMap();
    }

    // Fetch from Firestore
    print('[🐧 plans service] Fetching plan $planId from Firestore');
    final doc = await _firestore.collection("planes").doc(planId).get();
    if (!doc.exists) return null;

    final plan = Plan.fromFirestore(doc.id, doc.data()!);
    
    // Update cache
    await _localDataSource.insertPlan(plan);
    
    return plan.toDisplayMap();
  }

  /// Invalidate cache for a specific visibility
  Future<void> invalidateCache(String visibilidad) async {
    await _localDataSource.deletePlansByVisibility(visibilidad);
    print('[🐧 plans service] Cache invalidated for $visibilidad');
  }

  /// Invalidate all cache
  Future<void> invalidateAllCache() async {
    await _localDataSource.deleteAllPlans();
    print('[🐧 plans service] All cache invalidated');
  }

  /// Clean old cached plans (older than maxAge)
  Future<void> cleanOldCache() async {
    await _localDataSource.deleteOldCachedPlans(cacheMaxAge);
    print('[🐧 plans service] Old cache cleaned');
  }

  /// Update a plan in cache (useful after accepting/rejecting)
  Future<void> updatePlanInCache(String planId, Map<String, dynamic> updates) async {
    final cachedPlan = await _localDataSource.getPlanById(planId);
    if (cachedPlan == null) return;

    // Update specific fields
    final updatedPlan = cachedPlan.copyWith(
      participantesAceptados: updates['participantesAceptados'] as List<String>?,
      participantesRechazados: updates['participantesRechazados'] as List<String>?,
      cachedAt: DateTime.now(),
    );

    await _localDataSource.updatePlan(updatedPlan);
    print('[🐧 plans service] Plan $planId updated in cache');
  }

  /// Delete a plan from cache
  Future<void> deletePlanFromCache(String planId) async {
    await _localDataSource.deletePlan(planId);
    print('[🐧 plans service] Plan $planId deleted from cache');
  }

  /// Create a plan (works offline)
  Future<String> createPlan({
    required Map<String, dynamic> planData,
    required bool isOnline,
  }) async {
    final planId = planData['planID'] as String;

    // Convert planData to Plan model and save to cache immediately
    try {
      final plan = Plan.fromFirestore(planId, planData);
      await _localDataSource.insertPlan(plan);
      print('[🐧 plans service] Plan saved to local cache: $planId');
    } catch (e) {
      print('[🐧 plans service] Error saving to cache: $e');
    }

    if (isOnline) {
      // Try to create online
      try {
        await _firestore.collection('planes').doc(planId).set(planData);
        print('[🐧 plans service] Plan created online: $planId');
        return planId;
      } catch (e) {
        print('[🐧 plans service] Failed to create online, saving for later: $e');
        // Save for later sync
        await _localDataSource.insertPendingPlanCreation(planId, planData);
        return planId;
      }
    } else {
      // Offline mode - save for later sync
      print('[🐧 plans service] Offline mode - saving plan for later sync');
      await _localDataSource.insertPendingPlanCreation(planId, planData);
      return planId;
    }
  }

  /// Sync pending plan creations
  Future<void> syncPendingPlanCreations() async {
    final pendingPlans = await _localDataSource.getPendingPlanCreations();
    
    print('[🐧 plans service] Syncing ${pendingPlans.length} pending plans');
    
    for (var pending in pendingPlans) {
      final planId = pending['id'] as String;
      
      try {
        final planDataStr = pending['planData'] as String;
        
        // Check if it's valid JSON (starts with '{')
        if (!planDataStr.trim().startsWith('{')) {
          print('[🐧 plans service] Skipping plan $planId - old format (toString)');
          // Delete old format plans that can't be synced
          await _localDataSource.deletePendingPlanCreation(planId);
          continue;
        }
        
        // Deserialize the plan data
        final planData = jsonDecode(planDataStr) as Map<String, dynamic>;
        
        // Convert milliseconds back to Timestamp
        if (planData['fecha'] is int) {
          planData['fecha'] = Timestamp.fromMillisecondsSinceEpoch(planData['fecha'] as int);
        }
        if (planData['fecha_creacion'] is int) {
          planData['fecha_creacion'] = Timestamp.fromMillisecondsSinceEpoch(planData['fecha_creacion'] as int);
        }
        
        // Convert fechasEncuesta - handle milliseconds to Timestamp conversion for cada fecha
        if (planData['fechasEncuesta'] is List) {
          planData['fechasEncuesta'] = (planData['fechasEncuesta'] as List)
              .map((item) {
                if (item is! Map) return item;
                final itemMap = Map<String, dynamic>.from(item);
                
                // Convert fecha milliseconds to Timestamp
                if (itemMap['fecha'] is int) {
                  itemMap['fecha'] = Timestamp.fromMillisecondsSinceEpoch(itemMap['fecha'] as int);
                }
                
                return itemMap;
              })
              .toList();
        }
        
        // Convert horasEncuesta - pass through as is (already strings)
        if (planData['horasEncuesta'] is List) {
          planData['horasEncuesta'] = (planData['horasEncuesta'] as List)
              .map((item) {
                if (item is! Map) return item;
                return Map<String, dynamic>.from(item);
              })
              .toList();
        }
        
        // Convert ubicacionesEncuesta - pass through as is (already maps)
        if (planData['ubicacionesEncuesta'] is List) {
          planData['ubicacionesEncuesta'] = (planData['ubicacionesEncuesta'] as List)
              .map((item) {
                if (item is! Map) return item;
                return Map<String, dynamic>.from(item);
              })
              .toList();
        }
        
        // Upload to Firestore
        await _firestore.collection('planes').doc(planId).set(planData);
        print('[🐧 plans service] Successfully synced plan $planId');
        
        // Remove from pending
        await _localDataSource.deletePendingPlanCreation(planId);
      } catch (e) {
        print('[🐧 plans service] Failed to sync plan $planId: $e');
        // Delete problematic pending plans to avoid blocking future syncs
        try {
          await _localDataSource.deletePendingPlanCreation(planId);
          print('[🐧 plans service] Deleted problematic pending plan $planId');
        } catch (deleteError) {
          print('[🐧 plans service] Failed to delete pending plan: $deleteError');
        }
      }
    }
  }

  /// Check if there are pending plan creations
  Future<bool> hasPendingPlanCreations() async {
    final pending = await _localDataSource.getPendingPlanCreations();
    return pending.isNotEmpty;
  }

  /// Get user's own plans with caching
  Future<List<Map<String, dynamic>>> getMyPlans({
    required String userId,
    bool forceRefresh = false,
  }) async {
    // Get cached plans first (always check local DB)
    final cachedPlans = await _localDataSource.getPlansByAnfitrion(userId);
    print('[🐧 plans service] Found ${cachedPlans.length} cached plans for user $userId');

    // For "my plans", we use a special visibility key
    final cacheKey = "MisPlanes_$userId";
    
    // Check if cache is fresh
    final isCacheFresh = await _localDataSource.isCacheFresh(
      cacheKey,
      cacheMaxAge,
    );

    // If cache is fresh and not forcing refresh, return cached data
    if (isCacheFresh && !forceRefresh && cachedPlans.isNotEmpty) {
      print('[🐧 plans service] Using cached my plans');
      return cachedPlans.map((plan) => plan.toDisplayMap()).toList();
    }
    
    // If we have cached plans but cache is stale, return them while fetching
    if (cachedPlans.isNotEmpty && !forceRefresh) {
      print('[🐧 plans service] Returning cached plans while checking for updates');
      // Return cached data immediately, will update in background next time
      return cachedPlans.map((plan) => plan.toDisplayMap()).toList();
    }

    // Fetch from Firestore
    try {
      // Sync pending plans before fetching
      await syncPendingPlanCreations();
      
      print('[🐧 plans service] Fetching my plans from Firestore');
      final snapshot = await _firestore
          .collection("planes")
          .where("anfitrionID", isEqualTo: userId)
          .get();

      final plans = snapshot.docs
          .map((doc) {
            try {
              return Plan.fromFirestore(doc.id, doc.data());
            } catch (e) {
              print('[🐧 plans service] Error parsing plan ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Plan>()
          .toList();

      // Update cache - delete old plans and insert new ones
      await _localDataSource.deletePlansByAnfitrion(userId);
      if (plans.isNotEmpty) {
        await _localDataSource.insertPlans(plans);
      }

      print('[🐧 plans service] Cached ${plans.length} my plans');
      return plans.map((plan) => plan.toDisplayMap()).toList();
    } catch (e) {
      print('[🐧 plans service] Error fetching my plans: $e');
      
      // Use stale cache if available
      if (cachedPlans.isNotEmpty) {
        print('[🐧 plans service] Using stale cache (${cachedPlans.length} plans)');
        return cachedPlans.map((plan) => plan.toDisplayMap()).toList();
      }
      
      rethrow;
    }
  }
}
