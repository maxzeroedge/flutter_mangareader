import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:downloads_path_provider/downloads_path_provider.dart';
// import 'package:path_provider/path_provider.dart';

class MangaReaderData{
	String url;
	String name;
	MangaReaderData parent;
	String isCurrentPage;
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
}

class MangaReaderParser{

	String urlPrefix = "https://www.mangareader.net";
	MangaReaderData mangas;
	List<Map<String, String>> pagesSelected;

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

	Future<List<MangaReaderData>> fetchChapters (Map<String,String> args) async{
		if(this.mangas != null && this.mangas.children != null && args["forceReload"] == null){
			return this.mangas.getChild(url: args["url"]).children;
		}
		var url = args["url"];
		var parentChapter = MangaReaderData(
			url: args["url"],
			name: args["name"]
		);
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<MangaReaderData> chapters = [];
		htmlDocument.querySelector("div#chapterlist table#listing").querySelectorAll("tr").forEach( (chapterItem)=> {
			chapterItem.querySelector("a") != null ? chapters.add(
				MangaReaderData(
				url :  this.urlPrefix + chapterItem.querySelector("a").attributes["href"],
				name: chapterItem.querySelector("a").text,
				parent: parentChapter
			)) : ''
		} );
		return chapters;
	}

	Future<List<MangaReaderData>> fetchPages (Map<String,String> args) async{
		// if(this.pages != null && args["forceReload"] == null){
		// 	return this.pages;
		// }
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<MangaReaderData> pages = [];
		htmlDocument.querySelector("div#selectpage select#pageMenu").querySelectorAll("option").forEach( (pageItem)=> {
			pages.add(MangaReaderData(
				url :  this.urlPrefix + pageItem.attributes["value"],
				name: pageItem.text,
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

	List<Map<String, String>> updatePagesSelected(Map<String, String> entry, {bool clear = false, bool delete = false}){
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

	Future<void> downloadTitles ( List<Map<String, String>> titles ) async{
		titles.forEach( (title) async => {
			await downloadChapters(await fetchChapters(title))
		});
	}

	Future<void> downloadChapters ( List<Map<String, String>> chapters ) async{
		chapters.forEach( (page) async => {
			await downloadPages( await fetchPages(page) )
		});
	}

	Future<void> downloadPages ( List<Map<String, String>> pages ) async{
		pages.forEach( (page) async => {
			await _downloadFile( await getCurrentPageImage(page) )
		});
	}

	
}