import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';
import 'package:mangareader/mangareaderDBHandler.dart';

class MangaList extends StatefulWidget {
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
	
	@override
	MangaListState createState() => MangaListState();
}

class MangaListState extends State<MangaList>{
	Map<String, dynamic> args;

	String getNextRoute(bool isNext){
		switch (widget.pageType) {
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
				if( this.args.containsKey("levelType") && this.args["levelType"] == "Chapter" ){
					return "/downloadPage";
				}
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
					showCheckbox: widget.showCheckbox,
					snapshotData: snapshotData[position],
					updatePagesSelected: widget.updatePagesSelected,
					enableTapFunction: widget.enableTapFunction
				);
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		Object arguments = ModalRoute.of(context).settings.arguments;
		if( arguments != null ){
			if( arguments is MangaReaderData ){
				this.args = arguments.toMap().cast<String, String>();
			} else if( arguments is Map) {
				this.args = arguments.cast<String, String>();
			}
		}
		widget.updatePagesSelected(null, clear: true);
		Future<List<MangaReaderData>> listFuture = widget.listFutureFunction(this.args);
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