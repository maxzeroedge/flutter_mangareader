import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';

class MangaList extends StatelessWidget {
	MangaList({
		Key key, 
		this.title, 
		this.listFutureFunction,
		this.pageType
	}) : super(key: key);
	final String title;
	final dynamic listFutureFunction;
	final String pageType;
	Map<String, String> args;

	String getNextRoute(bool isNext){
		switch (this.pageType) {
			case "Titles":
				return isNext ? "/chapters/list" : "/mangas/list";
				break;
			case "Chapters":
				return isNext ? "/pages/list" : "/mangas/list";
				break;
			case "Pages":
				return isNext ? "/page" : "/pages/list";
				break;
			default:
				return "/about";
		}
	}

	Widget buildWidget(dynamic snapshotData){
		if(snapshotData.length < 1){
			return Column(
				children: <Widget>[
					Expanded(
						child: Center(
							child: Text("No Data Available for this ${this.args['name']} at ${this.args['url']}")
						),
					),
				],
			);
		}
		return ListView.builder(
			itemCount: snapshotData.length,
			itemBuilder: (context, position) {
				return GestureDetector(
					onTap: (){
						Navigator.pushNamed(
							context, 
							this.getNextRoute(true),
							arguments: snapshotData[position]
						);
					},
					child: Card(
						child: Text(snapshotData[position]["name"]),
					),
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		this.args = ModalRoute.of(context).settings.arguments;
		Future<List<Map<String, String>>> listFuture = this.listFutureFunction(args);
		return Scaffold(
			body: FutureBuilder(
				future: listFuture,
				builder: (context, snapshot) {
					return MangaFutureBuilder().build(context, snapshot, buildWidget);
				},
			),
		);
	}
}
