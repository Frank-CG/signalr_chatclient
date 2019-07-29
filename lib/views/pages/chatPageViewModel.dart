import 'package:chatclient/main.dart';
import 'package:chatclient/utils/viewModel/viewModel.dart';
import 'package:chatclient/utils/viewModel/viewModelProvider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:signalr_client/signalr_client.dart';
import 'package:logging/logging.dart';

typedef HubConnectionProvider = Future<HubConnection> Function();

// If you want only to log out the message for the higer level hub protocol:
final hubProtLogger = Logger("SignalR - hub");
// If youn want to also to log out transport messages:
final transportProtLogger = Logger("SignalR - transport");

class ChatMessage {
  // Properites

  final String senderName;
  final String message;

  // Methods
  ChatMessage(this.senderName, this.message);
}

class ChatPageViewModel extends ViewModel {
// Properties
  String _serverUrl;
  HubConnection _hubConnection;

  List<ChatMessage> _chatMessages;
  static const String chatMessagesPropName = "chatMessages";
  List<ChatMessage> get chatMessages => _chatMessages;

  bool _connectionIsOpen;
  static const String connectionIsOpenPropName = "connectionIsOpen";
  bool get connectionIsOpen => _connectionIsOpen;
  set connectionIsOpen(bool value) {
    updateValue(connectionIsOpenPropName, _connectionIsOpen, value, (v) => _connectionIsOpen = v);
  }

  String _userName;
  static const String userNamePropName = "userName";
  String get userName => _userName;
  set userName(String value) {
    updateValue(userNamePropName, _userName, value, (v) => _userName = v);
  }



final httpOptions = new HttpConnectionOptions(logger: transportProtLogger, transport: HttpTransportType.WebSockets);

// Methods

  ChatPageViewModel() {
    _serverUrl = kChatServerUrl + "/chatHub";
    _chatMessages = List<ChatMessage>();
    _connectionIsOpen = false;
    _userName = "Fred";

    openChatConnection();
  }

  Future<void> openChatConnection() async {
    if (_hubConnection == null) {
      // _hubConnection = HubConnectionBuilder().withUrl(_serverUrl).build();
      _hubConnection = HubConnectionBuilder().withUrl(_serverUrl, options: httpOptions).configureLogging(hubProtLogger).build();

      _hubConnection.onclose((error) => connectionIsOpen = false);
      _hubConnection.on("ReceiveMessage", _handleIncommingChatMessage);
    }

    // if (_hubConnection.state != HubConnectionState.Connected) {
    if(!connectionIsOpen) {
      await _hubConnection.start();
      connectionIsOpen = true;
    }
  }

  Future<void> sendChatMessage(String chatMessage) async {
    if( chatMessage == null ||chatMessage.length == 0){
      return;
    }
    // await openChatConnection();
    _hubConnection.invoke("SendMessage", args: <Object>[userName, chatMessage] );
  }

  void _handleIncommingChatMessage(List<Object> args){
    final String senderName = args[0];
    final String message = args[1];
    _chatMessages.add( ChatMessage(senderName, message));
    notifyPropertyChanged(chatMessagesPropName);
  }
}

class ChatPageViewModelProvider extends ViewModelProvider<ChatPageViewModel> {
  // Properties

  // Methods
  ChatPageViewModelProvider({Key key, viewModel: ChatPageViewModel, WidgetBuilder childBuilder}) : super(key: key, viewModel: viewModel, childBuilder: childBuilder);

  static ChatPageViewModel of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(ChatPageViewModelProvider) as ChatPageViewModelProvider).viewModel;
  }
}
