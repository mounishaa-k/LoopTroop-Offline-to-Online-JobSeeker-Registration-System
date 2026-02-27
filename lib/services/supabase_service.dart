import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resume_record.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Supabase backend integration.
///
/// SETUP REQUIRED (one-time):
///   1. Create a free project at https://supabase.com
///   2. Go to Project Settings → API
///   3. Copy your Project URL → paste in kSupabaseUrl below
///   4. Copy your anon/public key → paste in kSupabaseAnonKey below
///   5. Run this SQL in Supabase SQL Editor to create the candidates table:
///
///   CREATE TABLE candidates (
///     id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
///     display_id  text,
///     name        text,
///     phone       text,
///     email       text,
///     linkedin    text,
///     education   text,
///     skills      jsonb,
///     status      text DEFAULT 'synced',
///     created_at  timestamptz DEFAULT now()
///   );
///   ALTER TABLE candidates ENABLE ROW LEVEL SECURITY;
///   CREATE POLICY "Allow insert" ON candidates FOR INSERT WITH CHECK (true);
///   CREATE POLICY "Allow select" ON candidates FOR SELECT USING (true);
///
///   6. Run this SQL to create the users table for authentication:
///
///   CREATE TABLE users (
///     id uuid REFERENCES auth.users NOT NULL PRIMARY KEY,
///     email text NOT NULL,
///     name text
///   );
///   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
///   CREATE POLICY "Allow insert on users" ON users FOR INSERT WITH CHECK (auth.uid() = id);
///   CREATE POLICY "Allow select on users" ON users FOR SELECT USING (auth.uid() = id);
///
/// ─────────────────────────────────────────────────────────────────────────────

// ⚠️ Replace with your actual Supabase project values:
const String kSupabaseUrl = 'https://gueblmlklckqhnlypvvi.supabase.co';
const String kSupabaseAnonKey =
    'sb_publishable_E6tyhVnDMiVjuweJxl9YMw_qXWvON_1';

const String _table = 'candidates';

class SupabaseService {
  static bool _initialized = false;

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    if (kSupabaseUrl.contains('YOUR_PROJECT') ||
        kSupabaseAnonKey.contains('YOUR_ANON_KEY')) {
      debugPrint(
          '[SupabaseService] ⚠️  Supabase not configured. Set kSupabaseUrl and kSupabaseAnonKey.');
      return;
    }
    if (_initialized) return;
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
    _initialized = true;
    debugPrint('[SupabaseService] ✅ Initialized');
  }

  static bool get isConfigured =>
      !kSupabaseUrl.contains('YOUR_PROJECT') &&
      !kSupabaseAnonKey.contains('YOUR_ANON_KEY') &&
      _initialized;

  static SupabaseClient get _client => Supabase.instance.client;

  /// Get current logged in user
  static User? get currentUser =>
      isConfigured ? _client.auth.currentUser : null;

  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      isConfigured ? _client.auth.onAuthStateChange : const Stream.empty();

  /// Sign up a new user (profile handled securely via Supabase trigger)
  static Future<AuthResponse> signUp(
      String email, String password, String name) async {
    if (!isConfigured) throw SupabaseSyncException('Supabase not configured');

    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  /// Sign in existing user
  static Future<AuthResponse> signIn(String email, String password) async {
    if (!isConfigured) throw SupabaseSyncException('Supabase not configured');
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    if (!isConfigured) return;
    await _client.auth.signOut();
  }

  /// Generate the next incremental display_id based on backend records
  static Future<String> getNextDisplayId() async {
    if (!isConfigured) {
      // Offline fallback if Supabase not configured
      return 'fair_${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    try {
      final response = await _client
          .from(_table)
          .select('display_id')
          .order('display_id', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        return 'fair1';
      }

      final lastId = response.first['display_id'] as String?;
      if (lastId == null || !lastId.startsWith('fair')) {
        return 'fair1';
      }

      final numberPart = lastId.replaceFirst('fair', '');
      final count = int.tryParse(numberPart);
      if (count != null) {
        return 'fair${count + 1}';
      }
      return 'fair1';
    } catch (e) {
      debugPrint('[SupabaseService] Error generating next ID: $e');
      // Fallback in case of offline/network error
      return 'fair_${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }

  /// Insert a single candidate record.
  static Future<void> insertCandidate(ResumeRecord record) async {
    if (!isConfigured) throw SupabaseSyncException('Supabase not configured');

    final ext = record.extracted;
    await _client.from(_table).insert({
      'id': record.id,
      'display_id': record.displayId,
      'name': record.candidateName,
      'phone': record.primaryPhone,
      'email': record.primaryEmail,
      'linkedin':
          ext.linkedinUrls.isNotEmpty ? ext.linkedinUrls.first.value : '',
      'education': ext.education.isNotEmpty ? ext.education.first.degree : '',
      'skills': jsonEncode(ext.skills),
      'status': 'synced',
    });
  }

  /// Sync all pending records. Returns (syncedCount, failedCount, errors).
  static Future<({int synced, int failed, List<String> errors})> syncPending(
      List<ResumeRecord> pendingRecords) async {
    if (!isConfigured) {
      throw SupabaseSyncException(
          'Supabase not configured. Please set your URL and anon key in supabase_service.dart');
    }

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    for (final record in pendingRecords) {
      try {
        await insertCandidate(record);
        synced++;
      } catch (e) {
        failed++;
        errors.add('${record.candidateName}: $e');
        debugPrint('[SupabaseService] Insert failed: $e');
      }
    }

    return (synced: synced, failed: failed, errors: errors);
  }
}

class SupabaseSyncException implements Exception {
  final String message;
  SupabaseSyncException(this.message);
  @override
  String toString() => message;
}
