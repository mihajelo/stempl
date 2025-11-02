/*stemplanje.dart
Ta stran je namenjena za osnovno operacijo aplikacije, kjer delavec začenja in končuje delovne seje. 
funkcionalnosti na strani:
- izbira vrste dela
- beleženje začetka in konca delovnega časa
- beleženje začetka in konca malice
- premikanje po glavnem meniju
- beleženje lokacije ob začetku in koncu delovnega časa
- beleženje naprave, ki jo delavec uporablja
- končni prikaz delovnega časa in malice 

gradniki:
- gumb za začetek dela
- gumb za konec dela
- gumb za začetek malice
- gumb za konec malice
- dropdown za izbiro vrste dela
- prikaz časa dela
- prikaz časa malice
*/

// Uvoz potrebnih paketov in modulov

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'appData.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Widget za zaslon žiganja delovnih sej, prilagodljiv glede na dimenzije zaslona.
class StemplanjePage extends StatefulWidget {
  final double screenHeight;
  final double screenWidth;

  const StemplanjePage(
      {super.key, required this.screenHeight, required this.screenWidth});

  @override
  _StemplanjePageState createState() => _StemplanjePageState();
}

// Začetno stanje, ki upravlja parametre UI žiganja (gumbi, timerji), uporabniške podatke in geolokacijo.
class _StemplanjePageState extends State<StemplanjePage> {
  AppData appData = AppData();
  bool isPrikazDeloVisible = false;
  var imeTrenutnegaPodjetja = "";
  User? _currentUser;
  var imeTrenutnegaDelavca = "";

  bool isAdmin = false;
  double button1Position = 0;
  double button2Position = 0;
  double time1Position = 30;
  double button1Size = 80.0;
  double button2Size = 80.0;
  double icon1size = 50;
  double icon2size = 50;
  double opacity = 0;
  int _timerValue1 = 0;
  int _timerValue2 = 0;
  Timer? _timer1;
  Timer? _timer2;
  double latitude = 0.0;
  double longitude = 0.0;
  bool active = false;
  bool activen = true;
  String vrstaDela = "Redno delo";
  List<String> deloOptions = [
    'Redno delo',
    'Delo od doma',
    'Nočno delo',
    'Izredno delo',
    'Nedeljsko delo',
    'Izmensko delo',
    'Praznik',
    'Delo v deljenem delavnem času',
    'Ostalo'
  ];


  double screenHeight = 0.0;
  double screenWidth = 0;
  @override
  void initState() {
    super.initState();
    screenHeight = widget.screenHeight;
    screenWidth = widget.screenWidth;
    button1Size = screenHeight * 0.1205;
    button2Size = screenHeight * 0.1205;
    icon1size = screenHeight * 0.0503;
    icon2size = screenHeight * 0.0503;

    isPrikazDeloVisible = appData.prikazdelo;
    imeTrenutnegaPodjetja = appData.imePodjetja;
    _currentUser = FirebaseAuth.instance.currentUser;
    initializeDateFormatting();
    checkAndSetState1(screenHeight);
    checkAndSetState2(screenHeight);
    checkAndSetState3(screenHeight);
    getCurrentLocation(); 
    if (_currentUser != null) {
      imeTrenutnegaDelavca = _currentUser!.uid;
      _fetchCompanyIdForCurrentUser(_currentUser!.uid);
      fetchActive(_currentUser!.uid);
    }
  }

  String long = '';
  String lati = '';

  bool _isRunning1 = false;
  bool _isRunning2 = false;
  String? currentSessionKey;
  final malicaIcon = const Icon(Icons.restaurant);
  final casIcon = Icons.lock_clock;
  final stopIcon = const Icon(Icons.stop);

  final IconData malicaIconData = Icons.restaurant;
  final IconData casIconData = Icons.lock_clock;
  final IconData stopIconData = Icons.stop;

  // ignore: deprecated_member_use
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.reference();

  DateTime? _start1Time;
  DateTime? _stop1Time;
  DateTime? _start2Time;
  DateTime? _stop2Time;
  int timertime = 0;
  String currentcompanyid = "";
  int skupajtime = 0;
  Color button1Color = Colors.blue.withOpacity(
      1); 

  bool showOverlay = false;

@override
  void setState(VoidCallback fn) {
    if(mounted){super.setState(fn);
  }}
  void startLocationTimer() {
  }


