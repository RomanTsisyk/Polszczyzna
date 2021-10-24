import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mighty_news/components/AppWidgets.dart';
import 'package:mighty_news/main.dart';
import 'package:nb_utils/nb_utils.dart';

enum TtsState { playing, stopped, paused, continued }

class ReadAloudDialog extends StatefulWidget {
  static String tag = '/ReadAloudDialog';
  final String text;

  ReadAloudDialog(this.text);

  @override
  ReadAloudDialogState createState() => ReadAloudDialogState();
}

class ReadAloudDialogState extends State<ReadAloudDialog> with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();

  TtsState ttsState = TtsState.stopped;

  AnimationController animationController;
  int currentWordPosition = 0;
  int progress = 0;

  bool isError = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    init();
  }

  Future<void> init() async {
    bool isLanguageFound = false;
    flutterTts.awaitSpeakCompletion(true);
    flutterTts.getLanguages.then((value) {
      Iterable it = value;

      it.forEach((element) {
        if (element.toString().contains(appStore.languageForTTS)) {
          flutterTts.setLanguage(element);
          initTTS();
          isLanguageFound = true;
        }
      });
    });

    if (!isLanguageFound) initTTS();
  }

  Future<void> initTTS() async {
    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      stop();
    });


    flutterTts.setErrorHandler((msg) async {
      await Future.delayed(Duration(milliseconds: 500));

      if (!isError && mounted && context != null) {
        isError = true;
        finish(context);
        toast(errorSomethingWentWrong);
      }
    });

    flutterTts.setCancelHandler(() async {
      /*await Future.delayed(Duration(milliseconds: 200));

      finish(context);
      toast(errorSomethingWentWrong);*/
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        ttsState = TtsState.continued;
      });
    });

    await Future.delayed(Duration(milliseconds: 300));
    speak();
  }

  Future speak() async {
    currentWordPosition = 0;
    progress = 0;
    animationController.forward();

    // var result = await flutterTts.speak(widget.text);
    flutterTts.awaitSpeakCompletion(true);
    var count = widget.text.length;
    var max = 3000;
    var loopCount = count ~/max;

    for( var i = 0 ; i <= loopCount; i++ ) {
      if (i != loopCount) {
        await flutterTts.speak(widget.text.substring(i*max, (i+1)*max));
      } else {
        var end = (count - ((i*max))+(i*max));
        await flutterTts.speak(widget.text.substring(i*max, end));
      }
    }

    // if (result == 1) setState(() => ttsState = TtsState.playing);
  }

  Future stop() async {
    currentWordPosition = 0;
    progress = 0;

    animationController.reverse();

    var result = await flutterTts.stop();

    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts?.stop();
    animationController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width(),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // cachedImage(
          //   'https://upload.wikimedia.org/wikipedia/commons/thumb/4/43/Red_flag.svg/800px-Red_flag.svg.png',
          //   fit: BoxFit.cover,
          // ).cornerRadiusWithClipRRect(defaultRadius).opacity(opacity: 0.7),
          // Column(
          //   mainAxisSize: MainAxisSize.min,
          //   children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: IconButton(
                      onPressed: () {
                        ttsState == TtsState.playing ? stop() : speak();
                      },
                      icon: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: animationController, color: Colors.black),
                    ),
                  ),
                  Text('${ttsState == TtsState.playing ? 'Playing' : 'Stopped'}', style: boldTextStyle()),
                  64.width,
                  Positioned(child: CloseButton(), top: 16, right: 16),
                ],
              ),
              // 30.height,
            ],
          // ),
          // Positioned(child: CloseButton(), top: 16, right: 16),
        // ],
      ),
    );
  }
}
