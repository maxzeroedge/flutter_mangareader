import 'package:flutter/material.dart';

class MangaGeneric extends StatelessWidget {
	MangaGeneric({
		Key key,
		this.floatBtnAction = null,
		this.childWidget
	}): super(key: key);
	final Function floatBtnAction;
	final Widget childWidget;
	final List<Map<String, String>> listItems = [
		{
			"name": "Downloads"
		},
		{
			"name": "Progress"
		}
	];

	@override
	Widget build(BuildContext buildContext) {
		return Scaffold(
			body: SafeArea(
				minimum: const EdgeInsets.all(16.0),
				child: this.childWidget,
			),
			appBar: AppBar(
				title: Text("Manga Reader"),
				actions: <Widget>[
					GestureDetector(
						child: Icon(Icons.refresh),
						onTap: (){
							// Reload List
						},
					)
				],
			),
			drawer: Drawer(
				child: Container(
					color: Colors.white,
					child: ListView(
						children: <Widget>[
							Container(
								height: 110.0,
								child: DrawerHeader(
									child: Row(
										children: <Widget>[
											/* BackButton(
												color: Colors.white,
											), */
											Text(
												'Manga Reader',
												style: TextStyle(
													color: Colors.white,
													fontSize: 32.0
												),
											),
										],
									),
									margin: EdgeInsets.all(0),
									decoration: BoxDecoration(
										color: Colors.blue,
									),
								),
							),
							...listItems.map( (listItem) => 
								Builder(
									builder: (listTileContext) => ListTile(
										title: Text(
											listItem["name"],
											style: TextStyle(height: 2, fontSize: 17.0)
										),
										onTap: (){
											// TODO
										},
									)
								)
							)
						],
					),
				),
			),
			floatingActionButton: FloatingActionButton(
				onPressed: () {
					if(this.floatBtnAction != null){
						this.floatBtnAction();
					}
				},
				child: Opacity(
					opacity: floatBtnAction != null ? 1.0 : 0.0,
					child: Icon(Icons.file_download),
				),
				backgroundColor: Colors.blue,
			),
		);
	}
}