import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';
import 'package:mangareader/mangareaderGeneric.dart';

class MangaDetails extends StatelessWidget {
	MangaDetails({
		Key key, 
		this.title, 
		this.image, 
		this.listFutureFunction,
		this.pageType
	}) : super(key: key);
	final String title;
	final String image;
	final dynamic listFutureFunction;
	final String pageType;
	Map<String, String> args;

	Widget buildWidget(dynamic snapshotData){
		return MangaGeneric().build(
			Column(
				children: <Widget>[
					Scrollable(
						viewportBuilder: (context, offset){
							return Column(
								children: <Widget>[
									Image.network(snapshotData)
								],
							);
						},
					)
				],
			)
		);
	}

	@override
	Widget build(BuildContext context) {
		this.args = ModalRoute.of(context).settings.arguments;
		return Scaffold(
			body: FutureBuilder(
				future: this.listFutureFunction(this.args),
				builder: (context, snapshot) {
					return MangaFutureBuilder().build(context, snapshot, buildWidget);
				},
			)
		);
	}
	
}