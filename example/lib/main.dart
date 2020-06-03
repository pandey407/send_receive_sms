import 'package:flutter/material.dart';
import 'package:send_receive_sms/sms.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SmsSendPage(),
    );
  }
}

class SmsSendPage extends StatefulWidget {
  @override
  _SmsSendPageState createState() => _SmsSendPageState();
}

class _SmsSendPageState extends State<SmsSendPage> {
  SmsReceiver receiver;
  TextEditingController controller;
  String hintText;
  bool _invalidInput;
  bool _replyWaiting;
  String reply;
  String address = '5554';
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    receiver = SmsReceiver();
    _invalidInput = false;
    _replyWaiting = false;
    reply = ' ';
    hintText = 'Message';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  _sendSMS(String toSend) {
    SmsSender sender = new SmsSender();
    SmsMessage message = new SmsMessage(address, toSend);
    message.onStateChanged.listen((state) {
      if (state == SmsMessageState.Sending) {
        //_showToast('Sending', false);
      }
      if (state == SmsMessageState.Sent) {
        print('SENT');
      } else if (state == SmsMessageState.Delivered) {
        print("SMS is delivered!");
      }
    });
    sender.sendSms(message);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('लिखित/लाइसेन्स नतिजा'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                        width: 2, color: Theme.of(context).textSelectionColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter your $hintText',
                      labelText: hintText,
                      icon: Icon(Icons.message),
                      errorText:
                          _invalidInput ? '$hintText can\'t be empty' : null,
                    ),
                    controller: controller,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton.extended(
                  icon: Icon(Icons.send),
                  label: Text('Send'),
                  onPressed: () {
                    setState(() {
                      controller.text.isEmpty
                          ? _invalidInput = true
                          : _invalidInput = false;
                    });
                    if (!_invalidInput && controller.text.isNotEmpty) {
                      _sendSMS(controller.text);
                      setState(() {
                        _replyWaiting = true;
                      });
                    }
                  },
                ),
              ),
              StreamBuilder(
                  stream: receiver.onSmsReceived,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if (reply != (snapshot.data.body) && _replyWaiting) {
                        reply = snapshot.data.body;
                        return Text(reply);
                      } else if (reply != ' ') {
                        return Text(reply);
                      } else {
                        return Container();
                      }
                    } else {
                      return Container();
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }
}