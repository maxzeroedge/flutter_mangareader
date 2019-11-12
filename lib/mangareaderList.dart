import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';
import 'package:mangareader/mangareader.dart';

class MangaList extends StatelessWidget {
	MangaList({
		Key key, 
		this.title, 
		this.listFutureFunction,
		this.pageType,
		this.showCheckbox = false,
		this.updatePagesSelected,
		this.floatFunction = null,
		this.enableTapFunction = true
	}) : super(key: key);
	final String title;
	final Function listFutureFunction;
	final Function updatePagesSelected;
	final Function floatFunction;
	final String pageType;
	final bool showCheckbox;
	final bool enableTapFunction;
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
			case "Downloads":
				return "/downloads";
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
					enableTapFunction: this.enableTapFunction
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		if( ModalRoute.of(context).settings.arguments != null ){
			this.args = ( ModalRoute.of(context).settings.arguments as MangaReaderData ).toMap();
		}
		this.updatePagesSelected(null, clear: true);
		Future<List<MangaReaderData>> listFuture = this.listFutureFunction(this.args);
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
		this.checkBoxChecked = false,
		this.enableTapFunction
	}) : super ( key : key );

	final Function getNextRoute;
	final Function updatePagesSelected;
	final dynamic snapshotData;
	final bool showCheckbox;
	final bool checkBoxChecked;
	final bool enableTapFunction;

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
				checkBoxChecked = widget.updatePagesSelected(null).indexOf(widget.snapshotData) > -1;
			});
		}
		Widget gestureWidget = GestureDetector(
			onTap: (){
				if(widget.enableTapFunction){
					Navigator.pushNamed(
					context, 
					widget.getNextRoute(true),
					arguments: widget.snapshotData
				);
				}
			},
			child: Container(
				width: 301.0,
				height: 55.0,
				child: Row(
					children: <Widget>[
						Expanded(
							child: Text(widget.snapshotData.name)
						)
					],
				),
			)
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
									widget.updatePagesSelected(widget.snapshotData, clear: false, delete: !value);
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