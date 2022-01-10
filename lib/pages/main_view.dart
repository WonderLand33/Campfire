import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/pages/settings_view/settings_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/events.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:provider/provider.dart';

import './pages.dart';
import '../widgets/custom_buttons/app_bar_icon_button.dart';

/// MainView refers to the main tab bar navigation and view system in place
class MainView extends StatefulWidget {
  MainView({Key key, this.pageIndex, this.args, this.disableRefreshOnInit})
      : super(key: key);

  final int pageIndex;
  final Map<String, dynamic> args;
  final bool disableRefreshOnInit;

  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  NodeConnectionStatus nodeState = NodeConnectionStatus.loading;
  int _currentIndex = 1;
  final double _navBarRadius = SizingUtilities.circularBorderRadius * 1.8;

  bool _hasSynced = false;
  bool _disableRefreshOnInit = false;

  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  List<Widget> children;

  /// Tab icon color based on tab selection
  Color _buildIconColor(int index) {
    if (index == this._currentIndex) {
      return CFColors.spark;
    } else {
      return CFColors.twilight;
    }
  }

  //
  /// Tab text color based on tab selection
  TextStyle _buildTextStyle(int index) {
    if (index == this._currentIndex) {
      return GoogleFonts.workSans(
        textStyle: TextStyle(
          color: CFColors.spark,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
        ),
      );
    } else {
      return GoogleFonts.workSans(
        textStyle: TextStyle(
          color: CFColors.twilight,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
        ),
      );
    }
  }

  void _setCurrentIndex(int newIndex) {
    setState(() {
      _currentIndex = newIndex;
    });
  }

  StreamSubscription _nodeConnectionStatusChangedEventListener;

