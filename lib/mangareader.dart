import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'dart:io';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MangaReaderParser{

	String urlPrefix = "https://www.mangareader.net";
	List<Map<String, String>> titles;
	List<Map<String, String>> chapters;
	List<Map<String, String>> pages;
	List<String> pagesSelected;

	Future<List<Map<String,String>>> fetchTitles ( Map<String,String> args ) async{
		var response = await http.get("https://www.mangareader.net/alphabetical");
		var htmlDocument = parse(response.body);
		List<Map<String,String>> titles = [];
		htmlDocument.querySelectorAll("ul.series_alpha").forEach( (seriesAlphaUl)=> {
			seriesAlphaUl.querySelectorAll("li").forEach( (seriesAlphaUlLi) => {
				titles.add({
					"url": this.urlPrefix + seriesAlphaUlLi.querySelector("a").attributes["href"],
					"name": seriesAlphaUlLi.querySelector("a").text
				})
			} )
		} );
		return titles;
	}

	Future<List<Map<String,String>>> fetchChapters (Map<String,String> args) async{
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<Map<String,String>> chapters = [];
		htmlDocument.querySelector("div#chapterlist table#listing").querySelectorAll("tr").forEach( (chapterItem)=> {
			chapterItem.querySelector("a") != null ? chapters.add({
				"url" :  this.urlPrefix + chapterItem.querySelector("a").attributes["href"],
				"name": chapterItem.querySelector("a").text
			}) : ''
		} );
		return chapters;
	}

	Future<List<Map<String,String>>> fetchPages (Map<String,String> args) async{
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		List<Map<String,String>> pages = [];
		htmlDocument.querySelector("div#selectpage select#pageMenu").querySelectorAll("option").forEach( (pageItem)=> {
			pages.add({
				"url" :  this.urlPrefix + pageItem.attributes["value"],
				"name": pageItem.text,
				"isCurrentPage": pageItem.attributes["selected"]
			})
		} );
		return pages;
	}

	Future<String> getCurrentPageImage (Map<String,String> args) async{
		var url = args["url"];
		var response = await http.get(url);
		var htmlDocument = parse(response.body);
		String currentPageImage = htmlDocument.querySelector("div#imgholder img#img").attributes["src"];
		return currentPageImage;
	}

	List<String> updatePagesSelected(String entry, {bool clear = false, bool delete = false}){
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
		if(filename == null){
			var parts = url.split("/").reversed.iterator;
			var fileName = parts.current;
			parts.moveNext();
			var folderName = "mangareader/" + parts.current;
			filename = folderName + "/" + fileName.split("?")[0]; 
		}
		http.Client _client = new http.Client();
		var req = await _client.get(Uri.parse(url));
		var bytes = req.bodyBytes;
		await PermissionHandler().requestPermissions([PermissionGroup.storage]);
		String dir = (await DownloadsPathProvider.downloadsDirectory).path;
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