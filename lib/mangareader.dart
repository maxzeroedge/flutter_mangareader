import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

class MangaReaderParser{

	String url_prefix = "https://www.mangareader.net";
	List<Map<String, String>> titles;
	List<Map<String, String>> chapters;
	List<Map<String, String>> pages;

	Future<List<Map<String,String>>> fetchTitles ( Map<String,String> args ) async{
		var response = await http.get("https://www.mangareader.net/alphabetical");
		var htmlDocument = parse(response.body);
		List<Map<String,String>> titles = [];
		htmlDocument.querySelectorAll("ul.series_alpha").forEach( (seriesAlphaUl)=> {
			seriesAlphaUl.querySelectorAll("li").forEach( (seriesAlphaUlLi) => {
				titles.add({
					"url": this.url_prefix + seriesAlphaUlLi.querySelector("a").attributes["href"],
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
				"url" :  this.url_prefix + chapterItem.querySelector("a").attributes["href"],
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
				"url" :  this.url_prefix + pageItem.attributes["value"],
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
}