import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

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
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
        CREATE TABLE migraine_attacks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          patient_id TEXT,
          attack_id TEXT,
          age INTEGER,
          Duration INTEGER,
          Frequency INTEGER,
          Location TEXT,
          Character TEXT,
          Intensity INTEGER,
          Nausea INTEGER,
          Vomit INTEGER,
          Phonophobia INTEGER,
          Photophobia INTEGER,
          Visual INTEGER,
          Sensory INTEGER,
          Dysphasia INTEGER,
          Dysarthria INTEGER,
          Vertigo INTEGER,
          Tinnitus INTEGER,
          Hypoacusis INTEGER,
          Diplopia INTEGER,
          Defect INTEGER,
          Ataxia INTEGER,
          Conscience INTEGER,
          Paresthesia INTEGER,
          DPF TEXT,
          Type TEXT,
          summary TEXT,
          timestamp TEXT
        )
        ''');

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
    );

    _database = db;
    return db;
  }

  Future<int> insertMigraineAttack(MigraineAttack attack) async {
    final db = await database;
    return db.insert('migraine_attacks', attack.toDbMap());
  }

  Future<List<MigraineAttack>> fetchMigraineAttacks() async {
    final db = await database;
    final rows = await db.query(
      'migraine_attacks',
      orderBy: 'timestamp DESC',
    );
    return rows.map(MigraineAttack.fromDb).toList();
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
}

