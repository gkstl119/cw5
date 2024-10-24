import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'dart:math';

void main() {
  runApp(VirtualAquariumApp());
}

class VirtualAquariumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Aquarium',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AquariumScreen(),
    );
  }
}

class Fish {
  Color color;
  double speed;
  Offset position;
  Offset direction;

  Fish({required this.color, required this.speed})
      : position =
            Offset(Random().nextDouble() * 300, Random().nextDouble() * 300),
        direction = Offset(
            Random().nextDouble() * 2 - 1, Random().nextDouble() * 2 - 1);

  void move(double aquariumWidth, double aquariumHeight) {
    position += direction * speed;

    // Check for collision with aquarium boundaries
    if (position.dx < 0 || position.dx > aquariumWidth) {
      direction = Offset(-direction.dx, direction.dy);
    }
    if (position.dy < 0 || position.dy > aquariumHeight) {
      direction = Offset(direction.dx, -direction.dy);
    }
  }
}

class AquariumScreen extends StatefulWidget {
  @override
  _AquariumScreenState createState() => _AquariumScreenState();
}

class _AquariumScreenState extends State<AquariumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Fish> fishList = [];
  double fishSpeed = 1.0;
  Color fishColor = Colors.red;
  DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..addListener(() {
        setState(() {
          for (var fish in fishList) {
            fish.move(300, 300); // Assuming aquarium size is 300x300
          }
        });
      });
    _controller.repeat();
    _loadSettings(); // Load saved settings on startup
  }

  void _addFish() {
    if (fishList.length < 10) {
      // Limiting to 10 fish
      setState(() {
        fishList.add(Fish(color: fishColor, speed: fishSpeed));
      });
    }
  }

  void _removeFish() {
    if (fishList.isNotEmpty) {
      setState(() {
        fishList.removeLast();
      });
    }
  }

  Future<void> _saveSettings() async {
    int fishCount = fishList.length;
    await _dbHelper.saveAquariumSettings(
        fishCount, fishSpeed, colorToInt(fishColor));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Settings saved!")));
  }

  Future<void> _loadSettings() async {
    final settings = await _dbHelper.getAquariumSettings();
    setState(() {
      if (settings != null) {
        fishSpeed = settings['speed'];
        fishColor = intToColor(settings['color']);
        fishList = List.generate(
          settings['count'],
          (index) => Fish(color: fishColor, speed: fishSpeed),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Convert Color to int
  int colorToInt(Color color) {
    return color.value;
  }

  // Convert int back to Color
  Color intToColor(int value) {
    return Color(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Aquarium'),
      ),
      body: Column(
        children: [
          Container(
            width: 300,
            height: 300,
            color: Colors.blue,
            child: Stack(
              children: [
                CustomPaint(
                  painter: FishPainter(fishList),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _addFish,
                child: Text("Add Fish"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _removeFish,
                child: Text("Remove Fish"),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Text("Save Settings"),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text("Fish Speed"),
          Slider(
            value: fishSpeed,
            min: 0.5,
            max: 5.0,
            divisions: 10,
            label: fishSpeed.toString(),
            onChanged: (double value) {
              setState(() {
                fishSpeed = value;
              });
            },
          ),
          SizedBox(height: 10),
          Text("Fish Color"),
          DropdownButton<Color>(
            value: fishColor, // This should match one of the colors in items
            items: [
              DropdownMenuItem(
                value: Colors.red,
                child: Text("Red"),
              ),
              DropdownMenuItem(
                value: Colors.green,
                child: Text("Green"),
              ),
              DropdownMenuItem(
                value: Colors.blue,
                child: Text("Blue"),
              ),
              DropdownMenuItem(
                value: Colors.yellow,
                child: Text("Yellow"),
              ),
            ],
            onChanged: (Color? newColor) {
              setState(() {
                fishColor =
                    newColor ?? Colors.red; // Fallback to default if null
              });
            },
          ),
        ],
      ),
    );
  }
}

class FishPainter extends CustomPainter {
  final List<Fish> fishList;

  FishPainter(this.fishList);

  @override
  void paint(Canvas canvas, Size size) {
    for (var fish in fishList) {
      final paint = Paint()..color = fish.color;
      canvas.drawCircle(fish.position, 10, paint); // Draw fish as a circle
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
