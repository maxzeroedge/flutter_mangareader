import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';

class MangaList extends StatelessWidget {
	MangaList({
		Key key, 
		this.title, 
		this.listFutureFunction,
		this.pageType,
		this.showCheckbox = false,
		this.updatePagesSelected
	}) : super(key: key);
	final String title;
	final Function listFutureFunction;
	final Function updatePagesSelected;
	final String pageType;
	final bool showCheckbox;
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
				return MangaListItem(
					getNextRoute: this.getNextRoute,
					showCheckbox: this.showCheckbox,
					snapshotData: snapshotData[position],
					updatePagesSelected: this.updatePagesSelected,
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

class MangaListItem extends StatefulWidget {
	MangaListItem({
		Key key,
		this.getNextRoute,
		this.snapshotData,
		this.showCheckbox,
		this.updatePagesSelected,
		this.checkBoxChecked = false
	}) : super ( key : key );

	final Function getNextRoute;
	final Function updatePagesSelected;
	final Map snapshotData;
	final bool showCheckbox;
	final bool checkBoxChecked;

	@override
	MangaListItemState createState() {
		return MangaListItemState();
	}
}

class MangaListItemState extends State<MangaListItem> {
	bool checkBoxChecked;

	@override
	void initState() {
		super.initState();
	}

	@override
	Widget build(BuildContext context) {
		if(widget.updatePagesSelected != null){
			setState(() {
				checkBoxChecked = widget.updatePagesSelected(null).indexOf(widget.snapshotData["url"]) > -1;
			});
		}
		Widget gestureWidget = GestureDetector(
			onTap: (){
				Navigator.pushNamed(
					context, 
					widget.getNextRoute(true),
					arguments: widget.snapshotData
				);
			},
			child: Card(
				child: Text(widget.snapshotData["name"]),
			),
		);
		if(widget.showCheckbox){
			gestureWidget = Card(
				child: Row(
					children: <Widget>[
						Checkbox(
							value: checkBoxChecked,
							onChanged: (bool value){
								setState(() {
									print(value);
									print(value.runtimeType);
									widget.updatePagesSelected(widget.snapshotData["url"], clear: false, delete: !value);
								});
							},
						),
						gestureWidget
					],
				),
			);
		}
		return gestureWidget;
	}
}