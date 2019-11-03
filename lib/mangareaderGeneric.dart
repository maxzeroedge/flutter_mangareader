import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MangaGeneric extends StatefulWidget {
	MangaGeneric({
		Key key,
		this.floatBtnAction = null,
		this.childWidget
	}): super(key: key);
	final Function floatBtnAction;
	final Widget childWidget;

	@override
	MangaGenericState createState() => MangaGenericState();

	Future<bool> getStoragePermissions() async {
		// bool checkResult = await SimplePermissions.checkPermission(
		// 	Permission.WriteExternalStorage);
		// if (!checkResult) {
		// 	var status = await SimplePermissions.requestPermission(
		// 		Permission.WriteExternalStorage);
		// 	//print("permission request result is " + resReq.toString());
		// 	if (status == PermissionStatus.authorized) {
		// 		await downloadFile();
		// 	}
		// } else {
		// 	await downloadFile();
		// }
		Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
		return permissions[PermissionGroup.storage] == PermissionStatus.granted;
	}
	
}

class MangaGenericState extends State<MangaGeneric> {

	bool isDownloadInProgress = false;
	final List<Map<String, String>> listItems = [
		{
			"name": "Downloads"
		},
		{
			"name": "About"
		}
	];

	@override
	Widget build(BuildContext buildContext) {
		return Scaffold(
			appBar: AppBar(
				title: Text("Manga Reader"),
				actions: <Widget>[
					GestureDetector(
						child: Icon(Icons.refresh),
						onTap: (){
							// TODO: Reload List
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
				onPressed: () async {
					if(widget.floatBtnAction != null && !isDownloadInProgress){
						bool allowed = await widget.getStoragePermissions();
						if(allowed){
							setState(() {
								widget.floatBtnAction();
							});
						} else {
							Scaffold.of(context).showSnackBar(new SnackBar(
								content: new Text("Storage Permissions are Missing!"),
							));
						}
					}
				},
				child: Opacity(
					opacity: widget.floatBtnAction != null ? 1.0 : 0.0,
					child: Icon(
						isDownloadInProgress ? 
						Icons.refresh
						: Icons.file_download
					),
				),
				backgroundColor: Colors.blue,
			),
			body: SafeArea(
				minimum: const EdgeInsets.all(16.0),
				child: widget.childWidget,
			),
		);
	}
}