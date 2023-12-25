import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:myppg/ppg_data.dart';

import 'package:myppg/split_image.dart';
import 'package:myppg/util.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageView createState() {
    return HomePageView();
  }
}

class HomePageView extends State<HomePage> with SingleTickerProviderStateMixin {
  bool _toggled = false; // toggle button value
  bool _breathing = false; // toggle button value
  CameraController? _controller;
  late AnimationController _animationController;
  double _iconScale = 1;
  Image? imageOutput;
  late PpgData ppgData;
  int frameCount = 0;

  @override
  void initState() {
    super.initState();
    ppgData = PpgData.init();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);
    _animationController.addListener(() {
      setState(() {
        _iconScale = 1.0 + _animationController.value * 0.4;
      });
    });
    fillInitImage();
  }

  fillInitImage() async {
    imageOutput = await Helper.getRGBimage();
    setState(() {});
  }

  @override
  void dispose() {
    _toggled = false;
    _disposeController();
    WakelockPlus.disable();
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            onPressed: () async {
              imageOutput = await Helper.getRGBimage();
              setState(() {});
            },
            child: const Icon(Icons.image_outlined),
          ),
          FloatingActionButton(
            heroTag: 'split image',
            onPressed: () async {
              showDialog(
                context: context,
                builder: (_) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImageSplitPage(),
                            ),
                          );
                        },
                        child: const Text('Split Image'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Icon(Icons.pages),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(18),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: <Widget>[
                            _toggled
                                ? Center(
                                    child: AspectRatio(
                                      aspectRatio:
                                          _controller?.value.aspectRatio ?? 0.0,
                                      child: CameraPreview(_controller!),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(12),
                                    alignment: Alignment.center,
                                    color: Colors.grey,
                                  ),
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                _toggled
                                    ? "Cover both the camera and the flash with your finger"
                                    : "Camera feed will display here",
                                style: TextStyle(
                                    backgroundColor: _toggled
                                        ? Colors.white
                                        : Colors.transparent),
                                textAlign: TextAlign.center,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Created RGB IMAGE'),
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: imageOutput,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Transform.scale(
                      scale: _iconScale,
                      child: IconButton(
                        icon: Icon(
                            _toggled ? Icons.favorite : Icons.favorite_border),
                        color: Colors.red,
                        iconSize: 128,
                        onPressed: () {
                          if (_toggled) {
                            _untoggle();
                          } else {
                            _toggle();
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(_breathing ? 'Breathing In' : 'Breathing Out'),
                        InkWell(
                          onTapDown: (_) {
                            setState(() {
                              _breathing = true;
                            });
                          },
                          onTapUp: (_) {
                            setState(() {
                              _breathing = false;
                            });
                          },
                          child: ClipOval(
                            child: Icon(
                              Icons.air,
                              color: _breathing ? Colors.red : Colors.black38,
                              size: 128,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const Text('Data size 20kb'),
                  // const SizedBox(height: 20),
                  MaterialButton(
                    color: Colors.amberAccent,
                    onPressed: () {
                      // Share.share(ppgDataToJson(ppgData));
                    },
                    child: const Text('Share Raw'),
                  ),
                  const SizedBox(height: 20),
                  MaterialButton(
                    color: Colors.amberAccent,
                    onPressed: () {
                      // Share.share(ppgData.toJson().toString());
                    },
                    child: const Text('Share Base64\'ed'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _toggle() {
    _initController().then((onValue) {
      WakelockPlus.enable();
      _animationController.repeat(reverse: true);
      setState(() {
        _toggled = true;
      });
    });
  }

  void _untoggle() {
    _disposeController();
    int duration = DateTime.now().millisecondsSinceEpoch -
        (ppgData.metaData?.timestamp ?? 0);
    ppgData.addFinalMetaData(duration, frameCount);
    frameCount = 0;
    WakelockPlus.disable();
    _animationController.stop();
    _animationController.value = 0.0;
    setState(() {
      _toggled = false;
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _initController() async {
    try {
      List cameras = await availableCameras();
      _controller = CameraController(cameras.first, ResolutionPreset.low);
      await _controller?.initialize();
      Future.delayed(const Duration(milliseconds: 100)).then((onValue) {
        _controller?.setFlashMode(FlashMode.torch);
      });
      _controller?.startImageStream((CameraImage image) async {
        frameCount += 1;
        await ppgData.addData(image, _breathing);
        // if (Platform.isAndroid) {
        //   imageOutput = await Helper.convertYUV420toImageColor(image);
        // } else if (Platform.isIOS) {
        //   imageOutput = await Helper.convertBGRA8888ToImage(image);
        // }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
