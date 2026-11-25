import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Bounded Firestore reads for snappy UI.
/// - Prefers cache for first paint when available
/// - Always times out so loaders can't hang forever
/// - Safe for rules denials / offline emulator glitches
class SafeFirestore {
  SafeFirestore._();

  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration cacheTimeout = Duration(milliseconds: 600);

  /// Query get with timeout. Optionally paint from cache first via [onCache].
  static Future<QuerySnapshot<Map<String, dynamic>>> getQuery(
    Query<Map<String, dynamic>> query, {
    Duration timeout = defaultTimeout,
    void Function(QuerySnapshot<Map<String, dynamic>> snap)? onCache,
  }) async {
    if (onCache != null) {
      try {
        final cached = await query
            .get(const GetOptions(source: Source.cache))
            .timeout(cacheTimeout);
        if (cached.docs.isNotEmpty) {
          onCache(cached);
        }
      } catch (_) {
        // Cache miss / empty — fall through to network.
      }
    }

    try {
      return await query.get().timeout(timeout);
    } on TimeoutException {
      // Last resort: whatever is in local persistence.
      try {
        return await query
            .get(const GetOptions(source: Source.cache))
            .timeout(cacheTimeout);
      } catch (_) {
        rethrow;
      }
    }
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
    DocumentReference<Map<String, dynamic>> ref, {
    Duration timeout = defaultTimeout,
  }) async {
    try {
      final cached = await ref
          .get(const GetOptions(source: Source.cache))
          .timeout(cacheTimeout);
      if (cached.exists) return cached;
    } catch (_) {}

    try {
      return await ref.get().timeout(timeout);
    } on TimeoutException {
      return ref.get(const GetOptions(source: Source.cache));
    }
  }

  /// Run several loads in parallel; each failure is isolated.
  static Future<void> parallel(Iterable<Future<void> Function()> tasks) {
    return Future.wait(
      tasks.map((t) async {
        try {
          await t();
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ SafeFirestore.parallel task failed: $e');
        }
      }),
    );
  }
}
