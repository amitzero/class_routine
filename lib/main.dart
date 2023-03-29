import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  log('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    log('notification action tapped with input: ${notificationResponse.input}');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings("mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (notificationResponse) {},
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final subjects = [
    Subject(
      1,
      'Malaysian Govt. & Public Policy',
      'MPU-3312',
      DateTime.monday,
      '9:00am-11:00am',
      'Mr. Sharmin',
      'Online',
    ),
    Subject(
      2,
      'Operating System',
      'OPS-252',
      DateTime.tuesday,
      '2:00pm-5:00pm',
      'Dr. Shipra',
      'Lecturer Hall 403',
    ),
    Subject(
      3,
      'Data Structure & Algorithm',
      'DCM-254 & DSA-251',
      DateTime.tuesday,
      '9:30am-12:30pm',
      'Dr. Vivek',
      'Computer Lab 2',
    ),
    Subject(
      4,
      'Computer Networks',
      'CNW-112',
      DateTime.thursday,
      '2:00pm-5:00pm',
      'Dr. Hisamuddin',
      'Computer Lab 1',
    ),
    Subject(
      5,
      'Data Communication & Networking',
      'DCN-263',
      DateTime.thursday,
      '2:00pm-5:00pm',
      'Dr. Hisamuddin',
      'Computer Lab 1',
    ),
  ];

  @override
  void initState() {
    subjects.sort((a, b) => a.dayLeft - b.dayLeft);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Routine'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var sub in subjects) SubjectCard(subject: sub),
          ],
        ),
      ),
    );
  }
}

class Subject {
  int id;
  String name, code;
  int day;
  String time, lecturer, room;
  Subject(
    this.id,
    this.name,
    this.code,
    this.day,
    this.time,
    this.lecturer,
    this.room,
  );

  String get dayName {
    return DateFormat('EEEE').format(
      tz.TZDateTime.now(tz.local).subtract(
        Duration(days: tz.TZDateTime.now(tz.local).weekday - day),
      ),
    );
  }

  int get dayLeft {
    int left = day - tz.TZDateTime.now(tz.local).weekday;
    if (left < 0) left += 7;
    return left;
  }

  tz.TZDateTime get scheduleDateTime {
    var now = tz.TZDateTime.now(tz.local);
    return tz.TZDateTime(tz.local, now.year, now.month, now.day + dayLeft, 22);
  }

  String get title {
    return name;
  }

  String get body {
    return 'Tomorrow at $time\n$lecturer - $room';
  }
}

class SubjectCard extends StatefulWidget {
  const SubjectCard({super.key, required this.subject});

  final Subject subject;

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  Future<void> scheduleWeekly(Subject subject) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      subject.id,
      subject.title,
      subject.body,
      subject.scheduleDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'subject routine',
          'Subject Routine',
          channelDescription: 'Subject Routine Notification',
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  void initState() {
    scheduleWeekly(widget.subject);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.subject.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  widget.subject.code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          widget.subject.dayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.subject.time,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          widget.subject.lecturer,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          widget.subject.room,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  widget.subject.dayLeft == 0
                      ? 'Today have the class'
                      : 'Next class ${widget.subject.dayLeft == 1 ? 'tomorrow' : '${widget.subject.dayLeft} days later'}',
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
