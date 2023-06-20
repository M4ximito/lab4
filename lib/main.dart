import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random User',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> userDataList = [];
  bool isLoading = false;
  int numUsersToFetch = 15;
  int numUsersToDisplay = 5;

  void fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final jsonData = await NetworkService.fetchData(numUsersToFetch);
      final dartObjectList = NetworkService.convertToDartObject(jsonData);

      setState(() {
        userDataList = dartObjectList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch data from the network.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void refreshData() {
    userDataList.clear();
    fetchData();
  }

  void saveDataToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'userData.json'));
    print(directory);

    await file.writeAsString(json.encode(userDataList));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Data Saved'),
          content: Text('User data saved to file.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void saveDataToDatabase() async {
    setState(() {
      isLoading = true;
    });

    
      final directory = await getApplicationDocumentsDirectory();
      final databasePath = path.join(directory.path, 'userData.db');
      final database = await openDatabase(databasePath, version: 1,
          onCreate: (Database db, int version) {
            db.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT,
            email TEXT,
            phone TEXT,
            thumbnail TEXT
          )
        ''');
          });

      await database.transaction((txn) async {
        await txn.delete('users');

        for (dynamic userData in userDataList) {
          await txn.insert('users', {
            'name': '${userData['name']['first']} ${userData['name']['last']}',
            'email': userData['email'],
            'phone': userData['phone'],
            'thumbnail': userData['picture']['thumbnail'],
          });
        }
      });

      await database.close();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Data Saved'),
            content: Text('User data saved to database.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } cattry {ch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to save data to database.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void setNumUsersToDisplay(int count) {
    setState(() {
      numUsersToDisplay = count;
    });

    if (userDataList.length < count) {
      fetchData();
    }
  }

  Widget buildUserCard(dynamic userData) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userData['picture']['thumbnail']),
        ),
        title: Text('${userData['name']['first']} ${userData['name']['last']}'),
        subtitle: Text(userData['email']),
        trailing: Text(userData['phone']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Random Users'),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.more_vert),
            onSelected: (int value) {
              setNumUsersToDisplay(value);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                value: 5,
                child: Text('5 Users'),
              ),
              PopupMenuItem<int>(
                value: 10,
                child: Text('10 Users'),
              ),
              PopupMenuItem<int>(
                value: 15,
                child: Text('15 Users'),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : ListView.builder(
          itemCount: numUsersToDisplay,
          itemBuilder: (BuildContext context, int index) {
            if (index < userDataList.length) {
              return buildUserCard(userDataList[index]);
            } else {
              return SizedBox.shrink();
            }
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.refresh),
            onPressed: refreshData,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            child: Icon(Icons.save),
            onPressed: saveDataToFile,
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            child: Icon(Icons.density_small_sharp),
            onPressed: saveDataToDatabase,
          ),
        ],
      ),
    );
  }
}

class NetworkService {
  static Future<dynamic> fetchData(int numUsers) async {
    final url = 'https://randomuser.me/api/?results=$numUsers';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['results'];
    } else {
      throw Exception('Failed to fetch data from the network');
    }
  }

  static dynamic convertToDartObject(dynamic jsonData) {
    return jsonData;
  }
}
