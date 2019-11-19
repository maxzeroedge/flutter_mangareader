import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:mangareader/mangareaderDBHandler.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';

class MangaReaderParser{

	String urlPrefix = "https://www.mangareader.net";
	List<MangaReaderData> pagesSelected;

	Future<List<MangaReaderData>> fetchTitles ( Map<String,String> args ) async{
		List<MangaReaderData> titles = await MangaReaderDBHandler.getAllParentsFromDB();
		if(titles != null && titles.length > 0 && args != null && args["forceReload"] == null){
			return titles;
		}
		var response = await http.get("https://www.mangareader.net/alphabetical");
		var htmlDocument = parse(response.body);
		htmlDocument.querySelectorAll("ul.series_alpha").forEach( (seriesAlphaUl)=> {
			seriesAlphaUl.querySelectorAll("li").forEach( (seriesAlphaUlLi) => {
				titles.add(
					MangaReaderData(
						url: this.urlPrefix + seriesAlphaUlLi.querySelector("a").attributes["href"].trim(),
						name: seriesAlphaUlLi.querySelector("a").text.trim(),
						parent: null
				))
			} )
		} );
		await MangaReaderDBHandler.bulkInsert(titles);
		return titles;
	}

	// args contains the title information
	Future<List<MangaReaderData>> fetchChapters (Map<String,String> args) async{
		// This "SHOULD" never be true
		if(args.isEmpty){
			return null;
		}
		List<MangaReaderData> titles = await MangaReaderDBHandler.getFromDB(
			url: args["url"]
		);
		if(titles == null || titles.length != 1){
			print("How come no / more than 1 entry for the selected title?");
			return null;
		}
		List<MangaReaderData> chapters;
		try{
			chapters = await MangaReaderDBHandler.getFromDB(
				parent: titles[0]
			);
		} catch(e){
			print(e.toString());
			return List<MangaReaderData>();
		}
		if(chapters != null && chapters.length > 0 && args["forceReload"] == null){
			return chapters;
		}
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		htmlDocument.querySelector("div#chapterlist table#listing").querySelectorAll("tr").forEach( (chapterItem)=> {
			chapterItem.querySelector("a") != null ? chapters.add(
				MangaReaderData(
					url :  this.urlPrefix + chapterItem.querySelector("a").attributes["href"].trim(),
					name: chapterItem.querySelector("a").text.trim(),
					parent: titles[0]
				)
			) : ''
		} );
		await MangaReaderDBHandler.bulkInsert(chapters);
		return chapters;
	}

	// args contains the chapter information
	Future<List<MangaReaderData>> fetchPages (Map<String,String> args) async{
		// This "SHOULD" never be true
		if(args.isEmpty){
			return null;
		}
		// List<MangaReaderData> titles = await MangaReaderDBHandler.getFromDB(
		// 	url: args["url"]
		// );
		// if(titles == null || titles.length != 1){
		// 	print("How come no / more than 1 entry for the selected title?");
		// 	return null;
		// }
		List<MangaReaderData> chapters = await MangaReaderDBHandler.getFromDB(
			url: args["url"]
		);
		if(chapters == null || chapters.length != 1){
			print("How come no / more than 1 entry for the selected chapter?");
			return chapters;
		}
		List<MangaReaderData> pages = await MangaReaderDBHandler.getFromDB(
			parent: chapters[0]
		);
		if(pages != null && pages.length > 0 && args["forceReload"] == null){
			return pages;
		}
		var url = args["url"];
		try{
			var response = await http.get(url);
			var htmlDocument = parse(response.body);
			htmlDocument.querySelector("div#selectpage select#pageMenu").querySelectorAll("option").forEach( (pageItem)=> {
				pages.add(MangaReaderData(
					url :  this.urlPrefix + pageItem.attributes["value"].trim(),
					name: pageItem.text.trim(),
					parent: chapters[0]
				))
			} );
			await MangaReaderDBHandler.bulkInsert(pages);
		} catch(e){
			print(e);
		}
		return pages;
	}

