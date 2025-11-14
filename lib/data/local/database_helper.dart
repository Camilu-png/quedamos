import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('quedamos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE friends (
        id $idType,
        name $textType,
        email $textType,
        photoUrl $textTypeNullable,
        localPhotoPath $textTypeNullable,
        addedAt $intType,
        isSynced $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE friend_requests (
        id $idType,
        from_user $textType,
        to_user $textType,
        name $textType,
        email $textType,
        photoUrl $textTypeNullable,
        localPhotoPath $textTypeNullable,
        status $textType,
        createdAt $intType,
        isSynced $intType
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_friend_requests_status ON friend_requests(status)
    ''');

    await db.execute('''
      CREATE TABLE pending_deletions (
        id $idType,
        currentUserId $textType,
        friendId $textType,
        createdAt $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_acceptances (
        id $idType,
        currentUserId $textType,
        requestData $textType,
        createdAt $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE pending_plan_creations (
        id $idType,
        planData $textType,
        createdAt $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE plans (
        id $idType,
        anfitrionID $textType,
        anfitrionNombre $textType,
        titulo $textType,
        descripcion $textTypeNullable,
        iconoNombre $textType,
        iconoColor $textType,
        visibilidad $textType,
        fecha $intType,
        fechaEsEncuesta $intType,
        fechasEncuesta $textTypeNullable,
        hora $textTypeNullable,
        horaEsEncuesta $intType,
        horasEncuesta $textTypeNullable,
        ubicacion $textTypeNullable,
        ubicacionEsEncuesta $intType,
        participantesAceptados $textType,
        participantesRechazados $textType,
        createdAt $intType,
        updatedAt INTEGER,
        cachedAt $intType,
        isSynced $intType
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_plans_visibilidad ON plans(visibilidad)
    ''');

    await db.execute('''
      CREATE INDEX idx_plans_anfitrion ON plans(anfitrionID)
    ''');

    await db.execute('''
      CREATE INDEX idx_plans_cached_at ON plans(cachedAt)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add localPhotoPath column to friends table
      await db.execute('''
        ALTER TABLE friends ADD COLUMN localPhotoPath TEXT
      ''');

      // Add localPhotoPath column to friend_requests table
      await db.execute('''
        ALTER TABLE friend_requests ADD COLUMN localPhotoPath TEXT
      ''');
    }
    
    if (oldVersion < 3) {
      // Create pending_deletions table
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';
      
      await db.execute('''
        CREATE TABLE pending_deletions (
          id $idType,
          currentUserId $textType,
          friendId $textType,
          createdAt $intType
        )
      ''');
    }
    
    if (oldVersion < 4) {
      // Create pending_acceptances table
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';
      
      await db.execute('''
        CREATE TABLE pending_acceptances (
          id $idType,
          currentUserId $textType,
          requestData $textType,
          createdAt $intType
        )
      ''');
    }
    
    if (oldVersion < 5) {
      // Create plans table
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';
      const textTypeNullable = 'TEXT';
      
      await db.execute('''
        CREATE TABLE plans (
          id $idType,
          anfitrionID $textType,
          anfitrionNombre $textType,
          titulo $textType,
          descripcion $textTypeNullable,
          iconoNombre $textType,
          iconoColor $textType,
          visibilidad $textType,
          fecha $intType,
          fechaEsEncuesta $intType,
          fechasEncuesta $textTypeNullable,
          hora $textTypeNullable,
          horaEsEncuesta $intType,
          horasEncuesta $textTypeNullable,
          ubicacion $textTypeNullable,
          ubicacionEsEncuesta $intType,
          participantesAceptados $textType,
          participantesRechazados $textType,
          createdAt $intType,
          updatedAt INTEGER,
          cachedAt $intType,
          isSynced $intType
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_visibilidad ON plans(visibilidad)
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_anfitrion ON plans(anfitrionID)
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_cached_at ON plans(cachedAt)
      ''');
    }
    
    if (oldVersion < 6) {
      // Fix plans table - make updatedAt nullable
      // SQLite doesn't support ALTER COLUMN, so we need to recreate the table
      await db.execute('DROP TABLE IF EXISTS plans');
      
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';
      const textTypeNullable = 'TEXT';
      
      await db.execute('''
        CREATE TABLE plans (
          id $idType,
          anfitrionID $textType,
          anfitrionNombre $textType,
          titulo $textType,
          descripcion $textTypeNullable,
          iconoNombre $textType,
          iconoColor $textType,
          visibilidad $textType,
          fecha $intType,
          fechaEsEncuesta $intType,
          fechasEncuesta $textTypeNullable,
          hora $textTypeNullable,
          horaEsEncuesta $intType,
          horasEncuesta $textTypeNullable,
          ubicacion $textTypeNullable,
          ubicacionEsEncuesta $intType,
          participantesAceptados $textType,
          participantesRechazados $textType,
          createdAt $intType,
          updatedAt INTEGER,
          cachedAt $intType,
          isSynced $intType
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_visibilidad ON plans(visibilidad)
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_anfitrion ON plans(anfitrionID)
      ''');

      await db.execute('''
        CREATE INDEX idx_plans_cached_at ON plans(cachedAt)
      ''');
    }
    
    if (oldVersion < 7) {
      // Create pending_plan_creations table for offline plan creation
      const idType = 'TEXT PRIMARY KEY';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';
      
      await db.execute('''
        CREATE TABLE pending_plan_creations (
          id $idType,
          planData $textType,
          createdAt $intType
        )
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('ALTER TABLE plans ADD COLUMN fechasEncuesta TEXT');
    }

    if (oldVersion < 9) {
      await db.execute('ALTER TABLE plans ADD COLUMN horasEncuesta TEXT');
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
