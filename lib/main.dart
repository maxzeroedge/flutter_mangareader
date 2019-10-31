import 'package:flutter/material.dart';
import 'package:mangareader/mangareaderDetails.dart';
import 'mangareader.dart';
import 'mangareaderList.dart';

void main() => runApp(MyApp());

MangaReaderParser mangaReaderParser = MangaReaderParser();

class MyApp extends StatelessWidget {
	
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
				'/': (context) =>  MangaList(
					title: 'Flutter MangaReader',
					listFutureFunction: mangaReaderParser.fetchTitles,
					showCheckbox: true,
					pageType: "Titles",
					updatePagesSelected: mangaReaderParser.updatePagesSelected
				),
				'/mangas/list': (context) =>  MangaList(
					title: 'Flutter MangaReader',
					listFutureFunction: mangaReaderParser.fetchTitles,
					showCheckbox: true,
					pageType: "Titles",
					updatePagesSelected: mangaReaderParser.updatePagesSelected
				),
				// When navigating to the "/second" route, build the SecondScreen widget.
				'/chapters/list': (context) =>  MangaList(
					title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
					listFutureFunction: mangaReaderParser.fetchChapters,
					showCheckbox: true,
					pageType: "Chapters",
					updatePagesSelected: mangaReaderParser.updatePagesSelected,
					floatFunction: mangaReaderParser.downloadChapters
				),
				'/pages/list': (context) =>  MangaList(
					title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
					listFutureFunction: mangaReaderParser.fetchPages,
					pageType: "Pages",
					showCheckbox: true,
					updatePagesSelected: mangaReaderParser.updatePagesSelected,
					floatFunction: mangaReaderParser.downloadPages
				),
				'/page': (context) => MangaDetails(
					title: ( ModalRoute.of(context).settings.arguments as Map<String, String> )["name"],
					listFutureFunction: mangaReaderParser.getCurrentPageImage,
					pageType: "Page"
				)
			},
		);
	}
}