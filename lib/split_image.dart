import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:myppg/util.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:image/image.dart' as imglib;

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
  List<imglib.Image>? splitImages;

  List<List<double>>? pixelForImage;

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
                splitImages = Helper.splitImageIn4x4(
                    await Helper.getUint8ListFromCameraImage(_image!));
              }
              setState(() {});
            },
            child: const Icon(Icons.camera),
          ),
          FloatingActionButton(
            mini: true,
            heroTag: 'again',
            onPressed: () {
              setState(() {
                if (splitImages != null) {
                  pixelForImage = [];
                  for (imglib.Image img in splitImages!) {
                    pixelForImage
                        ?.add(Helper.getReducedRGBFromImagelibImage(img));
                  }
                  pixelForImage;
                }
              });
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
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(18),
                  ),
                  child: _toggled
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: _controller?.value.aspectRatio ?? 0.0,
                            child: CameraPreview(_controller!),
                          ),
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
                        for (imglib.Image img in splitImages!)
                          Image.memory(imglib.encodeJpg(img)),
                      ],
                    ),
            ),
            Expanded(
              flex: 2,
              child: pixelForImage == null
                  ? const Center(
                      child: Text('Split Images here'),
                    )
                  : GridView(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 2,
                        crossAxisSpacing: 2,
                        childAspectRatio: 1.5,
                      ),
                      children: [
                        for (List<double> rgb in pixelForImage!)
                          getPixelRep(rgb) ?? const SizedBox(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? getPixelRep(List<double> rgb) {
    if (rgb.length != 3) {
      return null;
    }
    return Row(
      children: [
        Container(
            color: Color.fromRGBO(
                rgb[0].toInt(), rgb[1].toInt(), rgb[2].toInt(), 0.7),
            width: MediaQuery.of(context).size.width / 4 - 2,
            child: Text(rgb.map((e) => e.toStringAsFixed(2)).toString()))
      ],
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
