import 'package:flutter/material.dart';

class MangaGeneric {

	@override
	Widget build(Widget childWidget, {Function floatBtnAction}) {
		return Scaffold(
			body: SafeArea(
				child: childWidget,
			),
			drawer: ListView(
				children: <Widget>[
					Container(
						height: 55.0,
						child: DrawerHeader(
							child: Text('Manga Reader '),
							margin: EdgeInsets.all(0),
							decoration: BoxDecoration(
								color: Colors.blue,
							),
						),
					),
				]
			),
			floatingActionButton: FloatingActionButton(
				onPressed: () {
					if(floatBtnAction != null){
						floatBtnAction();
					}
				},
				child: Icon(Icons.file_download),
				backgroundColor: Colors.blue,
			),
		);
	}
}