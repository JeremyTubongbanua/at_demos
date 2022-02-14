// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:at_app_flutter/at_app_flutter.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/date_symbol_data_file.dart';

import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iot_reciever/main.dart';
import 'package:iot_reciever/models/iot_model.dart';
import 'package:iot_reciever/widgets/Gaugewidget.dart';

// * Once the onboarding process is completed you will be taken to this screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.ioT}) : super(key: key);
  static const String id = '/home';
  final IoT ioT;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  IoT readings = IoT(sensorName: '@ZARIOT', heartRate: '0', bloodOxygen: '90');
  @override
  void initState() {
    super.initState();
    var atClientManager = AtClientManager.getInstance();
    String? currentAtsign;
    late AtClient atClient;
    var notificationService = atClientManager.notificationService;
    notificationService
        .subscribe(regex: AtEnv.appNamespace)
        .listen((notification) {
      getAtsignData(context, notification.key);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // * Getting the AtClientManager instance to use below
    AtClientManager atClientManager = AtClientManager.getInstance();
    // double _width = MediaQuery.of(context).size.width;
    // double _height = MediaQuery.of(context).size.height;
    var mediaQuery = MediaQuery.of(context);
    var _width = mediaQuery.size.width * mediaQuery.devicePixelRatio;
    var _height = mediaQuery.size.height * mediaQuery.devicePixelRatio;
    print(_width);

    int _gridRows =1 ;
    if (_width > _height) {
      _gridRows = 2;
    } else {
      _gridRows = 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: AutoSizeText(
          widget.ioT.sensorName,
          minFontSize: 5,
        ),
      ),
      body: Container(
        decoration:  BoxDecoration(
          color: Colors.white70,
          gradient: _gridRows > 1 ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.topRight,
            colors:  [ 
             Colors.red,Colors.blue
            ],
          ):
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:  [ 
             Colors.red,Colors.blue
            ],
          )
          ,
          image: DecorationImage(
            opacity: .1,
            fit: BoxFit.cover,
            image: AssetImage(
              'assets/images/blood-pressure.png',
            ),
          ),
        ),
        child: GridView.count(
          primary: false,
          childAspectRatio: 1,
          padding: const EdgeInsets.all(1),
          crossAxisSpacing: 2,
          mainAxisSpacing: 1,
          crossAxisCount: _gridRows,
          children: <Widget>[
            Container(
              child: GaugeWidget(
                measurement: 'Heart Rate',
                units: 'BPM',
                ioT: readings,
                value: 'heartRate',
                decimalPlaces: 0,
                bottomRange: 0,
                topRange: 200,
                lowSector: 50,
                medSector: 130,
                highSector: 20,
                lowColor: Color.fromARGB(255, 190, 35, 23),
                medColor: Color.fromARGB(255, 29, 102, 31),
                highColor: Color.fromARGB(255, 190, 35, 23),
              ),
            ),
            Container(
              child: GaugeWidget(
                measurement: 'Oxygen Saturation',
                units: 'SpO2%',
                ioT: readings,
                value: 'bloodOxygen',
                decimalPlaces: 1,
                bottomRange: 90,
                topRange: 100,
                lowSector: 0.5,
                medSector: 9.5,
                highSector: 0,
                lowColor: Color.fromARGB(255, 190, 35, 23),
                medColor: Color.fromARGB(255, 29, 102, 31),
                highColor: Color.fromARGB(255, 190, 35, 23),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getAtsignData(BuildContext context, String notificationKey) async {
    /// Get the AtClientManager instance
    var atClientManager = AtClientManager.getInstance();

    Future<AtClientPreference> futurePreference = loadAtClientPreference();

    var preference = await futurePreference;

    String? currentAtsign;
    late AtClient atClient;
    atClient = atClientManager.atClient;
    atClientManager.atClient.setPreferences(preference);
    currentAtsign = atClient.getCurrentAtSign();
    print(currentAtsign);

    //Split the notification to get the key and the sharedByAtsign
    // Notification looks like this :-
    // @ai6bh:snackbar.colin@colin
    var notificationList = notificationKey.split(':');
    String sharedByAtsign = '@' + notificationList[1].split('@').last;
    String keyAtsign = notificationList[1];
    keyAtsign = keyAtsign.replaceAll(
        '.${preference.namespace.toString()}$sharedByAtsign', '');

    var metaData = Metadata()
      ..isPublic = false
      ..isEncrypted = true
      ..namespaceAware = true;

    var key = AtKey()
      ..key = keyAtsign
      ..sharedBy = sharedByAtsign
      ..sharedWith = currentAtsign
      ..metadata = metaData;

    // The magic line that picks up the snack
    var reading = await atClient.get(key);
    // Yes that is all you need to do!
    var value = reading.value.toString();
    if (keyAtsign == 'mwc_hr') {
      readings.heartRate = value;
    }
    if (keyAtsign == 'mwc_o2') {
      readings.bloodOxygen = value;
    }
    var createdAt = reading.metadata?.createdAt;
    var dateFormat = DateFormat("H:m.s");
    String dateFormated = dateFormat.format(createdAt!);
    widget.ioT.sensorName = 'Updated: $dateFormated';
    setState(() {});
    print('Yay! A $keyAtsign reading of $value ! From $sharedByAtsign');
  }
}
