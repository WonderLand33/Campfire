import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/models/models.dart';
import 'package:paymint/pages/wallet_view/confirm_send_view.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/services/utils/currency_utils.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/gradient_card.dart';
import 'package:provider/provider.dart';

class SendView extends StatefulWidget {
  SendView({Key key}) : super(key: key);

  @override
  _SendViewState createState() => _SendViewState();
}

class _SendViewState extends State<SendView> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController _recipientAddressTextController = TextEditingController();

  TextEditingController _noteTextController = TextEditingController();

  TextEditingController _firoAmountController = TextEditingController();
  TextEditingController _fiatAmountController = TextEditingController();

  double _firoAmount = 0;
  double _fee = 0;
  double _totalAmount = 0;

  bool _cryptoAmountHasFocus = false;
  bool _fiatAmountHasFocus = false;

  bool get _amountHasFocus => _cryptoAmountHasFocus || _fiatAmountHasFocus;

  Widget _buildTxFeeInfo() {
    return Column(
      children: [
        // Transaction fee
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FittedBox(
              child: Text(
                "Transaction fee",
                style: GoogleFonts.workSans(
                  color: CFColors.twilight,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                "${_fee.toStringAsFixed(8)} ${CurrencyUtilities.coinName}",
                style: GoogleFonts.workSans(
                  color: CFColors.twilight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 16,
        ),

        // Total amount to send
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FittedBox(
              child: Text(
                "Total amount to send",
                style: GoogleFonts.workSans(
                  color: CFColors.twilight,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            FittedBox(
              child: Text(
                "${_totalAmount.toStringAsFixed(8)} ${CurrencyUtilities.coinName}",
                style: GoogleFonts.workSans(
                  color: CFColors.twilight,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountInputBox(dynamic firoPrice) {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.fog,
        borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
        border: Border.all(
          width: 1,
          color: _amountHasFocus ? CFColors.focusedBorder : CFColors.twilight,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _cryptoAmountHasFocus = hasFocus;
                });
              },
              child: TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                controller: _firoAmountController,
                keyboardType:
                    TextInputType.numberWithOptions(signed: false, decimal: true),
                inputFormatters: [
                  // regex to validate a crypto amount with 8 decimal places
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      RegExp(r'^([0-9]*\.?[0-9]{0,8}|\.[0-9]{0,8})$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue),
                ],
                onChanged: (String firoAmount) {
                  if (firoAmount.isNotEmpty && firoPrice != 0 && firoAmount != ".") {
                    _firoAmount = double.parse(firoAmount);
                    setState(() {
                      _totalAmount = _firoAmount + _fee;
                    });

                    final String fiatAmountString =
                        (_firoAmount * firoPrice).toStringAsFixed(2);

                    _fiatAmountController.text = fiatAmountString;
                  } else {
                    setState(() {
                      _totalAmount = 0;
                    });
                    _fiatAmountController.text = "";
                  }
                },
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: 14,
                    bottom: 12,
                    right: 16,
                  ),
                  // ticker suffix
                  suffixIcon: UnconstrainedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        CurrencyUtilities.coinName,
                        style: TextStyle(
                          color: CFColors.twilight,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  hintText: "0.00",
                  hintStyle: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Container(
              height: 1,
              color: _amountHasFocus ? CFColors.focusedBorder : CFColors.twilight,
            ),
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _fiatAmountHasFocus = hasFocus;
                });
              },
              child: TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                controller: _fiatAmountController,
                keyboardType:
                    TextInputType.numberWithOptions(signed: false, decimal: true),
                inputFormatters: [
                  // regex to validate a fiat amount with 2 decimal places
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      RegExp(r'^([0-9]*\.?[0-9]{0,2}|\.[0-9]{0,2})$')
                              .hasMatch(newValue.text)
                          ? newValue
                          : oldValue),
                ],
                onChanged: (String fiatAmount) {
                  if (fiatAmount.isNotEmpty && fiatAmount != ".") {
                    final fiatValue = double.parse(fiatAmount);
                    _firoAmount = fiatValue / firoPrice;

                    final amountString = _firoAmount.toStringAsFixed(8);

                    setState(() {
                      _totalAmount = double.parse(amountString) + _fee;
                    });

                    _firoAmountController.text = amountString;
                  } else {
                    setState(() {
                      _totalAmount = 0;
                    });
                    _firoAmountController.text = "";
                  }
                },
                decoration: InputDecoration(
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: 14,
                    bottom: 12,
                    right: 16,
                  ),
                  suffixIcon: UnconstrainedBox(
                    child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FutureBuilder(
                          future: CurrencyUtilities.fetchPreferredCurrency(),
                          builder: (context, futureData) {
                            if (futureData.connectionState == ConnectionState.done) {
                              return Text(
                                futureData.data,
                                style: TextStyle(
                                  color: CFColors.twilight,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              );
                            }
                            return Text(
                              "...",
                              style: TextStyle(
                                color: CFColors.twilight,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            );
                          },
                        )),
                  ),
                  hintText: firoPrice == 0 ? "..." : "0.00",
                  hintStyle: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 16, // ScalingUtils.fontScaled(context, 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BitcoinService bitcoinService = Provider.of<BitcoinService>(context);

    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: CFColors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 8,
            left: 20,
            right: 20,
            bottom: 16,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GradientCard(
                gradient: CFColors.fireGradientVerticalLight,
                circularBorderRadius: SizingUtilities.circularBorderRadius,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FittedBox(
                        child: Text(
                          "You can spend: ",
                          style: GoogleFonts.workSans(
                            color: CFColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FutureBuilder(
                        future: bitcoinService.utxoData,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<UtxoData> utxoData,
                        ) {
                          if (utxoData.connectionState == ConnectionState.done) {
                            if (utxoData == null || utxoData.hasError) {
                              // TODO: Display failed overlay 'Unable to fetch balance data.\nPlease check connection'
                              return Text(
                                "... ${CurrencyUtilities.coinName}",
                                style: GoogleFonts.workSans(
                                  color: CFColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }

                            return FittedBox(
                              child: Text(
                                "${utxoData.data.bitcoinBalance.toString()} ${CurrencyUtilities.coinName}",
                                style: GoogleFonts.workSans(
                                  color: CFColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          } else {
                            //TODO: wallet balance loading progress
                            return SizedBox(
                              height: 20,
                              width: 100,
                              child: LinearProgressIndicator(
                                color: Colors.green,
                                backgroundColor: Colors.purple,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 17,
              ),

              // Send to
              Row(
                children: [
                  FittedBox(
                    child: Text(
                      "Send to",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                controller: _recipientAddressTextController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    top: 12,
                    bottom: 12,
                    right: 5,
                  ),
                  hintText: "Address",
                  suffixIcon: UnconstrainedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed("/addressbook").then(
                                (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  if (value is String) {
                                    _recipientAddressTextController.text = value;
                                  }
                                },
                              );
                              print("open addressbook icon clicked");
                            },
                            child: SvgPicture.asset(
                              "assets/svg/book-open.svg",
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              print("read qr code icon button tapped");
                            },
                            child: SvgPicture.asset(
                              "assets/svg/qr-code.svg",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),

              // Note
              Row(
                children: [
                  FittedBox(
                    child: Text(
                      "Note (optional)",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              TextField(
                style: GoogleFonts.workSans(
                  color: CFColors.dusk,
                ),
                controller: _noteTextController,
                decoration: InputDecoration(
                  fillColor: CFColors.fog,
                  border: OutlineInputBorder(),
                  hintText: "Type something...",
                  hintStyle: GoogleFonts.workSans(
                    color: CFColors.twilight,
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),

              // Amount
              Row(
                children: [
                  FittedBox(
                    child: Text(
                      "Amount",
                      style: GoogleFonts.workSans(
                        color: CFColors.twilight,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              FutureBuilder(
                future: bitcoinService.bitcoinPrice,
                builder: (context, price) {
                  if (price.connectionState == ConnectionState.done) {
                    if (price.hasError || price.data == null) {
                      // TODO: show proper connection error
                      print("Couldn't fetch price, please check connection");
                      return _buildAmountInputBox(0);
                    }
                    return _buildAmountInputBox(price.data);
                  }

                  print("Fetching price... please wait...");
                  return _buildAmountInputBox(0);
                },
              ),
              SizedBox(
                height: 16,
              ),

              FutureBuilder(
                future: bitcoinService.fees,
                builder: (BuildContext context, AsyncSnapshot<FeeObject> feeObject) {
                  if (feeObject.connectionState == ConnectionState.done) {
                    if (feeObject == null || feeObject.hasError) {
                      // TODO: connection error notification
                      return _buildTxFeeInfo();
                    }

                    // TODO is this the correct fee?
                    _fee = feeObject.data.medium;

                    return _buildTxFeeInfo();
                  } else {
                    return _buildTxFeeInfo();
                  }
                },
              ),

              SizedBox(
                height: 16,
              ),

              // Send Button
              SizedBox(
                height: 48,
                width: MediaQuery.of(context).size.width - 40,
                child: GradientButton(
                  onTap: () {
                    print("SEND pressed");

                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (
                          context,
                          widget,
                          animation,
                        ) {
                          return ConfirmSendView(
                            amount: _firoAmount,
                            note: _noteTextController.text,
                            address: _recipientAddressTextController.text,
                            fee: _fee,
                          );
                        },
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          // const begin = Offset(0.0, 1.0);
                          // const end = Offset.zero;
                          // const curve = Curves.ease;

                          // var tween = Tween(begin: begin, end: end)
                          //     .chain(CurveTween(curve: curve));

                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                  child: Text(
                    "SEND",
                    style: GoogleFonts.workSans(
                      color: CFColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}