  Future<void> getCurrentLocation() async {
    startLocationTimer();
    setState(() {
// Set the flag to true when starting to search for location
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
// Set the flag to false when location is found
      });
    } catch (e) {
      setState(() {
// Set the flag to false on error
      });
    }
  }

  Future<String> getDeviceName() async {
    String deviceName = "Unknown"; // Default value

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
    }

    return deviceName;
  }

void _startTimer1(size) async {
    // Inicializacija časovnikov in določitev začetnega časa
    _start1Time = DateTime.now();
    _timerValue1 = 0;
    _timerValue2 = 0;

    // Pridobitev trenutne lokacije in naprave
    await getCurrentLocation();

    // Pridobitev imena naprave
    String deviceName = await getDeviceName();

    // Formatiranje začetnega časa
    String formattedStartTime =
        DateFormat("yyyy-MM-dd HH:mm:ss").format(_start1Time!);

    // Določitev dolžine in širine kot niz
    String long = longitude.toString(); 
    String lati = latitude.toString(); 

    // Ustvarjanje novega vnosa v bazo podatkov za delovno sejo
    DatabaseReference sessionRef = _databaseRef.child('work_sessions').push();
    Map<String, dynamic> newSession = {
      'username': _currentUser?.uid,
      'start_time': formattedStartTime,
      'vrsta': vrstaDela,
      'companyid': currentcompanyid,
      'lokacija_prijave_longitude': long,
      'lokacija_prijave_latitude': lati,
      'napravaPrijava': deviceName,
      'sprememba': ''
    };
    
    // Batch update z novim sessionom
    Map<String, dynamic> updates = {};
    updates['work_sessions/${sessionRef.key}'] = newSession;
    await _databaseRef.update(updates);

    // Funkcija za delovanje časovnika
    _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerValue1++;
      });
    });

    // Shranjevanje ključa trenutne seje
    currentSessionKey = sessionRef.key;
    // Spreminjanje vizualne lastnosti gumba po začetku delovne seje
    fadeOutText();
    setState(() {
      _isRunning1 = true;
      icon1size = size * 0.0503;
      icon2size = size * 0.0439;
      button1Size = size * 0.0639;
      button2Size = size * 0.0639;
      _stop1Time = null;
      _start2Time = null;
      _stop2Time = null;
      button1Position = 160;

      button1Color = Colors.blue.withOpacity(1);
    });

    // Posodobitev stanja delovanja časovnika 
    _updateUI();
  }








  void _pauseTimer1() {
    _timer1?.cancel();
    setState(() {
      _isRunning1 = false;
    });
  }

  void _unpauseTimer1() {
    if (_timer1 == null || !_timer1!.isActive) {
      _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _timerValue1++;
        });
      });
      _isRunning1 = true;
    }
  }

  Future<void> _stopTimer1(size) async {
    DateTime endTime = DateTime.now();
    String formattedEndTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(endTime);
    await getCurrentLocation(); // Wait for location data to be retrieved
    String deviceName = await getDeviceName();

    DatabaseReference sessionRef =
        _databaseRef.child('work_sessions').child(currentSessionKey!);
    _timer1?.cancel();

    String long = longitude.toString(); // Convert longitude to string
    String lati = latitude.toString(); // Convert latitude to string

    if (_start2Time == null) {
      sessionRef.update({
        'end_time': formattedEndTime,
        'start_time_lunch':
            DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime(0)),
        'end_time_lunch': DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime(0)),
        'right': true,
        'lokacija_odjave_longitude': long,
        'lokacija_odjave_latitude': lati,
        'napravaOdjava': deviceName,
      });
    } else {
      long = longitude.toString(); // Convert longitude to string
      sessionRef.update({
        'end_time': formattedEndTime,
        'right': true,
        'lokacija_odjave_longitude': long,
        'lokacija_odjave_latitude': lati,
        'napravaOdjava': deviceName,
      });
    }

    _stop1Time = endTime;

    setState(() {
      _isRunning1 = false;
      icon1size = size * 0.0503;
      icon2size = size * 0.0503;
      button1Size = size * 0.0628;
      button2Size = size * 0.0628;
      button1Position = 0;
      button1Color = Colors.blue.withOpacity(1);
    });
  }

  void _startTimer2(size) {
    _start2Time = DateTime.now();
    String formattedStart2Time =
        DateFormat("yyyy-MM-dd HH:mm:ss").format(_start2Time!);
    _timerValue2 = _timerValue2;
    _timer2 = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timerValue2++;
      });
    });
    DatabaseReference sessionRef =
        _databaseRef.child('work_sessions').child(currentSessionKey!);
    sessionRef.update({
      'start_time_lunch': formattedStart2Time,
    });
    setState(() {
      _isRunning2 = true;
      button2Size = size * 0.0503;
      button1Size = size * 0.0125;
      icon2size = size * 0.0754;
      icon1size = size * 0.0256;
      button1Position = 0;
      button1Color = button1Color =
          const Color.fromARGB(255, 205, 199, 199).withOpacity(1);
    });

    _updateUI();
  }

  void _stopTimer2(size) {
    _timer2?.cancel();

    _stop2Time = DateTime.now();
    String formattedStop2Time =
        DateFormat("yyyy-MM-dd HH:mm:ss").format(_stop2Time!);

    DatabaseReference sessionRef =
        _databaseRef.child('work_sessions').child(currentSessionKey!);
    sessionRef.update({
      'end_time_lunch': formattedStop2Time.toString(),
    });
    setState(() {
      _isRunning2 = false;
      button1Size = size * 0.0754;
      icon1size = size * 0.0628;
      icon2size = size * 0.0503;
      button2Size = size * 0.08;
      button1Position = 0;
      button1Color = Colors.blue.withOpacity(1);
    });
  }

  void _fetchCompanyIdForCurrentUser(String userId) async {
    final companyIdSnapshot = await FirebaseDatabase.instance
        // ignore: deprecated_member_use
        .reference()
        .child('users')
        .child(userId)
        .child('companyId')
        .once();

    if (companyIdSnapshot.snapshot.value != null) {
      var companyId = companyIdSnapshot.snapshot.value as String;
      setState(() {
        companyId = companyId;
        currentcompanyid = companyId;
      });
    }
  }

  Future<void> fetchActive(String userId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          // ignore: deprecated_member_use
          .reference()
          .child('users')
          .child(userId)
          .child('active')
          .once();

      if (snapshot.snapshot.value == true) {
        setState(() {
          active = true;
        });
      } else {
        setState(() {
          active = false;
        });
      }
    } catch (e) {
      setState(() {
        active = false;
      });
    }
  }

  void checkAndSetState3(size) async {
    final dataSnapshot = await FirebaseDatabase.instance
        .reference()
        .child('work_sessions')
        .orderByChild('username')
        .equalTo(_currentUser?.uid)
        .once();

    final Map<dynamic, dynamic>? sessions =
        dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (sessions != null) {
      for (final key in sessions.keys) {
        final session = sessions[key] as Map<dynamic, dynamic>;
        if (session.length == 10) {
          currentSessionKey = key; // Set the session key
          // Rest of your code remains the same
          _start1Time = DateTime.parse(session['start_time']);
          _start2Time = DateTime.parse(session['start_time_lunch']);
          _stop2Time = DateTime.parse(session['end_time_lunch']);

          if (_start1Time != null) {
            Duration difference1 = DateTime.now().difference(_start1Time!);
            Duration difference2 = _stop2Time!.difference(_start2Time!);
            Duration totalDifference = difference1 - difference2;

            _timerValue1 = totalDifference.inSeconds;
          }
          if (_start2Time != null && _stop2Time != null) {
            Duration difference = _stop2Time!.difference(_start2Time!);
            _timerValue2 = difference.inSeconds;
          }
          fadeInText();
          setState(() {
            _isRunning1 = true;
            _isRunning2 = false;
            icon1size = size * 0.0628;
            button1Size = size * 0.0754;
            icon2size = size * 0.0503;

            button2Size = size * 0.08;
            button1Position = 0;
            _start2Time = DateTime.now();
            button1Color = Colors.blue.withOpacity(1);
            vrstaDela = session['vrsta'];
          });
          _updateUI();
          _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _timerValue1++;
            });
          });
          break; // Exit the loop after finding the first matching session
        }
      }
    }
  }

  Future<void> checkAndSetState2(size) async {
    final dataSnapshot = await FirebaseDatabase.instance
        .reference()
        .child('work_sessions')
        .orderByChild('username')
        .equalTo(_currentUser?.uid)
        .once();

    final Map<dynamic, dynamic>? sessions =
        dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (sessions != null) {
      for (final key in sessions.keys) {
        final session = sessions[key] as Map<dynamic, dynamic>;
        if (session.length == 9) {
          currentSessionKey = key; // Set the session key
          _start1Time = DateTime.parse(session['start_time']);
          _start2Time = DateTime.parse(session['start_time_lunch']);

          if (_start1Time != null && _start2Time != null) {
            Duration difference = _start2Time!.difference(_start1Time!);
            _timerValue1 = difference.inSeconds;
          }
          if (_start1Time != null && _start2Time != null) {
            Duration difference = DateTime.now().difference(_start2Time!);
            _timerValue2 = difference.inSeconds;
          }
          fadeInText();

          setState(() {
            _isRunning2 = true;
            button2Size = size * 0.0503;
            button1Size = size * 0.0125;
            icon2size = size * 0.0754;
            icon1size = size * 0.0256;
            button1Position = 0;
            button1Color = button1Color =
                const Color.fromARGB(255, 205, 199, 199).withOpacity(1);
            vrstaDela = session['vrsta'];
          });
          _updateUI();

          _timer2 = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _timerValue2++;
            });
          });
          break; // Exit the loop after finding the first matching session
        }
      }
    }
  }

  Future<void> checkAndSetState1(size) async {
    final dataSnapshot = await FirebaseDatabase.instance
        .reference()
        .child('work_sessions')
        .orderByChild('username')
        .equalTo(_currentUser?.uid)
        .once();

    final Map<dynamic, dynamic>? sessions =
        dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (sessions != null) {
      for (final key in sessions.keys) {
        final session = sessions[key] as Map<dynamic, dynamic>;
        if (session.length == 8 && session['username'] == _currentUser?.uid) {
          currentSessionKey = key; // Set the session key
          // Rest of your code remains the same
          _start1Time = DateTime.parse(session['start_time']);
          if (_start1Time != null) {
            Duration difference = DateTime.now().difference(_start1Time!);
            _timerValue1 = difference.inSeconds;

            _timer1 = Timer.periodic(const Duration(seconds: 1), (timer) {
              setState(() {
                _timerValue1++;
              });
            });
          }
          setState(() {
            _isRunning1 = true;
            button1Size = size * 0.0639;
            icon1size = size * 0.0503;
            icon2size = size * 0.0439;
            button2Size = size * 0.0639;
            _stop1Time = null;
            button1Position = 160;
            button1Color = Colors.blue.withOpacity(1);
            vrstaDela = session['vrsta'];
          });

          break; // Exit the loop after finding the first matching session
        }
      }
    }
  }

  void fadeInText() {
    setState(() {
      opacity = 1.0; // Set opacity to fully visible
    });
  }

  void fadeOutText() {
    setState(() {
      opacity = 0.0; // Set opacity to fully transparent
    });
  }

  void _updateUI() async {
    while (_isRunning1 || _isRunning2) {
      setState(() {});
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  //GADNIKIIIIIIIIIIII


  Widget ozadje(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(199, 119, 192, 252),
            Colors.white,
          ],
        ),
      ),
    );
  }

  Widget topNotch(BuildContext context) {
    EdgeInsets padding = MediaQuery.of(context).padding;
    double topPadding = padding.top;
    return Container(
      height: topPadding,
      color: Colors.black,
    );
  }

  Widget delo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        border: Border.all(
          color: Colors.transparent,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 84, 84, 84).withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: screenWidth * 0.0298),
          Container(
            height: screenHeight * 0.0628, // Set the desired height
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: DropdownButton<String>(
              value: vrstaDela,
              items: deloOptions.map((String plan) {
                return DropdownMenuItem<String>(
                  value: plan,
                  child: Center(
                    child: Text(
                      plan,
                      style: TextStyle(fontSize: screenHeight * 0.0201),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  vrstaDela = newValue ?? 'Delo';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget timer1(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue
                    .withOpacity(1), // Set the background color to white
                border: Border.all(
                  color: Colors.transparent,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 84, 84, 84).withOpacity(
                        0.5), // Set shadow color and opacity to gray
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: screenWidth * 0.0597,
                    height: screenHeight * 0.0816,
                  ),
                  const Icon(Icons.lock_clock,
                      size: 30, color: Color.fromARGB(255, 16, 16, 16)),
                  SizedBox(width: screenWidth * 0.0498),
                  Text(
                    _formatTime(_timerValue1),
                    style: TextStyle(
                      fontSize: screenHeight * 0.0503,
                    ),
                    selectionColor: const Color.fromARGB(1, 255, 255, 255),
                  ),
                  SizedBox(width: screenWidth * 0.0597),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget timer2(BuildContext context) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 500),
    child: Stack(
      children: [
        Visibility(
          visible: opacity != 0.0, // Only visible if opacity is not 0
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: opacity,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500), // Add duration here
              style: TextStyle(
                fontSize: screenHeight * 0.0503,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.transparent,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 84, 84, 84)
                                  .withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: screenWidth * 0.0498),
                            malicaIcon,
                            SizedBox(
                              width: screenWidth * 0.0398,
                              height: screenHeight * 0.0690,
                            ),
                            Text(
                              _formatTime(_timerValue2),
                              style: TextStyle(fontSize: screenHeight * 0.0503),
                              selectionColor: const Color.fromARGB(1, 131, 0, 0),
                            ),
                            SizedBox(width: screenWidth * 0.0498),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget prikazCas(BuildContext context) {
  bool shouldShowListTiles = _stop1Time != null;
  return AnimatedOpacity(
    duration: const Duration(milliseconds: 2000),
    opacity: shouldShowListTiles ? 1.0 : 0.0,
    child: shouldShowListTiles
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding here
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Set the width of the first container
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(1),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 84, 84, 84).withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_start1Time != null)
                        ListTile(
                          title: Text(
                            'Začetek dela',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenHeight * 0.0215,
                            ),
                          ),
                          trailing: Text(
                            '${_start1Time!.hour.toString().padLeft(2, '0')}:${_start1Time!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenHeight * 0.0226,
                            ),
                          ),
                        ),
                      if (_stop1Time != null)
                        ListTile(
                          title: Text(
                            'Konec dela',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenHeight * 0.0215,
                            ),
                          ),
                          trailing: Text(
                            '${_stop1Time!.hour.toString().padLeft(2, '0')}:${_stop1Time!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: screenHeight * 0.0226,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_start2Time != null || _stop2Time != null)
                  SizedBox(
                    // Set the width of the second container
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 84, 84, 84).withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_start2Time != null)
                            ListTile(
                              title: Text(
                                'Začetek malice',
                                style: TextStyle(fontSize: screenHeight * 0.0215),
                              ),
                              trailing: Text(
                                '${_start2Time!.hour.toString().padLeft(2, '0')}:${_start2Time!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: screenHeight * 0.0226),
                              ),
                            ),
                          if (_stop2Time != null)
                            ListTile(
                              title: Text(
                                'Konec malice',
                                style: TextStyle(fontSize: screenHeight * 0.0215),
                              ),
                              trailing: Text(
                                '${_stop2Time!.hour.toString().padLeft(2, '0')}:${_stop2Time!.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: screenHeight * 0.0226),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )
        : const SizedBox(),
  );
}


  Widget timerdelo(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: EdgeInsets.only(top: button2Position),
      child: InkResponse(
        onTap: () {
          if (_isRunning1) {
            _pauseTimer1();
            _startTimer2(screenHeight);
            fadeInText();
          } else {
            _unpauseTimer1();
            _stopTimer2(screenHeight);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: EdgeInsets.all(button2Size),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: const Color.fromARGB(255, 84, 84, 84)
                  .withOpacity(0.4), // Set the border color to blue
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 84, 84, 84)
                    .withOpacity(0.5), // Set shadow color and opacity to gray
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            (_isRunning2 ? stopIconData : malicaIconData),
            size: icon2size, // Adjust the size as needed
            color: const Color.fromARGB(
                255, 0, 0, 0), // Set the icon color to white
          ),
        ),
      ),
    );
  }

  Widget timermalca(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: EdgeInsets.only(top: button1Position),
      child: InkResponse(
        onTap: active
            ? () {
                if (_isRunning2) {
                  return;
                } else {
                  if (_isRunning1) {
                    _stopTimer1(screenHeight);
                  } else {
                    _startTimer1(screenHeight);
                    setState(() {
                      button1Position = 120;
                    });
                  }
                }
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          padding: EdgeInsets.all(button1Size),
          decoration: BoxDecoration(
            color: active ? button1Color : Colors.grey,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromARGB(255, 84, 84, 84)
                  .withOpacity(0.4), // Set the border color to blue
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 84, 84, 84)
                    .withOpacity(0.5), // Set shadow color and opacity to gray
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            (_isRunning1 ? stopIconData : casIconData),
            size: icon1size, // Adjust the size as needed
          ),
        ),
      ),
    );
  }

//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
//VSE SKUPEJ ZGRAJEN
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          topNotch(context),
          Expanded(
            child: Stack(
              children: [
                ozadje(context),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 20),
                        delo(context),
                        SizedBox(height: 20),
                        timer1(context),
                        SizedBox(height: 20),
                        timer2(context),
                        SizedBox(height: 20),
                        prikazCas(context),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              children: [
                                timerdelo(context),
                                timermalca(context),
                              ],
                            )
                          ],
                        ),
                        SizedBox(height: 20),
                        // V build metodi, kjer imate druge gumbe (npr. kjer je _scanQR)
