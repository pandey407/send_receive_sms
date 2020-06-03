import 'package:flutter/material.dart';
import 'package:sms_maintained/sms.dart';

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
  List<TextEditingController> numberControllers;
  List<String> hintText;
  List<String> messageLead;
  List<bool> _invalidInputs;
  List<bool> _selections;
  List<bool> _replyWaiting;
  List<String> optionText;
  int _currentIndex;
  List<String> replies;
  String address = '5556';
  @override
  void initState() {
    super.initState();
    numberControllers = [TextEditingController(), TextEditingController()];
    receiver = SmsReceiver();
    _selections = [true, false];
    _invalidInputs = [false, false];
    _replyWaiting = [false, false];
    replies = [' ', ' '];
    hintText = ['Applicant ID', 'License number'];
    messageLead = ['WT', 'LC'];
    optionText = ['लिखित नतिजा', 'लाइसेन्स प्रिन्ट'];
    _currentIndex = 0;
  }

  @override
  void dispose() {
    numberControllers.map((controller) => controller.dispose());
    super.dispose();
  }

  _sendSMS(String number) {
    SmsSender sender = new SmsSender();
    SmsMessage message =
        new SmsMessage(address, '${messageLead[_currentIndex]} $number');
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(15),
                    borderWidth: 3,
                    fillColor: Theme.of(context).primaryColor,
                    selectedColor: Theme.of(context).textSelectionColor,
                    children: optionText
                        .map(
                          (option) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              option,
                            ),
                          ),
                        )
                        .toList(),
                    isSelected: _selections,
                    onPressed: (int index) {
                      setState(() {
                        for (int i = 0; i < _selections.length; i++) {
                          if (i == index) {
                            _selections[i] = true;
                            _currentIndex = i;
                          } else {
                            _selections[i] = false;
                          }
                        }
                      });
                    },
                  ),
                ),
              ),
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
                      hintText: 'Enter your ${hintText[_currentIndex]}',
                      labelText: hintText[_currentIndex],
                      icon: Icon(Icons.message),
                      errorText: _invalidInputs[_currentIndex]
                          ? '${hintText[_currentIndex]} can\'t be empty'
                          : null,
                    ),
                    controller: numberControllers[_currentIndex],
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
                      numberControllers[_currentIndex].text.isEmpty
                          ? _invalidInputs[_currentIndex] = true
                          : _invalidInputs[_currentIndex] = false;
                    });
                    if (!_invalidInputs[_currentIndex] &&
                        numberControllers[_currentIndex].text.isNotEmpty) {
                      _sendSMS(numberControllers[_currentIndex].text);
                      setState(() {
                        for (int i = 0; i < _replyWaiting.length; i++) {
                          if (i == _currentIndex) {
                            _replyWaiting[i] = true;
                          } else {
                            _replyWaiting[i] = false;
                          }
                        }
                      });
                    }
                  },
                ),
              ),
              StreamBuilder(
                  stream: receiver.onSmsReceived,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.hasData) {
                      if (!replies.contains(snapshot.data.body) &&
                          _replyWaiting[_currentIndex]) {
                        replies[_currentIndex] = snapshot.data.body;
                        return buildCustomTile();
                      } else if (replies[_currentIndex] != ' ') {
                        return buildCustomTile();
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

  Container buildCustomTile() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'SMS from DoTM',
              textAlign: TextAlign.center,
            ),
          ),
          Divider(color: Colors.white70),
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              replies[_currentIndex],
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
