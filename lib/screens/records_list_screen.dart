import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/resume_record.dart';
import '../state/app_state.dart';
import '../utils/helpers.dart';

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  String _query = '';
  String _filter = 'all'; // 'all' | 'pending' | 'synced'
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ResumeRecord> _filtered(List<ResumeRecord> records) {
    return records.where((r) {
      final matchFilter = _filter == 'all' || r.status == _filter;
      final q = _query.toLowerCase();
      final matchQuery = q.isEmpty ||
          r.candidateName.toLowerCase().contains(q) ||
          r.primaryPhone.contains(q) ||
          r.primaryEmail.toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  Future<void> _delete(BuildContext ctx, String id) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title:
            const Text('Delete record?', style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Color(0xFF8899CC))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.lowConfidence))),
        ],
      ),
    );
    if (ok == true && ctx.mounted) {
      ctx.read<AppState>().deleteRecord(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Saved Records',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone, email…',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8899CC)),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF8899CC)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _chip('All', 'all'),
                const SizedBox(width: 8),
                _chip('Pending', 'pending'),
                const SizedBox(width: 8),
                _chip('Synced', 'synced'),
              ],
            ),
          ),
          // List
          Expanded(
            child: Consumer<AppState>(
              builder: (_, state, __) {
                final items = _filtered(state.records);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_outlined,
                            color: Color(0xFF3344AA), size: 64),
                        const SizedBox(height: 16),
                        Text(
                          state.records.isEmpty
                              ? 'No records yet'
                              : 'No records match your search',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8899CC), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        if (state.records.isEmpty)
                          Text('Capture a resume to get started',
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF5566AA),
                                  fontSize: 13)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _RecordTile(
                      record: items[i],
                      onTap: () => Navigator.pushNamed(ctx, '/detail',
                          arguments: items[i]),
                      onDelete: () => _delete(ctx, items[i].id),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/capture'),
        icon: const Icon(Icons.add),
        label: Text('Add', style: GoogleFonts.inter()),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _chip(String label, String value) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: sel ? AppTheme.primaryColor : AppTheme.cardBorderColor),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: sel ? Colors.black87 : const Color(0xFF908D8A),
                fontSize: 13,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final ResumeRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _RecordTile(
      {required this.record, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPending = record.isPending;
    final statusColor =
        isPending ? AppTheme.mediumConfidence : AppTheme.highConfidence;

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.lowConfidence.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppTheme.lowConfidence),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // handled in onDelete
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    record.candidateName.isNotEmpty
                        ? record.candidateName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${record.candidateName} (${record.displayId})',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    if (record.primaryPhone.isNotEmpty)
                      Text(record.primaryPhone,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF8899CC), fontSize: 12)),
                    if (record.primaryEmail.isNotEmpty)
                      Text(record.primaryEmail,
                          style: GoogleFonts.inter(
                              color: const Color(0xFF5566AA), fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Status + time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(record.status.toUpperCase(),
                        style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 4),
                  Text(Helpers.timeAgo(record.createdAt),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF5566AA), fontSize: 10)),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF5566AA), size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