  @override
  void initState() {
    // show system status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // statusBarBrightness: Brightness.dark,
      ),
    );

    if (widget.disableRefreshOnInit != null) {
      _disableRefreshOnInit = widget.disableRefreshOnInit;
      nodeState = NodeConnectionStatus.synced;
    }

    if (widget.pageIndex != null) {
      _currentIndex = widget.pageIndex;
    }

    children = [
      SendView(
        autofillArgs: widget.args,
      ),
      WalletView(),
      ReceiveView(),
      MoreView(),
    ];

    _nodeConnectionStatusChangedEventListener =
        GlobalEventBus.instance.on<NodeConnectionStatusChangedEvent>().listen((event) {
      if (nodeState != event.newStatus) {
        setState(() {
          nodeState = event.newStatus;
        });
      }
    });

    if (!_disableRefreshOnInit) {
      Provider.of<BitcoinService>(context, listen: false).refreshWalletData();
    }

    super.initState();
  }

  @override
  dispose() {
    _nodeConnectionStatusChangedEventListener.cancel();
    super.dispose();
  }

  AppBar buildAppBar(BuildContext context) {
    final bitcoinService = Provider.of<BitcoinService>(context);
    return AppBar(
      backgroundColor: CFColors.white,
      title: FutureBuilder(
        future: bitcoinService.currentWalletName,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Text(
              snapshot.data == null ? "Error loading wallet..." : snapshot.data,
              style: GoogleFonts.workSans(
                color: CFColors.spark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            );
          } else {
            return CircularProgressIndicator(
              color: CFColors.spark,
              strokeWidth: 2,
            );
          }
        },
      ),

      // trailing appbar button
      actions: [
        Padding(
          padding: EdgeInsets.only(
            top: 10,
            bottom: 10,
            right: 20,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: AppBarIconButton(
              size: 36,
              icon: SvgPicture.asset(
                "assets/svg/menu.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
              circularBorderRadius: 8,
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) {
                      return SettingsView();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],

      // leading appbar button
      leadingWidth: 36.0 + 20.0, // account for 20 padding

      leading: Padding(
        padding: EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 20,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: AppBarIconButton(
            size: 36,
            onPressed: () {
              _disableRefreshOnInit = false;
              bitcoinService.refreshWalletData();
            },
            circularBorderRadius: 8,
            icon: _selectIconAsset(),
          ),
        ),
      ),
    );
  }

  _selectIconAsset() {
    switch (nodeState) {
      case NodeConnectionStatus.synced:
        return SvgPicture.asset(
          "assets/svg/radio.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.connecting:
        return SvgPicture.asset(
          "assets/svg/refresh-cw.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.disconnected:
        return SvgPicture.asset(
          "assets/svg/radio-disconnected.svg",
          color: CFColors.twilight,
          width: 24,
          height: 24,
        );

      case NodeConnectionStatus.loading:
        return SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: CFColors.twilight,
            strokeWidth: 2,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      backgroundColor: CFColors.white,
      // bottomNavigationBar: new Theme(
      //   data: Theme.of(context).copyWith(canvasColor: ColorStyles.mist),
      appBar: buildAppBar(context),
      extendBody: true,
      bottomNavigationBar: Container(
        height: SizingUtilities.bottomToolBarHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_navBarRadius),
            topRight: Radius.circular(_navBarRadius),
          ),
          boxShadow: <BoxShadow>[
            CFColors.standardBoxShadow,
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_navBarRadius),
            topRight: Radius.circular(_navBarRadius),
          ),
          child: BottomNavigationBar(
            backgroundColor: CFColors.mist,
            // elevation: 0,
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            onTap: _setCurrentIndex,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  "assets/svg/send.svg",
                  color: _buildIconColor(0), // Index 0 -> send view
                  semanticsLabel: "send navigation logo",
                ),
                title: Text(
                  "Send",
                  style: _buildTextStyle(0),
                ),
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  "assets/svg/wallet.svg",
                  color: _buildIconColor(1), // Index 1 -> wallet view
                ),
                title: Text(
                  "Wallet",
                  style: _buildTextStyle(1),
                ),
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  "assets/svg/receive.svg",
                  color: _buildIconColor(2), // Index 2 -> receive view
                ),
                title: Text(
                  "Receive",
                  style: _buildTextStyle(2),
                ),
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.menu,
                  color: _buildIconColor(5), // Index 2
                ),
                title: Text(
                  "More",
                  style: _buildTextStyle(5),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          IndexedStack(
            children: children,
            index: _currentIndex,
          ),
          if (nodeState == NodeConnectionStatus.loading && !_disableRefreshOnInit)
            _buildSyncing(),
          if (nodeState == NodeConnectionStatus.synced && !_disableRefreshOnInit)
            _buildConnected(),
          if (nodeState == NodeConnectionStatus.disconnected && !_disableRefreshOnInit)
            _buildDisconnected(),
        ],
      ),
      // ),
    );
  }

  Column _buildDisconnected() {
    return Column(
      children: [
        _buildDropDown(
            context, "Could not connect. Tap to retry.", CFColors.dropdownError),
      ],
    );
  }

  Widget _buildConnected() {
    if (_hasSynced) {
      return Container();
    }
    _hasSynced = true;
    return Column(
      children: [
        FutureBuilder(
          future: Future.delayed(Duration(seconds: 3)),
          builder: (context, snapshot) {
            // return empty container to clear message after some time
            if (snapshot.connectionState == ConnectionState.done) {
              return Container();
            } else {
              return _buildDropDown(context, "Connected", CFColors.notificationSuccess);
            }
          },
        ),
      ],
    );
  }

  Column _buildSyncing() {
    _hasSynced = false;
    return Column(
      children: [
        _buildDropDown(context, "Synchronizing", CFColors.dropdownSynchronizing),
      ],
    );
  }

  Container _buildDropDown(BuildContext context, String message, Color backgroundColor) {
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(SizingUtilities.circularBorderRadius),
            bottomRight: Radius.circular(SizingUtilities.circularBorderRadius),
          ),
          boxShadow: [
            BoxShadow(
              color: CFColors.shadowColor,
              spreadRadius: 0.2,
              blurRadius: 1,
              offset: Offset(0, 2),
            )
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: FittedBox(
            child: Text(
              message,
              style: GoogleFonts.workSans(
                decoration: TextDecoration.none,
                color: CFColors.dusk,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
