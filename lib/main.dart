import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_streams/audio_streams.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebSocketChannel channel;

  Stream<List<int>> stream;
  AudioController controller;

  bool isRecording = false;
  DateTime startTime;

  @override
  void initState() {
    super.initState();
    /// 웹소켓 연결
    wssconnect();
    /// 플랫폼에 따라서 오디오 스크리밍 라이브러리를 변경하여 사용
    if (Platform.isAndroid) {
      /// Android-specific code
      initAudioAndroid();
    } else if (Platform.isIOS) {
      /// iOS-specific code
      initAudioIOS();
    }
  }

  @override
  void dispose() {
    super.dispose();

    channel.sink.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('aaaa'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              (isRecording) ? 'Recording' : 'Not recording',
            ),
            Text(
              'abcd',
            ),
            StreamBuilder(
              stream: channel.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print(jsonDecode(snapshot.data));
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(snapshot.hasData ? '${snapshot.data}' : ''),
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _controlMicStream,
        tooltip: 'Increment',
        child: (isRecording) ? Icon(Icons.stop) : Icon(Icons.keyboard_voice),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  // Responsible for switching between recording / idle state
  void _controlMicStream() async {
    _changeListening();
  }

  bool _changeListening() {
    return !isRecording ? _startListening() : _stopListening();
  }

  bool _startListening() {
    if (isRecording) return false;

    setState(() {
      isRecording = true;
      startTime = DateTime.now();
    });
    /// 웹소켓 연결
    wssconnect();
    print("Start Listening to the microphone");
    return true;
  }

  bool _stopListening() {
    if (!isRecording) return false;

    setState(() {
      isRecording = false;
      startTime = null;
    });
    print("Stop Listening to the microphone");
    return true;
  }

  /// 웹소켓 연결 프로세스
  void wssconnect() {
    String API_ID = 'minds-edu-api-stt';
    String API_KEY = '982326d160684a489dcbeb7445ecd644';
    String user_id = 'userId';
    String model = 'customer1';
    String answer_text = 'What are you doing there?';

    // 문장을 인코딩해주어야 한다. Uri.encodeFull
    String param =
        "?apiId=$API_ID&apiKey=$API_KEY&userId=$user_id&model=$model&answerText=${Uri.encodeFull(answer_text)}&chksym=undefined";
    String url = 'wss://maieng.maum.ai:7777/engedu/v1/websocket/pron$param';
    //String url = 'wss://websocket-ykgtl.run.goorm.io';

    setState(() {
      channel = IOWebSocketChannel.connect(url); //연결
    });
  }

  /// 안드로이드용 오디오 스트리밍 처리
  Future<void> initAudioAndroid() async {
    stream = microphone(
        audioSource: AudioSource.VOICE_RECOGNITION,
        sampleRate: 16000,
        channelConfig: ChannelConfig.CHANNEL_IN_MONO,
        audioFormat: AudioFormat.ENCODING_PCM_16BIT);
    stream.listen((samples) {
      if(isRecording) {
        //print(samples);
        //channel.sink.add(samples); //8bit 에서 작동 음질 찢어짐

        //print(Uint8List.fromList(samples));
        //channel.sink.add(Uint8List.fromList(samples)); //8bit, 16bit 에서 작동 음질 찢어짐

        print(utf8.encode(samples.join()));
        channel.sink.add(utf8.encode(samples.join())); //8bit, 16bit 에서 작동 음질 노이즈 심함

        //https://github.com/anarchuser/mic_stream/issues/9 //이슈상황
      }
    });
  }

  /// 아이폰용 오디오 스트리밍 처리
  Future<void> initAudioIOS() async {
    controller = new AudioController(CommonFormat.Int16, 16000, 1, true);
    await controller.intialize();
    controller.startAudioStream().listen((samples) async {
      if (isRecording) {
        //print(samples);
        //channel.sink.add(samples); //8bit 에서 작동 음질 찢어짐

        //print(Uint8List.fromList(samples));
        //channel.sink.add(Uint8List.fromList(samples)); //8bit, 16bit 에서 작동 음질 찢어짐

        print(utf8.encode(samples.join()));
        channel.sink.add(utf8.encode(samples.join())); //8bit, 16bit 에서 작동 음질 노이즈 심함
      }
    });
  }
}
