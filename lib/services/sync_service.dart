import 'dart:async';
import '../services/database_service.dart';

typedef ProgressCallback = void Function(
    int current, int total, String message);

class SyncService {
  static Future<SyncResult> syncAll({
    ProgressCallback? onProgress,
    bool clearAfterSync = false,
  }) async {
    final pending = await DatabaseService.instance.getPendingRecords();
    final total = pending.length;

    if (total == 0) {
      return const SyncResult(
          synced: 0, failed: 0, message: 'No pending records to sync.');
    }

    int synced = 0;
    int failed = 0;

    for (int i = 0; i < pending.length; i++) {
      final record = pending[i];
      onProgress?.call(i, total, 'Syncing ${record.candidateName}...');

      try {
        // Simulate network call
        await Future.delayed(const Duration(milliseconds: 800));

        // Simulate 95% success rate
        final success = (i % 20) != 19; // fail every 20th for demo
        if (success) {
          await DatabaseService.instance.updateStatus(record.id, 'synced');
          synced++;
        } else {
          failed++;
        }
      } catch (e) {
        failed++;
      }
    }

    onProgress?.call(total, total, 'Sync complete');

    if (clearAfterSync && synced > 0) {
      await DatabaseService.instance.clearSynced();
    }

    return SyncResult(
      synced: synced,
      failed: failed,
      message:
          'Synced $synced of $total records${failed > 0 ? ' ($failed failed)' : ''}.',
    );
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final String message;

  const SyncResult({
    required this.synced,
    required this.failed,
    required this.message,
  });

  bool get isSuccess => failed == 0;
}
