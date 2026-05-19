import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// One row from `ai_chat_messages` (PainPal AI assistant tab).
class AiChatStoredMessage {
  AiChatStoredMessage({
    required this.id,
    required this.isUser,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final bool isUser;
  final String body;
  final DateTime createdAt;
}

class PainpalDatabase {
  PainpalDatabase._();

  static final PainpalDatabase instance = PainpalDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final docs = await getApplicationDocumentsDirectory();
    final dbPath = path.join(docs.path, 'painpal.db');
    final db = await openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''
        CREATE TABLE ai_chat_messages (
          id TEXT PRIMARY KEY NOT NULL,
          account_key TEXT NOT NULL,
          is_user INTEGER NOT NULL,
          body TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
        ''');

        await db.execute(
          'CREATE INDEX idx_ai_chat_account_created ON ai_chat_messages (account_key, created_at)',
        );

        await db.execute('''
        CREATE TABLE mri_scans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patient_id TEXT,
          mri_id TEXT,
          image_path TEXT,
          prediction TEXT,
          confidence REAL,
          timestamp TEXT
        )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS ai_chat_messages (
            id TEXT PRIMARY KEY NOT NULL,
            account_key TEXT NOT NULL,
            is_user INTEGER NOT NULL,
            body TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_ai_chat_account_created ON ai_chat_messages (account_key, created_at)',
          );
        }
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS migraine_attacks');
        }
      },
    );

    _database = db;
    return db;
  }

  /// Removes legacy on-device migraine rows (attacks now live in MongoDB via Next.js API).
  Future<void> clearMigraineAttacks() async {
    final db = await database;
    await db.execute('DROP TABLE IF EXISTS migraine_attacks');
  }

  Future<int> insertMriScan(MriScan scan) async {
    final db = await database;
    return db.insert('mri_scans', scan.toDbMap());
  }

  Future<List<MriScan>> fetchMriScans() async {
    final db = await database;
    final rows = await db.query('mri_scans', orderBy: 'timestamp DESC');
    return rows.map(MriScan.fromDb).toList();
  }

  /// Persisted AI assistant messages for [accountKey] (e.g. signed-in user id), newest last.
  Future<List<AiChatStoredMessage>> fetchAiChatMessages(
    String accountKey, {
    int limit = 250,
  }) async {
    final db = await database;
    final rows = await db.query(
      'ai_chat_messages',
      where: 'account_key = ?',
      whereArgs: [accountKey],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    final chronological = rows.reversed.toList();
    return chronological
        .map(
          (m) => AiChatStoredMessage(
            id: m['id']! as String,
            isUser: (m['is_user'] as int) != 0,
            body: m['body']! as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at']! as int),
          ),
        )
        .toList();
  }

  Future<void> insertAiChatMessage({
    required String accountKey,
    required String id,
    required bool isUser,
    required String body,
  }) async {
    final db = await database;
    await db.insert(
      'ai_chat_messages',
      {
        'id': id,
        'account_key': accountKey,
        'is_user': isUser ? 1 : 0,
        'body': body,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Removes oldest AI chat rows for this account beyond [keepCount] (FIFO).
  Future<void> pruneAiChatMessages(String accountKey, {int keepCount = 400}) async {
    final db = await database;
    await db.rawDelete(
      '''
      DELETE FROM ai_chat_messages
      WHERE account_key = ?
        AND id NOT IN (
          SELECT id FROM ai_chat_messages
          WHERE account_key = ?
          ORDER BY created_at DESC
          LIMIT ?
        )
      ''',
      [accountKey, accountKey, keepCount],
    );
  }
}

