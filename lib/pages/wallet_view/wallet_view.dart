import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/transaction_subviews/transaction_search_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/event_bus/events/node_connection_status_changed_event.dart';
import 'package:paymint/services/event_bus/global_event_bus.dart';
import 'package:paymint/services/utils/currency_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/shared_utilities.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/text_switch_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:paymint/widgets/transaction_card.dart';
import 'package:provider/provider.dart';

class WalletView extends StatefulWidget {
  WalletView({Key key}) : super(key: key);

  @override
  _WalletViewState createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  NodeConnectionStatus _nodeStatus = NodeConnectionStatus.disconnected;

  StreamSubscription _nodeConnectionStatusChangedEventListener;

  @override
  void initState() {
    // add listener
    _nodeConnectionStatusChangedEventListener = GlobalEventBus.instance
        .on<NodeConnectionStatusChangedEvent>()
        .listen((event) {
      if (_nodeStatus != event.newStatus) {
        setState(() {
          _nodeStatus = event.newStatus;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _nodeConnectionStatusChangedEventListener.cancel();
    super.dispose();
  }

  TextSwitchButtonState _balanceToggleState = TextSwitchButtonState.available;

  @override
  Widget build(BuildContext context) {
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);

    final double _bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        SizingUtilities.bottomToolBarHeight;

    /// list of balances with length of 4 is expected
    // index 0 and 1 for the funds available to spend.
    // index 2 and 3 for all the funds in the wallet (including the undependable ones)
    Widget _buildBalance(List<String> balances) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18,
              width: 126,
              child: TextSwitchButton(
                buttonStateChanged: (state) {
                  print("balance switch button changed to: $state");
                  setState(() {
                    _balanceToggleState = state;
                  });
                },
              ),
            ),
            SizedBox(
              height: 14,
            ),
            FittedBox(
              child: Text(
                _balanceToggleState == TextSwitchButtonState.available
                    ? "${balances[0]} ${CurrencyUtilities.coinName}"
                    : "${balances[2]} ${CurrencyUtilities.coinName}",
                style: GoogleFonts.workSans(
                  color: CFColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            FittedBox(
              child: FutureBuilder(
                future: bitcoinService.currency,
                builder: (context, AsyncSnapshot<String> snapshot) {
                  String fiatTicker = "...";
                  if (snapshot.connectionState == ConnectionState.done) {
                    fiatTicker = snapshot.data;
                  }
                  return Text(
                    _balanceToggleState == TextSwitchButtonState.available
                        ? "${balances[1]} $fiatTicker"
                        : "${balances[3]} $fiatTicker",
                    style: GoogleFonts.workSans(
                      color: CFColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: CFColors.white,
      body: Container(
        height: _bodyHeight -
            10, // needed to fit content on screen. Magic numbers \o/
        color: CFColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 10,
                horizontal: SizingUtilities.standardPadding,
              ),
              child: GradientCard(
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                gradient: CFColors.fireGradientVerticalLight,
                child: Stack(
                  children: [
                    FutureBuilder(
                      future: bitcoinService.getFullBalance(),
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> balancesData) {
                        if (balancesData.connectionState ==
                            ConnectionState.done) {
                          if (balancesData == null || balancesData.hasError) {
                            return _buildBalance(["...", "...", "...", "..."]);
                          }

                          if (_nodeStatus == NodeConnectionStatus.synced)
                            return _buildBalance(balancesData.data);
                          else {
                            return _buildBalance(["...", "...", "...", "..."]);
                          }
                        } else {
                          return _buildBalance(["...", "...", "...", "..."]);
                        }
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Opacity(
                          opacity: 0.5,
                          child: SvgPicture.asset(
                            "assets/svg/groupLogo.svg",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: SizingUtilities.standardPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TRANSACTIONS",
                    style: GoogleFonts.workSans(
                      color: CFColors.twilight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          useSafeArea: false,
                          barrierDismissible: false,
                          builder: (context) {
                            return TransactionSearchView();
                          });
                    },
                    icon: Icon(
                      FeatherIcons.search,
                      color: CFColors.twilight,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: bitcoinService.lelantusTransactionData,
                builder: (context, txData) {
                  if (txData.connectionState == ConnectionState.done) {
                    final data = txData.data;
                    if (_nodeStatus == NodeConnectionStatus.synced) {
                      return _buildTransactionList(context, data);
                    } else {
                      return Center(
                        child: SpinKitThreeBounce(
                          color: CFColors.spark,
                          size: MediaQuery.of(context).size.width * 0.1,
                        ),
                      );
                    }
                  } else {
                    return Center(
                      child: SpinKitThreeBounce(
                        color: CFColors.spark,
                        size: MediaQuery.of(context).size.width * 0.1,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// build transaction list after loading data
Widget _buildTransactionList(BuildContext context, TransactionData txData) {
  // No transactions in wallet
  if (txData.txChunks.length == 0) {
    return Center(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SizedBox(
          //   height: 32,
          // ),
          SvgPicture.asset(
            "assets/svg/empty-tx-list.svg",
            width: MediaQuery.of(context).size.width * 0.52,
          ),
          SizedBox(
            height: 8,
          ),
          FittedBox(
            child: Text(
              "NO TRANSACTIONS YET",
              style: GoogleFonts.workSans(
                color: CFColors.dew,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 0.25,
              ),
            ),
          )
        ],
      ),
    );
  } else {
    // flatten transactions into single list
    List<Transaction> txList =
        txData.txChunks.expand((element) => element.transactions).toList();

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 0,
        horizontal: 16,
      ),
      child: ListView.builder(
        itemCount: txList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.all(
              SizingUtilities.listItemSpacing / 2,
            ),
            child: TransactionCard(
              transaction: txList[index],
              txType: txList[index].txType,
              date: Utilities.extractDateFrom(txList[index].timestamp),
              amount:
                  "${Utilities.satoshisToAmount(txList[index].amount)} ${CurrencyUtilities.coinName}",
              fiatValue: txList[index].worthNow is String
                  ? txList[index].worthNow
                  : txList[index].worthNow.toStringAsFixed(2),
            ),
          );
        },
      ),
    );
  }
}
