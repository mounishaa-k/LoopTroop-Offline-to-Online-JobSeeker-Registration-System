import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/resume_record.dart';
import '../services/supabase_service.dart';

/// Central app state — single source of truth for all records.
/// Persists to SharedPreferences. Syncs to Supabase on demand.
class AppState extends ChangeNotifier {
  static const _key = 'fairtrack_records';

  List<ResumeRecord> _records = [];
  bool _syncing = false;
  String _lastSyncError = '';

  List<ResumeRecord> get records => List.unmodifiable(_records);
  List<ResumeRecord> get pendingRecords =>
      _records.where((r) => r.isPending).toList();
  int get pendingCount => pendingRecords.length;
  bool get syncing => _syncing;
  String get lastSyncError => _lastSyncError;

  /// Call once at startup to restore persisted records.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _records = list
            .map((e) => ResumeRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      _records = [];
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_records.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  /// Upsert a record by id.
  Future<void> saveRecord(ResumeRecord record) async {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      _records[idx] = record;
    } else {
      _records.insert(0, record);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
    await _persist();
  }

  /// Sync all pending records to Supabase.
  /// Returns (syncedCount, failedCount, errorMessages).
  Future<({int synced, int failed, List<String> errors})> syncAll() async {
    if (_syncing) return (synced: 0, failed: 0, errors: <String>[]);

    _syncing = true;
    _lastSyncError = '';
    notifyListeners();

    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      final pending = pendingRecords;

      if (SupabaseService.isConfigured) {
        // ── Real Supabase sync ──
        final result = await SupabaseService.syncPending(pending);
        synced = result.synced;
        failed = result.failed;
        errors = result.errors;
      } else {
        // ── Simulated sync (Supabase not configured) ──
        await Future.delayed(const Duration(seconds: 2));
        synced = pending.length;
        errors = [];
        debugPrint(
            '[AppState] Simulated sync — configure Supabase for real sync');
      }

      // Mark successfully synced records
      for (final r in pending) {
        final wasError = errors.any((e) => e.startsWith(r.candidateName));
        if (!wasError) r.status = 'synced';
      }

      // Remove synced records from local storage
      _records.removeWhere((r) => r.isSynced);
    } catch (e) {
      _lastSyncError = e.toString();
      errors.add(e.toString());
    } finally {
      _syncing = false;
      notifyListeners();
      await _persist();
    }

    return (synced: synced, failed: failed, errors: errors);
  }

  void clear() {
    _records.clear();
    notifyListeners();
    _persist();
  }
}
