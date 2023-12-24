import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:myppg/util.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ImageSplitPage extends StatefulWidget {
  const ImageSplitPage({super.key});

  @override
  ImageSplitPageView createState() {
    return ImageSplitPageView();
  }
}

class ImageSplitPageView extends State<ImageSplitPage>
    with SingleTickerProviderStateMixin {
  bool _toggled = false; // toggle button value

  CameraController? _controller;

  CameraImage? _image; // store the last camera image
  List<Image>? splitImages;

  Image? imageOutput;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _toggled = false;
    _disposeController();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          FloatingActionButton(
            mini: true,
            heroTag: 'hello',
            onPressed: () {
              if (_toggled) {
                _untoggle();
              } else {
                _toggle();
              }
            },
            child: const Icon(Icons.start),
          ),
          FloatingActionButton(
            mini: true,
            heroTag: 'new',
            onPressed: () async {
              if (_image != null) {
                splitImages = Helper.splitImage(
                    await Helper.getUint8ListFromCameraImage(_image!));
              }
              setState(() {});
            },
            child: const Icon(Icons.camera),
          ),
          FloatingActionButton(
            mini: true,
            heroTag: 'again',
            onPressed: () async {
              setState(() {});
            },
            child: const Icon(Icons.precision_manufacturing_outlined),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Split Image proof'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(18),
                  ),
                  child: _toggled
                      ? AspectRatio(
                          aspectRatio: _controller?.value.aspectRatio ?? 0.0,
                          child: CameraPreview(_controller!),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.center,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: splitImages == null
                  ? const Center(
                      child: Text('Split Images here'),
                    )
                  : GridView(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: _controller?.value.aspectRatio ?? 1.0,
                      ),
                      children: [
                        for (Image img in splitImages!) img,
                      ],
                    ),
            ),
            const Expanded(flex: 1, child: SizedBox()),
          ],
        ),
      ),
    );
  }

  void _toggle() {
    _initController().then((onValue) {
      WakelockPlus.enable();

      setState(() {
        _toggled = true;
      });
      // after is toggled
    });
  }

  void _untoggle() {
    _disposeController();
    WakelockPlus.disable();
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

      _controller?.startImageStream((CameraImage image) async {
        _image = image;
        if (Platform.isAndroid) {
          imageOutput = await Helper.convertYUV420toImageColor(image);
        } else if (Platform.isIOS) {
          imageOutput = await Helper.convertBGRA8888ToImage(image);
        }
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
