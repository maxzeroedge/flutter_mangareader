import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:uuid/uuid.dart';

import 'mangareader.dart';

class MangaReaderData{
	String id;
	String url;
	String name;
	String levelType;
	MangaReaderData parent;
	List<MangaReaderData> children;
	MangaReaderData({String url, String name, MangaReaderData parent, String isCurrentPage, String id, String levelType}){
		this.url = url;
		this.name = name;
		this.parent = parent;
		if(id != null){
			this.id = id;
		}
    this.levelType = levelType;
	}

	List<dynamic> getChild({String url, String name}){
		int childIndex = children.indexWhere( (mangaReaderData) => mangaReaderData.name == name || mangaReaderData.url == url ); 
		// return remove && childIndex > -1 ? children.removeAt(childIndex) : children[childIndex];
		if(childIndex > -1){
			return [children[childIndex], childIndex];
		} else {
			return [null, childIndex];
		}
	}

	Map<String, dynamic> toMap(){
		return Map.from({
			"url": this.url,
			"name": this.name,
			"id": this.id != null ? this.id : Uuid().v4(),
			"parent": this.parent != null ? this.parent.id : 'empty',
      "levelType": this.levelType
		});
	}

	static MangaReaderData fromMap(Map<String, dynamic> args){
		if(args == null){
			return MangaReaderData();
		}
		return MangaReaderData(
			id: args["id"],
			url: args["url"],
			name: args["name"]
		);
	}

	bool operator ==(obj) => (obj.name != null && obj.name == this.name) || (obj.url != null && obj.url == this.url);

	String toString() => "[${this.id}] ${this.name} at ${this.url}";
}


class MangaReaderDBHandler {
	Database database;

	static Future<Database> openConnection() async{
		await MangaReaderParser.getStoragePermissions();
		Directory downloadsContent = await DownloadsPathProvider.downloadsDirectory;
		String dbPath = join(downloadsContent.path, "mangareader");
		// dbPath = join( await getDatabasesPath() , 'mangareader_zero.db');
		dbPath = join(dbPath, 'mangareader_zero.db');
		return await openDatabase(
			// Set the path to the database. Note: Using the `join` function from the
			// `path` package is best practice to ensure the path is correctly
			// constructed for each platform.
			dbPath,
			onCreate: (db, version) {
				// Run the CREATE TABLE statement on the database.
				return db.execute(
				'''CREATE TABLE MangaReaderData(
					id TEXT PRIMARY KEY UNIQUE, 
					url TEXT UNIQUE, 
					name TEXT, 
					levelType TEXT, 
					parent TEXT,
					FOREIGN KEY (parent) REFERENCES MangaReaderData(id)
						ON DELETE NO ACTION ON UPDATE NO ACTION )''',
				);
			},
			// Set the version. This executes the onCreate function and provides a
			// path to perform database upgrades and downgrades.
			version: 1,
		);
	}

	static void insertIntoDB(MangaReaderData mangaReaderData) async {
		Database database = await MangaReaderDBHandler.openConnection();
		database.insert(
			"MangaReaderData", 
			mangaReaderData.toMap(),
				conflictAlgorithm: ConflictAlgorithm.replace
		);
		await database.close();
	}

	static Future<List<MangaReaderData>> getAllParentsFromDB() async {
		Database database = await MangaReaderDBHandler.openConnection();
		try{
			List<Map<String, dynamic>> mangaReaderList = await database.rawQuery("SELECT * FROM MangaReaderData where parent = 'empty'");
			await database.close();
			return List<MangaReaderData>.generate(mangaReaderList.length, (i){
				return MangaReaderData.fromMap(mangaReaderList[i]);
			});
		} catch(e){
			print(e);
			return List<MangaReaderData>();
		}
	}

	static Future<List<MangaReaderData>> getFromDB({String url, String name, MangaReaderData parent}) async {
		String whereCondition = "";
		List<dynamic> whereArgs = [];
		if(url != null){
			whereCondition = 'url = ?';
			whereArgs.add(url);
		} 
		if(name != null) {
			whereCondition = 'name = ?';
			whereArgs.add(name);
		}
		if(parent != null){
			if(whereCondition.length > 0){
				whereCondition += " AND ";
			}
			whereCondition += "parent = ?";
			if(parent.id == null){
				List<MangaReaderData> parents = await MangaReaderDBHandler.getFromDB(name: parent.name);
				parent = parents.first;
			}
			whereArgs.add(parent.id);
		}
		if(whereArgs.isEmpty){
			return null;
		}
		
		Database database = await MangaReaderDBHandler.openConnection();
		try{
			List<Map<String, dynamic>> mangaReaderList = await database.query(
				"MangaReaderData", 
				where: whereCondition,
				whereArgs: whereArgs
			);
			await database.close();
			return List<MangaReaderData>.generate(mangaReaderList.length, (i){
				return MangaReaderData.fromMap(mangaReaderList[i]);
			});
		} catch(e){
			return List<MangaReaderData>();
		}
	}

	static Future<List<dynamic>> bulkInsert(List<MangaReaderData> items) async {
		Database database = await MangaReaderDBHandler.openConnection();
		List<MangaReaderData> uniqueItems = [];
		items.forEach( (item) => {
			if( !uniqueItems.contains(item) ){
				uniqueItems.add(item)
			}
		} );
		Batch batch = database.batch();
		uniqueItems.forEach( (item) => {
			batch.insert("MangaReaderData", item.toMap())
		} );
		if(!database.isOpen){
			database = await MangaReaderDBHandler.openConnection();
		}
		List<dynamic> insertedList = await batch.commit(noResult: true, continueOnError: true);
		await database.close();
		return insertedList;
	} 
}