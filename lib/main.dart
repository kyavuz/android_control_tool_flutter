import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BrightnessControlPage(),
    );
  }
}

class BrightnessControlPage extends StatefulWidget {
  @override
  _BrightnessControlPageState createState() => _BrightnessControlPageState();
}

class _BrightnessControlPageState extends State<BrightnessControlPage> {
  double _brightness = 0.5; // Başlangıç parlaklığı (%50)
  bool _isAutoBrightnessOn = false; // Adaptif parlaklık açık mı?
  bool _wasAutoBrightnessOn = false; // Slider değişmeden önceki adaptif parlaklık durumu
  static const platform = MethodChannel('android/settings');

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _getCurrentBrightness();
    _checkAutoBrightness();
  }

  Future<void> _requestPermission() async {
    if (!await Permission.systemAlertWindow.isGranted) {
      await Permission.systemAlertWindow.request();
    }
    if (!await Permission.manageExternalStorage.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _checkAutoBrightness() async {
    try {
      final int result = await platform.invokeMethod('getAutoBrightness');
      setState(() {
        _isAutoBrightnessOn = result == 1;
        _wasAutoBrightnessOn = _isAutoBrightnessOn; // Başlangıçta durumu kaydet
      });
    } catch (e) {
      print("Error checking auto brightness: $e");
    }
  }

  Future<void> _toggleAutoBrightness(bool enable) async {
    final int newValue = enable ? 1 : 0;
    try {
      await platform.invokeMethod('setAutoBrightness', newValue);
      setState(() {
        _isAutoBrightnessOn = enable;
      });
    } catch (e) {
      print("Error toggling auto brightness: $e");
    }
  }

  Future<void> _getCurrentBrightness() async {
    double brightness = await ScreenBrightness().system;
    setState(() {
      _brightness = brightness;
    });
  }

  Future<void> _setBrightness(double brightness) async {
    if (brightness < _brightness && _isAutoBrightnessOn) {
      // Slider azaltıldığında adaptif parlaklığı kapat ve önceki durumunu sakla
      _wasAutoBrightnessOn = _isAutoBrightnessOn;
      _toggleAutoBrightness(false);
    }

    await ScreenBrightness().setSystemScreenBrightness(brightness);
    setState(() {
      _brightness = brightness;
    });
  }

  void _onSliderChangeEnd(double value) {
    if (value > _brightness && _wasAutoBrightnessOn) {
      // Eğer slider artırılmışsa ve önceden adaptif parlaklık açıksa geri aç
      _toggleAutoBrightness(true);
    }
    //_wasAutoBrightnessOn = _isAutoBrightnessOn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Brightness Control")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Brightness: ${(_brightness * 100).toInt()}%"),
            Slider(
              value: _brightness,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                _setBrightness(value);
              },
              onChangeEnd: _onSliderChangeEnd,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _toggleAutoBrightness(!_isAutoBrightnessOn),
              child: Text(
                _isAutoBrightnessOn
                    ? "Disable Auto Brightness"
                    : "Enable Auto Brightness",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
