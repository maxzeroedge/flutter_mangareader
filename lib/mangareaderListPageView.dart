import 'package:flutter/material.dart';
import 'package:mangareader/mangaFutureBuilder.dart';
import 'package:mangareader/mangareaderDBHandler.dart';

import 'mangareaderDetails.dart';

class MangaPageView extends StatelessWidget {
	MangaPageView({
		Key key, 
		this.title, 
		this.listFutureFunction,
		this.pageType,
		this.showCheckbox = false,
		this.updatePagesSelected,
		this.floatFunction = null,
		this.enableTapFunction = true,
		this.childFutureFunction
	}) : super(key: key);
	final String title;
	final Function listFutureFunction;
	final Function updatePagesSelected;
	final Function floatFunction;
	final String pageType;
	final bool showCheckbox;
	final bool enableTapFunction;
	final Function childFutureFunction;
	Map<String, dynamic> args;

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

	Future<String> dummyChildFunction(Map<String, String> returnable) async{
		return returnable["url"];
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
		return PageView.builder(
			itemCount: snapshotData.length,
			itemBuilder: (context, position) {
				Function childFunction = this.childFutureFunction;
				if(childFunction == null){
					childFunction = dummyChildFunction;
				}
				return MangaDetails(
					title: snapshotData[position].name,
					url: snapshotData[position].url,
					listFutureFunction: childFunction,
					pageType: "Page"
				);
			},
			pageSnapping: false,
		);
	}

	@override
	Widget build(BuildContext context) {
		if( ModalRoute.of(context).settings.arguments != null ){
			this.args = ( ModalRoute.of(context).settings.arguments as MangaReaderData ).toMap().cast<String, String>();
		}
		if(this.updatePagesSelected != null){
			this.updatePagesSelected(null, clear: true);
		}
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

class MangaPageViewItem extends StatefulWidget {
	MangaPageViewItem({
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
	MangaPageViewItemState createState() {
		return MangaPageViewItemState();
	}
}

class MangaPageViewItemState extends State<MangaPageViewItem> {
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