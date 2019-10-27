import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MangaFutureBuilder {
	Widget build(BuildContext context, AsyncSnapshot snapshot, Function callback) {
		if( snapshot.connectionState == ConnectionState.done ) {
			if(snapshot.hasError){
				// Show Error
				return Column(
					children: <Widget>[
						Expanded(
							child: Center(
								child: Card(
									child: Text(snapshot.error.toString()),
								),
							),
						),
					],
				);
			} else if( snapshot.hasData ){
				// Show Data
				return callback(snapshot.data);
			}
		} else {
			// Show Loading
			return Column(
				children: <Widget>[
					Expanded(
						child: Center(
							child: CircularProgressIndicator(
								backgroundColor: Colors.white,
							),
						),
					),
				],
			);
		}
		return Column(
			children: <Widget>[
				Expanded(
					child: Center(
						child: CircularProgressIndicator(
							backgroundColor: Colors.white,
						),
					),
				),
			],
		);
	}
}