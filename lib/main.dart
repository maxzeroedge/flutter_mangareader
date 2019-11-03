import 'package:flutter/material.dart';
import 'package:mangareader/mangareaderDetails.dart';
import 'package:mangareader/mangareaderGeneric.dart';
import 'mangareader.dart';
import 'mangareaderList.dart';

void main() => runApp(MyApp());

MangaReaderParser mangaReaderParser = MangaReaderParser();

class MyApp extends StatelessWidget {

	Function floatBtnFunction(Function floatFunction){
		return ()=>{
			floatFunction(mangaReaderParser.updatePagesSelected(null))
		};
	}
	
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Flutter Demo',
			theme: ThemeData(
				primarySwatch: Colors.blue,
				backgroundColor: Colors.white,
			),
			debugShowCheckedModeBanner: false,
			initialRoute: '/',
			routes: {
				// When navigating to the "/" route, build the FirstScreen widget.
				'/': (context) =>  MangaGeneric(
					childWidget: MangaList(
						title: 'Flutter MangaReader',
						listFutureFunction: mangaReaderParser.fetchTitles,
						showCheckbox: true,
						pageType: "Titles",
						updatePagesSelected: mangaReaderParser.updatePagesSelected,
					),
					floatBtnAction: this.floatBtnFunction(mangaReaderParser.downloadTitles),
				),
				'/mangas/list': (context) =>  MangaGeneric(
					childWidget: MangaList(
						title: 'Flutter MangaReader',
						listFutureFunction: mangaReaderParser.fetchTitles,
						showCheckbox: true,
						pageType: "Titles",
						updatePagesSelected: mangaReaderParser.updatePagesSelected
					),
					floatBtnAction: this.floatBtnFunction(mangaReaderParser.downloadTitles),
				),
				// When navigating to the "/second" route, build the SecondScreen widget.
				'/chapters/list': (context) =>  MangaGeneric(
					childWidget: MangaList(
						title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
						listFutureFunction: mangaReaderParser.fetchChapters,
						showCheckbox: true,
						pageType: "Chapters",
						updatePagesSelected: mangaReaderParser.updatePagesSelected,
					),
					floatBtnAction: this.floatBtnFunction(mangaReaderParser.downloadChapters),
				),
				'/pages/list': (context) =>  MangaGeneric(
					childWidget: MangaList(
						title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
						listFutureFunction: mangaReaderParser.fetchPages,
						pageType: "Pages",
						showCheckbox: true,
						updatePagesSelected: mangaReaderParser.updatePagesSelected,
					),
					floatBtnAction: this.floatBtnFunction(mangaReaderParser.downloadPages)
				),
				'/page': (context) => MangaGeneric(
					childWidget: MangaDetails(
						title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
						listFutureFunction: mangaReaderParser.getCurrentPageImage,
						pageType: "Page"
					),
				)
			},
		);
	}
}