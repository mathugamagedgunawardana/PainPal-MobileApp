import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

const int _dbVersion = 2;

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
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _database = db;
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
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
      timestamp TEXT,
      triggers TEXT,
      attack_start_time TEXT,
      attack_end_time TEXT
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

    await db.execute('''
    CREATE TABLE medications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      attack_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      dosage TEXT NOT NULL,
      time_taken TEXT NOT NULL,
      effectiveness INTEGER NOT NULL,
      FOREIGN KEY (attack_id) REFERENCES migraine_attacks(id)
    )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE migraine_attacks ADD COLUMN triggers TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE migraine_attacks ADD COLUMN attack_start_time TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE migraine_attacks ADD COLUMN attack_end_time TEXT');
      } catch (_) {}
      await db.execute('''
      CREATE TABLE IF NOT EXISTS medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attack_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        time_taken TEXT NOT NULL,
        effectiveness INTEGER NOT NULL,
        FOREIGN KEY (attack_id) REFERENCES migraine_attacks(id)
      )
      ''');
    }
  }

  Future<int> insertMigraineAttack(MigraineAttack attack) async {
    final db = await database;
    final map = attack.toDbMap();
    map.remove('id');
    final id = await db.insert('migraine_attacks', map);
    for (final med in attack.medications) {
      await db.insert('medications', MedicationEntry(
        attackId: id,
        name: med.name,
        dosage: med.dosage,
        timeTaken: med.timeTaken,
        effectiveness: med.effectiveness,
      ).toDbMap());
    }
    return id;
  }

  Future<List<MedicationEntry>> fetchMedicationsForAttack(int attackId) async {
    final db = await database;
    final rows = await db.query(
      'medications',
      where: 'attack_id = ?',
      whereArgs: [attackId],
    );
    return rows.map(MedicationEntry.fromDb).toList();
  }

  Future<List<MigraineAttack>> fetchMigraineAttacks() async {
    final db = await database;
    final rows = await db.query(
      'migraine_attacks',
      orderBy: 'timestamp DESC',
    );
    final result = <MigraineAttack>[];
    for (final row in rows) {
      final attack = MigraineAttack.fromDb(row);
      if (attack.id != null) {
        final meds = await fetchMedicationsForAttack(attack.id!);
        result.add(attack.copyWith(medications: meds));
      } else {
        result.add(attack);
      }
    }
    return result;
  }

  Future<void> updateMigraineAttack(int id, MigraineAttack attack) async {
    final db = await database;
    final map = attack.toDbMap();
    map.remove('id');
    await db.update('migraine_attacks', map, where: 'id = ?', whereArgs: [id]);
    await db.delete('medications', where: 'attack_id = ?', whereArgs: [id]);
    for (final med in attack.medications) {
      await db.insert('medications', MedicationEntry(
        attackId: id,
        name: med.name,
        dosage: med.dosage,
        timeTaken: med.timeTaken,
        effectiveness: med.effectiveness,
      ).toDbMap());
    }
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

