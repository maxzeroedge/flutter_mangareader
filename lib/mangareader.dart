import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:downloads_path_provider/downloads_path_provider.dart';
// import 'package:path_provider/path_provider.dart';

class MangaReaderData{
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

	MangaReaderData getChild({String url, String name}){
		int childIndex = children.indexWhere( (mangaReaderData) => mangaReaderData.name == name || mangaReaderData.url == url ); 
		return children[childIndex];
	}

	Map<String, String> toMap(){
		return Map.from({
			"url": this.url,
			"name": this.name
		});
	}

	static MangaReaderData fromMap(Map<String, String> args){
		return MangaReaderData(
			url: args["url"],
			name: args["name"]
		);
	}
}

class MangaReaderParser{

	String urlPrefix = "https://www.mangareader.net";
	MangaReaderData mangas;
	List<MangaReaderData> pagesSelected;

	Future<List<MangaReaderData>> fetchTitles ( Map<String,String> args ) async{
		if(this.mangas != null && this.mangas.children != null && args["forceReload"] == null){
			return this.mangas.children;
		}
		var response = await http.get("https://www.mangareader.net/alphabetical");
		var htmlDocument = parse(response.body);
		List<MangaReaderData> titles = [];
		htmlDocument.querySelectorAll("ul.series_alpha").forEach( (seriesAlphaUl)=> {
			seriesAlphaUl.querySelectorAll("li").forEach( (seriesAlphaUlLi) => {
				titles.add(
					MangaReaderData(
						url: this.urlPrefix + seriesAlphaUlLi.querySelector("a").attributes["href"],
						name: seriesAlphaUlLi.querySelector("a").text
				))
			} )
		} );
		this.mangas.children = titles;
		return titles;
	}

	// args contains the title information
	Future<List<MangaReaderData>> fetchChapters (Map<String,String> args) async{
		var parentTitle = null;
		if(this.mangas != null && this.mangas.children != null ){
			parentTitle = this.mangas.getChild(url: args["url"]);
		}
		if(parentTitle != null && args["forceReload"] == null){
			return parentTitle.children;
		}
		if(parentTitle == null){
			parentTitle = MangaReaderData.fromMap(args);
		}
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<MangaReaderData> chapters = [];
		htmlDocument.querySelector("div#chapterlist table#listing").querySelectorAll("tr").forEach( (chapterItem)=> {
			chapterItem.querySelector("a") != null ? chapters.add(
				MangaReaderData(
				url :  this.urlPrefix + chapterItem.querySelector("a").attributes["href"],
				name: chapterItem.querySelector("a").text,
				parent: parentTitle
			)) : ''
		} );
		return chapters;
	}

	// args contains the chapter information
	Future<List<MangaReaderData>> fetchPages (Map<String,String> args) async{
		MangaReaderData parentChapter = null;
		if( this.mangas != null && this.mangas.children != null ){
			parentChapter = this.mangas.getChild(url: args["parentTitleUrl"]);
			if(parentChapter != null){
				parentChapter = parentChapter.getChild(url: args["url"]);
				if( parentChapter != null && args["forceReload"] != null){
					return parentChapter.children;
				}
			} 
			if(parentChapter == null) {
				parentChapter = MangaReaderData.fromMap(args);
			}
		}
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<MangaReaderData> pages = [];
		htmlDocument.querySelector("div#selectpage select#pageMenu").querySelectorAll("option").forEach( (pageItem)=> {
			pages.add(MangaReaderData(
				url :  this.urlPrefix + pageItem.attributes["value"],
				name: pageItem.text,
				parent: parentChapter,
				isCurrentPage: pageItem.attributes["selected"]
			))
		} );
		return pages;
	}

	Future<List<Map<String,String>>> getDownloadedItems (Map<String,String> args) async{
		List<Map<String,String>> titles = [];
		Directory downloadsContent = await DownloadsPathProvider.downloadsDirectory;
		String parentPath = downloadsContent.path + "/mangareader";
		if(args.containsKey("parentPath")){
			parentPath += "/" + args["parentPath"];
		}
		if(args.containsKey("targetPath")){
			parentPath = args["targetPath"];
		}
		Directory(parentPath)
			.listSync()
			.forEach( (f) async => {
			titles.add({
				"name": f.path.split("/").last,
				"targetPath": f.absolute.path
			})
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
	Future<void> downloadTitles ( List<MangaReaderData> titles ) async{
		titles.forEach( (title) async => {
			await downloadChapters(await fetchChapters(title.toMap()))
		});
	}

	Future<void> downloadChapters ( List<MangaReaderData> chapters ) async{
		chapters.forEach( (page) async => {
			await downloadPages( await fetchPages(page.toMap()) )
		});
	}

	Future<void> downloadPages ( List<MangaReaderData> pages ) async{
		pages.forEach( (page) async => {
			await _downloadFile( await getCurrentPageImage(page.toMap()) )
		});
	}

	
}