	Future<List<MangaReaderData>> getDownloadedItems (Map<String,String> args) async{
		List<MangaReaderData> titles = [];
		Directory downloadsContent = await DownloadsPathProvider.downloadsDirectory;
		String parentPath = join(downloadsContent.path, "mangareader");
		if(args.containsKey("parentPath")){
			parentPath += join(parentPath, args["parentPath"]);
		}
		if(args.containsKey("url")){
			parentPath = args["url"];
		}
		Directory(parentPath)
			.listSync()
			.forEach( (f) async => {
			titles.add(MangaReaderData(
				name: f.path.split("/").last,
				url: f.absolute.path
			))
		});
		return titles;
	}

	Future<String> getCurrentPageImage (Map<String,String> args) async{
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		String currentPageImage = htmlDocument.querySelector("div#imgholder img#img").attributes["src"];
		return currentPageImage;
	}

	List<MangaReaderData> updatePagesSelected(MangaReaderData entry, {bool clear = false, bool delete = false}){
		if( this.pagesSelected == null ){
			this.pagesSelected = [];
		}
		if(clear){
			this.pagesSelected = [];
		} else if( entry != null ) {
			if(delete){
				this.pagesSelected.remove(entry);
			} else {
				this.pagesSelected.add(entry);
			}
		} 
		return this.pagesSelected;
	}

	Future<File> _downloadFile(String url, { String filename }) async {
		var folderName = "";
		if(filename == null){
			var parts = url.split("/").reversed.iterator;
			parts.moveNext();
			var fileName = parts.current + "";
			parts.moveNext();
			folderName = parts.current;
			parts.moveNext();
			folderName = "mangareader/" + parts.current + "/" + folderName + "/";
			filename = folderName + "/" + fileName.split("?")[0]; 
		}
		http.Client _client = new http.Client();
		var req = await _client.get(Uri.parse(url));
		var bytes = req.bodyBytes;
		String dir = (await DownloadsPathProvider.downloadsDirectory).path;
		// String dir = (await getApplicationDocumentsDirectory()).path;
		print(dir);
		await new Directory('$dir/$folderName').create(recursive: true);
		File file = new File('$dir/$filename');
		await file.writeAsBytes(bytes);
		return file;
	}

	// TODO: These fetch calls need parent data in MangaReaderData
	Future<void> downloadTitles ( List<MangaReaderData> titles, {Function callback} ) async{
		titles.forEach( (title) async => {
			await downloadChapters(await fetchChapters(title.toMap().cast<String, String>()))
		});
		if(callback != null){
			callback();
		}
	}

	Future<void> downloadChapters ( List<MangaReaderData> chapters, {Function callback} ) async{
		chapters.forEach( (page) async => {
			await downloadPages( await fetchPages(page.toMap().cast<String, String>()) )
		});
		if(callback != null){
			callback();
		}
	}

	Future<void> downloadPages ( List<MangaReaderData> pages, {Function callback} ) async{
		pages.forEach( (page) async => {
			await _downloadFile( await getCurrentPageImage(page.toMap().cast<String, String>()) )
		});
		if(callback != null){
			callback();
		}
	}

	

	static Future<bool> getStoragePermissions() async {
		// bool checkResult = await SimplePermissions.checkPermission(
		// 	Permission.WriteExternalStorage);
		// if (!checkResult) {
		// 	var status = await SimplePermissions.requestPermission(
		// 		Permission.WriteExternalStorage);
		// 	//print("permission request result is " + resReq.toString());
		// 	if (status == PermissionStatus.authorized) {
		// 		await downloadFile();
		// 	}
		// } else {
		// 	await downloadFile();
		// }
		Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
		return permissions[PermissionGroup.storage] == PermissionStatus.granted;
	}

	
}