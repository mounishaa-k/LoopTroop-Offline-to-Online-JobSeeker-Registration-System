import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants.dart';
import '../models/resume_record.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) => db.execute('''
        CREATE TABLE ${AppConstants.tableRecords} (
          id TEXT PRIMARY KEY,
          display_id TEXT,
          raw_text TEXT,
          pages_texts TEXT,
          images TEXT,
          extracted TEXT,
          extraction_metadata TEXT,
          status TEXT DEFAULT 'pending',
          created_at TEXT,
          updated_at TEXT
        )
      '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE ${AppConstants.tableRecords} ADD COLUMN display_id TEXT');
        }
      },
    );
  }

  Future<void> insertRecord(ResumeRecord record) async {
    final db = await database;
    final json = record.toJson();
    await db.insert(
      AppConstants.tableRecords,
      {
        'id': json['id'],
        'display_id': json['display_id'],
        'raw_text': json['raw_text'],
        'pages_texts': jsonEncode(json['pages_texts']),
        'images': jsonEncode(json['images']),
        'extracted': jsonEncode(json['extracted']),
        'extraction_metadata': jsonEncode(json['extraction_metadata']),
        'status': json['status'],
        'created_at': json['created_at'],
        'updated_at': json['updated_at'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateRecord(ResumeRecord record) async {
    final db = await database;
    final json = record.toJson();
    await db.update(
      AppConstants.tableRecords,
      {
        'raw_text': json['raw_text'],
        'pages_texts': jsonEncode(json['pages_texts']),
        'images': jsonEncode(json['images']),
        'extracted': jsonEncode(json['extracted']),
        'extraction_metadata': jsonEncode(json['extraction_metadata']),
        'status': json['status'],
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await database;
    await db.update(
      AppConstants.tableRecords,
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db
        .delete(AppConstants.tableRecords, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearSynced() async {
    final db = await database;
    await db.delete(AppConstants.tableRecords,
        where: 'status = ?', whereArgs: ['synced']);
  }

  Future<ResumeRecord?> getRecord(String id) async {
    final db = await database;
    final rows = await db
        .query(AppConstants.tableRecords, where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _rowToRecord(rows.first);
  }

  Future<List<ResumeRecord>> getAllRecords() async {
    final db = await database;
    final rows =
        await db.query(AppConstants.tableRecords, orderBy: 'created_at DESC');
    return rows.map(_rowToRecord).toList();
  }

  Future<List<ResumeRecord>> getPendingRecords() async {
    final db = await database;
    final rows = await db.query(AppConstants.tableRecords,
        where: 'status = ?', whereArgs: ['pending'], orderBy: 'created_at ASC');
    return rows.map(_rowToRecord).toList();
  }

  Future<int> countPending() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM ${AppConstants.tableRecords} WHERE status='pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  ResumeRecord _rowToRecord(Map<String, dynamic> row) {
    final json = {
      'id': row['id'],
      'display_id': row['display_id'],
      'raw_text': row['raw_text'],
      'pages_texts': jsonDecode(row['pages_texts'] as String? ?? '[]'),
      'images': jsonDecode(row['images'] as String? ?? '[]'),
      'extracted': jsonDecode(row['extracted'] as String? ?? '{}'),
      'extraction_metadata':
          jsonDecode(row['extraction_metadata'] as String? ?? '{}'),
      'status': row['status'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    };
    return ResumeRecord.fromJson(json);
  }
}
