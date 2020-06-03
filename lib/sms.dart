/// An SMS library for flutter
library sms_send_receive;

import 'dart:async';
import 'package:flutter/services.dart';

typedef OnError(Object error);

enum SmsMessageState {
  Sending,
  Sent,
  Delivered,
  Fail,
  None,
}

enum SmsMessageKind {
  Sent,
  Received,
  Draft,
}

/// A SMS Message
///
/// Used to send message or used to read message.
class SmsMessage implements Comparable<SmsMessage> {
  int _id;
  String _address;
  String _body;
  bool _read;
  DateTime _date;
  DateTime _dateSent;
  SmsMessageKind _kind;
  SmsMessageState _state = SmsMessageState.None;
  StreamController<SmsMessageState> _stateStreamController =
      new StreamController<SmsMessageState>();

  SmsMessage(this._address, this._body,
      {int id,
      bool read,
      DateTime date,
      DateTime dateSent,
      SmsMessageKind kind}) {
    this._id = id;
    this._read = read;
    this._date = date;
    this._dateSent = dateSent;
    this._kind = kind;
  }

  /// Read message from JSON
  ///
  /// Format:
  ///
  /// ```json
  /// {
  ///   "address": "phone-number-here",
  ///   "body": "text message here"
  /// }
  /// ```
  SmsMessage.fromJson(Map data) {
    this._address = data["address"];
    this._body = data["body"];
    if (data.containsKey("_id")) {
      this._id = data["_id"];
    }
    if (data.containsKey("read")) {
      this._read = data["read"] as int == 1;
    }
    if (data.containsKey("kind")) {
      this._kind = data["kind"];
    }
    if (data.containsKey("date")) {
      this._date = new DateTime.fromMillisecondsSinceEpoch(data["date"]);
    }
    if (data.containsKey("date_sent")) {
      this._dateSent =
          new DateTime.fromMillisecondsSinceEpoch(data["date_sent"]);
    }
  }

  /// Convert SMS to map
  Map get toMap {
    Map res = {};
    if (_address != null) {
      res["address"] = _address;
    }
    if (_body != null) {
      res["body"] = _body;
    }
    if (_id != null) {
      res["_id"] = _id;
    }
    if (_read != null) {
      res["read"] = _read;
    }
    if (_date != null) {
      res["date"] = _date.millisecondsSinceEpoch;
    }
    if (_dateSent != null) {
      res["dateSent"] = _dateSent.millisecondsSinceEpoch;
    }
    return res;
  }

  /// Get message id
  int get id => this._id;
  /// Get sender, alias phone number
  String get sender => this._address;

  /// Get address, alias phone number
  String get address => this._address;

  /// Get message body
  String get body => this._body;

  /// Check if message is read
  bool get isRead => this._read;

  /// Get date
  DateTime get date => this._date;

  /// Get date sent
  DateTime get dateSent => this._dateSent;

  /// Get message kind
  SmsMessageKind get kind => this._kind;

  Stream<SmsMessageState> get onStateChanged => _stateStreamController.stream;

  /// Set message kind
  set kind(SmsMessageKind kind) => this._kind = kind;

  /// Set message date
  set date(DateTime date) => this._date = date;

  /// Get message state
  get state => this._state;

  set state(SmsMessageState state) {
    if (this._state != state) {
      this._state = state;
      _stateStreamController.add(state);
    }
  }

  @override
  int compareTo(SmsMessage other) {
    return other._id - this._id;
  }
}

/// A SMS receiver that creates a stream of SMS
///
///
/// Usage:
///
/// ```dart
/// var receiver = SmsReceiver();
/// receiver.onSmsReceived.listen((SmsMessage msg) => ...);
/// ```
class SmsReceiver {
  static SmsReceiver _instance;
  final EventChannel _channel;
  Stream<SmsMessage> _onSmsReceived;

  factory SmsReceiver() {
    if (_instance == null) {
      final EventChannel eventChannel = const EventChannel(
          "plugins.babariviere.com/recvSMS", const JSONMethodCodec());
      _instance = new SmsReceiver._private(eventChannel);
    }
    return _instance;
  }

  SmsReceiver._private(this._channel);

  /// Create a stream that collect received SMS
  Stream<SmsMessage> get onSmsReceived {
    if (_onSmsReceived == null) {
      print("Creating sms receiver");
      _onSmsReceived = _channel.receiveBroadcastStream().map((dynamic event) {
        SmsMessage msg = new SmsMessage.fromJson(event);
        msg.kind = SmsMessageKind.Received;
        return msg;
      });
    }
    return _onSmsReceived;
  }
}

/// A SMS sender
class SmsSender {
  static SmsSender _instance;
  final MethodChannel _channel;
  final EventChannel _stateChannel;
  Map<int, SmsMessage> _sentMessages;
  int _sentId = 0;
  final StreamController<SmsMessage> _deliveredStreamController =
      new StreamController<SmsMessage>();

  factory SmsSender() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
          "plugins.babariviere.com/sendSMS", const JSONMethodCodec());
      final EventChannel stateChannel = const EventChannel(
          "plugins.babariviere.com/statusSMS", const JSONMethodCodec());

      _instance = new SmsSender._private(methodChannel, stateChannel);
    }
    return _instance;
  }

  SmsSender._private(this._channel, this._stateChannel) {
    _stateChannel.receiveBroadcastStream().listen(this._onSmsStateChanged);

    _sentMessages = new Map<int, SmsMessage>();
  }

  /// Send an SMS
  ///
  /// Take a message in argument + 2 functions that will be called on success or on error
  ///
  /// This function will not set automatically thread id, you have to do it
  Future<SmsMessage> sendSms(SmsMessage msg) async {
    if (msg == null || msg.address == null || msg.body == null) {
      if (msg == null) {
        throw ("no given message");
      } else if (msg.address == null) {
        throw ("no given address");
      } else if (msg.body == null) {
        throw ("no given body");
      }
      return null;
    }

    msg.state = SmsMessageState.Sending;
    Map map = msg.toMap;
    this._sentMessages.putIfAbsent(this._sentId, () => msg);
    map['sentId'] = this._sentId;

    await _channel.invokeMethod("sendSMS", map);
    msg.date = new DateTime.now();

    return msg;
  }

  Stream<SmsMessage> get onSmsDelivered => _deliveredStreamController.stream;

  void _onSmsStateChanged(dynamic stateChange) {
    int id = stateChange['sentId'];
    if (_sentMessages.containsKey(id)) {
      switch (stateChange['state']) {
        case 'sent':
          {
            _sentMessages[id].state = SmsMessageState.Sent;
            break;
          }
        case 'delivered':
          {
            _sentMessages[id].state = SmsMessageState.Delivered;
            _deliveredStreamController.add(_sentMessages[id]);
            _sentMessages.remove(id);
            break;
          }
        case 'fail':
          {
            _sentMessages[id].state = SmsMessageState.Fail;
            _sentMessages.remove(id);
            break;
          }
      }
    }
  }
}
