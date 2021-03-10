import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:at_commons/at_commons.dart';
import 'package:newserverdemo/services/server_demo_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  static final String id = 'home';
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //update
  String _key;
  String _value;
  // lookup
  TextEditingController _lookupTextFieldController = TextEditingController();
  String _lookupKey;
  String _lookupValue = '';
  // scan
  List<String> _scanItems = List<String>();
  // service
  ServerDemoService _atClientService = ServerDemoService.getInstance();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //update
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white,
                elevation: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.create, size: 70),
                      title: Text(
                        'Update ',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0),
                      ),
                      subtitle: ListView(
                        shrinkWrap: true,
                        children: [
                          TextField(
                            decoration: InputDecoration(hintText: 'Enter Key'),
                            onChanged: (key) {
                              _key = key;
                            },
                          ),
                          TextField(
                            decoration:
                                InputDecoration(hintText: 'Enter Value'),
                            onChanged: (value) {
                              _value = value;
                            },
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(10),
                      child: FlatButton(
                        child: Text('Update'),
                        color: Colors.deepOrange,
                        textColor: Colors.white,
                        onPressed: _update,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //scan
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white,
                elevation: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.scanner, size: 70),
                      title: Text(
                        'Scan',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.0),
                      ),
                      subtitle: DropdownButton<String>(
                        hint: Text('Select Key'),
                        items: _scanItems.map((String key) {
                          return DropdownMenuItem(
                            value: key != null ? key : null,
                            child: Text(key),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _lookupKey = value;
                            _lookupTextFieldController.text = value;
                          });
                        },
                        value: _scanItems.length > 0 ? _scanItems[0] : '',
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(20),
                      child: FlatButton(
                        child: Text('Scan'),
                        color: Colors.deepOrange,
                        textColor: Colors.white,
                        onPressed: _scan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            //lookup
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: Colors.white,
                elevation: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.list, size: 70),
                      title: Text(
                        'LookUp',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.0,
                        ),
                      ),
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            decoration: InputDecoration(hintText: 'Enter Key'),
                            controller: _lookupTextFieldController,
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            "Lookup Result : ",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            '$_lookupValue',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(20),
                      child: FlatButton(
                        child: Text('Lookup'),
                        color: Colors.deepOrange,
                        textColor: Colors.white,
                        onPressed: _lookup,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: add the _scan, _update, and _lookup methods
_update() async {}

_scan() async {}

_lookup() async {}
