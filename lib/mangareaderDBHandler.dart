import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MangaReaderData{
	int id;
	String url;
	String name;
	String levelType;
	MangaReaderData parent;
	List<MangaReaderData> children;
	MangaReaderData({String url, String name, MangaReaderData parent, String isCurrentPage}){
		this.url = url;
		this.name = name;
		this.parent = parent;
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
			"parent": this.parent
		});
	}

	static MangaReaderData fromMap(Map<String, dynamic> args){
		if(args == null){
			return MangaReaderData();
		}
		return MangaReaderData(
			url: args["url"],
			name: args["name"]
		);
	}
}


class MangaReaderDBHandler {
	Database database;

	static Future<Database> openConnection() async{
		return await openDatabase(
			// Set the path to the database. Note: Using the `join` function from the
			// `path` package is best practice to ensure the path is correctly
			// constructed for each platform.
			join( await getDatabasesPath() , 'mangareader_zero.db'),
			onCreate: (db, version) {
				// Run the CREATE TABLE statement on the database.
				return db.execute(
				"""CREATE TABLE IF NOT EXISTS MangaReaderData(
					id INTEGER PRIMARY KEY AUTOINCREMENT, 
					url TEXT, 
					name TEXT, 
					levelType TEXT, 
					FOREIGN_KEY (parentId) REFERENCES MangaReaderData(id)
						ON DELETE NO ACTION ON UPDATE NO ACTION )""",
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
		List<Map<String, dynamic>> mangaReaderList = await database.rawQuery("SELECT * FROM MangaReaderData where parent is null");
		await database.close();
		return List<MangaReaderData>.generate(mangaReaderList.length, (i){
			return MangaReaderData.fromMap(mangaReaderList[i]);
		});
	}

	static Future<List<MangaReaderData>> getFromDB({String url, String name, MangaReaderData parent}) async {
		Database database = await MangaReaderDBHandler.openConnection();
		String whereCondition = "";
		List<dynamic> whereArgs = [];
		if(url != null){
			whereCondition = 'url = ?';
			whereArgs.add(url);
		} else {
			whereCondition = 'name = ?';
			whereArgs.add(name);
		}
		if(parent != null){
			if(whereCondition.length > 0){
				whereCondition += " AND ";
			}
			whereCondition += "parent = ?";
			whereArgs.add(parent);
		}
		
		List<Map<String, dynamic>> mangaReaderList = await database.query(
			"MangaReaderData", 
			where: whereCondition,
			whereArgs: whereArgs
		);
		await database.close();
		return List<MangaReaderData>.generate(mangaReaderList.length, (i){
			return MangaReaderData.fromMap(mangaReaderList[i]);
		});
	}

	static Future<List<dynamic>> bulkInsert(List<MangaReaderData> items) async {
		Database database = await MangaReaderDBHandler.openConnection();
		Batch batch = database.batch();
		items.forEach( (item) => {
			batch.insert("MangaReaderData", item.toMap())
		} );
		List<dynamic> insertedList = await batch.commit(noResult: true);
		await database.close();
		return insertedList;
	} 
}