Positioned(
  bottom: 20,
  right: 20,
  child: FloatingActionButton(
    heroTag: 'testButton',
    onPressed: _testMassDataInsertIndividual,
    tooltip: 'Test mass data',
    backgroundColor: Colors.orange,
    child: const Icon(Icons.data_array),
),)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


//TESTIRANJE 
Future<void> _testMassDataInsertIndividual() async {
  final dbRef = FirebaseDatabase.instance.ref('test_stemplanje_individual');
  const testCount = 500;
  int successfulInserts = 0;
  int failedInserts = 0;

  final overallStart = DateTime.now();
  debugPrint('⏳ Začenjam individualno vstavljanje $testCount zapisov...');

  try {
    // Inicializacija deviceInfo z boljšim error handlingom
    AndroidDeviceInfo? deviceInfo;
    try {
      deviceInfo = await DeviceInfoPlugin().androidInfo;
    } catch (e) {
      debugPrint('⚠️ Napaka pri pridobivanju podatkov o napravi: $e');
      deviceInfo = null;
    }
    
    final deviceName = deviceInfo?.model ?? 'Unknown Device';
    final currentUser = FirebaseAuth.instance.currentUser;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    const fallbackUid = "GK6Qx7xj4hNmvPawJyAzClbTw0I2";

    for (int i = 0; i < testCount; i++) {
      try {
        final now = DateTime.now().subtract(Duration(minutes: i));
        final timeData = {
          'now': now,
          'end': now.add(Duration(hours: 8)),
          'lunch_start': now.add(Duration(minutes: 30)),
          'lunch_end': now.add(Duration(minutes: 75)),
        };

        final formattedTimes = {
          'start_time': dateFormat.format(timeData['now']!),
          'end_time': dateFormat.format(timeData['end']!),
          'start_time_lunch': dateFormat.format(timeData['lunch_start']!),
          'end_time_lunch': dateFormat.format(timeData['lunch_end']!),
        };

        await dbRef.push().set({
          'companyid': "-Nhkws0cLp4zKO7-cI8N",
          ...formattedTimes,
          'lokacija_prijave_latitude': "46.071808",
          'lokacija_prijave_longitude': "14.516224",
          'lokacija_odjave_latitude': "46.071808",
          'lokacija_odjave_longitude': "14.516224",
          'napravaPrijava': deviceName,
          'napravaOdjava': deviceName,
          'right': true,
          'sprememba': "",
          'username': currentUser?.uid ?? fallbackUid,
          'vrsta': i.isEven ? "Redno delo" : "Dodatno delo",
          'timestamp_server': ServerValue.timestamp,
          'test_data': true
        });
        
        successfulInserts++;
      } catch (e, stack) {
        failedInserts++;
        debugPrint('❌ Napaka pri zapisu $i: $e');
        debugPrint(stack.toString());
      }

      if (i % 50 == 0) debugPrint('↳ Obdelano $i zapisov');
    }

    final duration = DateTime.now().difference(overallStart);
    debugPrint('✅ Uspešno vstavljenih: $successfulInserts/$testCount');
    debugPrint('⏱ Skupni čas: ${duration.inMilliseconds}ms (${duration.inMilliseconds/testCount}ms/zapis)');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vstavljenih $successfulInserts zapisov (${failedInserts} napak)'),
          duration: Duration(seconds: 5),
        )
      );
    }

  } catch (e, stack) {
    debugPrint('‼️ Globalna napaka: $e');
    debugPrint(stack.toString());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Globalna napaka: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    }
  }
}
}
