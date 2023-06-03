import 'dart:async';
import 'dart:io';

import 'package:adhoc_chat_app/controllers/app_controller.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with WidgetsBindingObserver {
  //define the text Controller to controll the message text field
  final TextEditingController msgText = TextEditingController();
  //define an instance of FlutterP2pConnection class
  final _flutterP2pConnectionPlugin = FlutterP2pConnection();
  //define the list of devices that will jion the chat / be discovred
  List<DiscoveredPeers> peers = [];
  //define WifiP2PInfo instance which hold general information about the P2P connection
  WifiP2PInfo? wifiP2PInfo;
  //stream of type  WifiP2PInfo which will inform the program about any chnages regarding the information of WifiP2PInfo
  StreamSubscription<WifiP2PInfo>? _streamWifiInfo;
  //stream of discovred peers is used to continously see any devices appears when discovering is on
  StreamSubscription<List<DiscoveredPeers>>? _streamPeers;

  //init state function is called when the widget _ChatState defined above is first created
  @override
  void initState() {
    super.initState();
    //It allows you to interact with the lifecycle of the application and handle events related to it
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  //its called when this widget is distroyed
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flutterP2pConnectionPlugin.unregister();
    _appController.isConnected.value = false;
    super.dispose();
  }

  //monitoring the events and changed in the app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _flutterP2pConnectionPlugin.unregister();
    } else if (state == AppLifecycleState.resumed) {
      _flutterP2pConnectionPlugin.register();
    }
  }

  //its called inside the init_state which will initliaze the nessaccary streams and plugins
  void _init() async {
    await _flutterP2pConnectionPlugin.initialize();
    await _flutterP2pConnectionPlugin.register();
    _streamWifiInfo =
        _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
      setState(() {
        wifiP2PInfo = event;
      });
    });
    _streamPeers = _flutterP2pConnectionPlugin.streamPeers().listen((event) {
      setState(() {
        peers = event;
      });
    });
  }

  //this function will be used for to start socket connection with other peer
  Future startSocket() async {
    if (wifiP2PInfo != null) {
      bool started = await _flutterP2pConnectionPlugin.startSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 2,
        deleteOnError: true,
        onConnect: (name, address) {
          _appController.isConnected.value = true;
          toast("$name connected to socket with address: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            toast(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
          print(
              "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
        },
        receiveString: (req) async {
          if (req == "ack") {
            Fluttertoast.showToast(
                msg: req, textColor: Colors.green, gravity: ToastGravity.TOP);
          } else {
            _appController.Meesages.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          req,
                          textAlign: TextAlign.justify, //here the text go
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            _flutterP2pConnectionPlugin.sendStringToSocket("ack");
          }
        },
      );
      toast("open socket: $started");
    }
  }

  //this function will be used for to connect to an already established socket connection with other peer
  Future connectToSocket() async {
    if (wifiP2PInfo != null) {
      await _flutterP2pConnectionPlugin.connectToSocket(
        groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
        downloadPath: "/storage/emulated/0/Download/",
        maxConcurrentDownloads: 3,
        deleteOnError: true,
        onConnect: (address) {
          //execute th follwing when connection is started
          _appController.isConnected.value = true;
          toast("connected to socket: $address");
        },
        transferUpdate: (transfer) {
          if (transfer.completed) {
            toast(
                "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
          }
        },

        //when message is sccessfully received => show ack to the oother peer
        receiveString: (req) async {
          if (req == "ack") {
            Fluttertoast.showToast(
                msg: req, textColor: Colors.green, gravity: ToastGravity.TOP);
          } else {
            _appController.Meesages.add(
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          req,
                          textAlign: TextAlign.justify,
                          //here the text go
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
            _flutterP2pConnectionPlugin.sendStringToSocket("ack");
          }
        },
      );
    }
  }

  //this function will close the socket connection / Communication after this is nit possible
  Future closeSocketConnection() async {
    _appController.isConnected.value = false;
    bool closed =
        _flutterP2pConnectionPlugin.closeSocket(); //closing the socket
    toast("closed: $closed"); //showing to user
  }

  //this method will take the value from message text field and sned through the socket
  Future sendMessage() async {
    //checks if the message length is over 55 , to avoid overflow
    if (msgText.text.length < 55) {
      _appController.messageLengthOk.value = true;
      _flutterP2pConnectionPlugin.sendStringToSocket(msgText.text);
    } else {
      _appController.messageLengthOk.value =
          false; //notify that connection is still not possible when len >55
      Fluttertoast.showToast(
        msg: "You can not send more than 55 charcter!",
        textColor: Colors.red,
        fontSize: 20,
        gravity: ToastGravity.TOP,
      );
    }
  }

  //its a special package that enable the widget to show messages to the user
  void toast(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      gravity: ToastGravity.CENTER,
      textColor: Colors.green,
    );
  }

  //this is a controller that extends the GetX controller which will enalbe us to controll the state of the app in any place inside the widget
  final AppController _appController = Get.find();

  //Building the widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      //drawer is the menu that pop up from the left
      drawer: Drawer(
        shadowColor: Colors.red,
        backgroundColor: Colors.red.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: ListView(
            children: [
              enableLocationButton(),
              enableWifiButton(),
              createGroupButton(),
              removeOrDisconnectGroupButton(),
              showGroupInfoButton(context),
              getIpButton(),
            ],
          ),
        ),
      ),
      //chat screen app bar
      appBar: AppBar(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: Colors.blue,
        elevation: 10,
        backgroundColor: Colors.redAccent,
        actions: [
          //Show information
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.red.withOpacity(0.4),
                    title: const Text(
                      'Ip and other info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "Group Owner IP address: ${wifiP2PInfo == null ? "null" : wifiP2PInfo?.groupOwnerAddress}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        wifiP2PInfo != null
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(height: 10),
                                  const Divider(
                                    thickness: 2,
                                    color: Colors.red,
                                  ),
                                  Text(
                                    "connected: ${wifiP2PInfo?.isConnected}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 2,
                                  ),
                                  Text(
                                    'isGroupOwner: ${wifiP2PInfo?.isGroupOwner}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 2,
                                  ),
                                  Text(
                                    'groupFormed: ${wifiP2PInfo?.groupFormed}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 2,
                                  ),
                                  Text(
                                    'groupOwnerAddress: ${wifiP2PInfo?.groupOwnerAddress}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const Divider(
                                    thickness: 2,
                                  ),
                                  Text(
                                    'clients: ${wifiP2PInfo?.clients}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              )
                            : const SizedBox.shrink(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
            icon: const Icon(
              Icons.info,
            ),
          ),
        ],
        title: const Text('Chat Screen'),
      ),
      //components of the screen
      body: Column(
        children: [
          /*
            Widgets under this line are all called by their names using method 
          */
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              scrollDirection: Axis.vertical,
              child: Obx(
                () => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _appController.Meesages.value,
                  ),
                ),
              ),
            ),
          ),
          messageTextField(),
          sendMessageIcon(),
          towFiveFiveImage(),
          bottomActionButtons(),
        ],
      ),
    );
  }

  /*
    After this line , everything is just a widget that build the inetrface of the chat screen 
  */
  Image towFiveFiveImage() {
    return Image.asset(
      "images/255.jpg",
      width: 150,
      height: 240,
    );
  }

  Row sendMessageIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: Colors.red[900],
            child: IconButton(
              color: Colors.white,
              onPressed: () async {
                if (_appController.isConnected.value) {
                  await sendMessage();
                  //dont sned if meesgae length is > 55
                  if (!_appController.messageLengthOk.value) {
                    return;
                  }
                  _appController.Meesages.add(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.4),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                msgText.text,
                                textAlign: TextAlign.justify, //here the text go
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  //clearing meesage
                  msgText.clear();
                } else {
                  Fluttertoast.showToast(
                    msg: "Please make connection before start messaging!",
                    gravity: ToastGravity.CENTER,
                    textColor: Colors.red,
                    backgroundColor: Colors.black,
                  );
                }
              },
              icon: const Icon(Icons.send),
            ),
          ),
        ),
      ],
    );
  }

  Padding bottomActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [
              Colors.grey,
              Colors.redAccent,
              Colors.grey,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              //check Peers
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, bottom: 10, top: 10, right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Peers'),
                                content: discoverdPeersList(context),
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.search,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      "Find Peers",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    )
                  ],
                ),
              ),
              //discover Button
              Padding(
                padding: const EdgeInsets.only(
                    left: 10, bottom: 10, top: 10, right: 10),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black,
                        child: IconButton(
                          onPressed: () async {
                            bool? discovering =
                                await _flutterP2pConnectionPlugin.discover();
                            toast("discovering $discovering");
                          },
                          icon: const Icon(
                            Icons.connect_without_contact,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                      const Text(
                        "Discover",
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      )
                    ],
                  ),
                ),
              ),
              //Open Scoket
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, bottom: 10, top: 10, right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        onPressed: () async {
                          startSocket();
                        },
                        icon: const Icon(
                          Icons.wifi_calling,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      "Open Socket",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    )
                  ],
                ),
              ),
              //Connect To Socket
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, bottom: 10, top: 10, right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        onPressed: () async {
                          connectToSocket();
                        },
                        icon: const Icon(
                          Icons.connected_tv_sharp,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      "Connect to Socket",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    )
                  ],
                ),
              ),
              //stop discover Button
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, bottom: 10, top: 10, right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        onPressed: () async {
                          bool? stopped =
                              await _flutterP2pConnectionPlugin.stopDiscovery();
                          toast("stopped discovering $stopped");
                        },
                        icon: const Icon(
                          Icons.block,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      "Stop Discover",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    )
                  ],
                ),
              ),
              //Close Socket
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, bottom: 10, top: 10, right: 10),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.black,
                      child: IconButton(
                        onPressed: () async {
                          closeSocketConnection();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                    const Text(
                      "Close Socket",
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SizedBox discoverdPeersList(BuildContext context) {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: peers.length,
        itemBuilder: (context, index) => Center(
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Center(
                  child: AlertDialog(
                    content: SizedBox(
                      height: 200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("name: ${peers[index].deviceName}"),
                          Text("address: ${peers[index].deviceAddress}"),
                          Text("isGroupOwner: ${peers[index].isGroupOwner}"),
                          Text(
                              "isServiceDiscoveryCapable: ${peers[index].isServiceDiscoveryCapable}"),
                          Text(
                              "primaryDeviceType: ${peers[index].primaryDeviceType}"),
                          Text(
                              "secondaryDeviceType: ${peers[index].secondaryDeviceType}"),
                          Text("status: ${peers[index].status}"),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          bool? bo = await _flutterP2pConnectionPlugin
                              .connect(peers[index].deviceAddress);
                          toast("connected: $bo");
                        },
                        child: const Text("connect"),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 30,
              child: Center(
                child: Text(
                  peers[index]
                      .deviceName
                      .toString()
                      .characters
                      .first
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextField messageTextField() {
    return TextField(
      controller: msgText,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        hintText: "message",
      ),
    );
  }

  TextButton getIpButton() {
    return TextButton(
      onPressed: () async {
        String? ip = await _flutterP2pConnectionPlugin.getIPAddress();
        toast("ip: $ip");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "get ip",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  TextButton showGroupInfoButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        var info = await _flutterP2pConnectionPlugin.groupInfo();
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (context) => Center(
            child: Dialog(
              child: SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("groupNetworkName: ${info?.groupNetworkName}"),
                      Text("passPhrase: ${info?.passPhrase}"),
                      Text("isGroupOwner: ${info?.isGroupOwner}"),
                      Text("clients: ${info?.clients}"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "get group info",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  TextButton removeOrDisconnectGroupButton() {
    return TextButton(
      onPressed: () async {
        bool? removed = await _flutterP2pConnectionPlugin.removeGroup();
        toast("removed group: $removed");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "remove group/disconnect",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  TextButton createGroupButton() {
    return TextButton(
      onPressed: () async {
        bool? created = await _flutterP2pConnectionPlugin.createGroup();
        toast("created group: $created");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "create group",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  TextButton enableWifiButton() {
    return TextButton(
      onPressed: () async {
        await _flutterP2pConnectionPlugin.enableWifiServices();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "enable wifi",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  TextButton enableLocationButton() {
    return TextButton(
      onPressed: () async {
        print(await _flutterP2pConnectionPlugin.enableLocationServices());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.all(15),
          child: Text(
            "enable location",
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton askLocationPermissionButton() {
    return ElevatedButton(
      onPressed: () async {
        print(await _flutterP2pConnectionPlugin.askLocationPermission());
      },
      child: const Text("ask location permission"),
    );
  }
}
