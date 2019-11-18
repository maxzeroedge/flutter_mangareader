import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';
import 'package:mangareader/mangareaderDBHandler.dart';

class MangaDetails extends StatelessWidget {
	MangaDetails({
		Key key, 
		this.title, 
		this.url,
		this.image, 
		this.listFutureFunction,
		this.pageType
	}) : super(key: key);
	final String title;
	final String url;
	final String image;
	final dynamic listFutureFunction;
	final String pageType;
	Map<String, String> args;

	Widget buildWidget(dynamic snapshotData){
		return Column(
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
		);
	}

	@override
	Widget build(BuildContext context) {
		if(this.url == null){
			this.args = ( ModalRoute.of(context).settings.arguments as MangaReaderData ).toMap().cast<String, String>();
		} else {
			this.args = {
				"name": this.title,
				"url": this.url
			};
		}
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