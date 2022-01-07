import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:paymint/notifications/overlay_notification.dart';
import 'package:paymint/pages/onboarding_view/helpers/builders.dart';
import 'package:paymint/services/bitcoin_service.dart';
import 'package:paymint/utilities/cfcolors.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:paymint/utilities/sizing_utilities.dart';
import 'package:paymint/utilities/text_styles.dart';
import 'package:paymint/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:paymint/widgets/custom_buttons/gradient_button.dart';
import 'package:paymint/widgets/custom_buttons/simple_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class WalletBackUpView extends StatelessWidget {
  const WalletBackUpView({Key key}) : super(key: key);

  Future<List<String>> _getMnemonic(BuildContext context) async {
    final bitcoinService = Provider.of<BitcoinService>(context, listen: false);
    final _currentWallet = await bitcoinService.currentWalletName;
    final secureStore = new FlutterSecureStorage();
    final mnemonicString = await secureStore.read(key: '${_currentWallet}_mnemonic');
    final List<String> data = mnemonicString.split(' ');
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.white,
      appBar: AppBar(
        backgroundColor: CFColors.white,
        title: Text(
          "Backup Key",
          style: GoogleFonts.workSans(
            color: CFColors.dusk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),

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
              onPressed: () async {
                Navigator.pop(context);
              },
              circularBorderRadius: 8,
              icon: SvgPicture.asset(
                "assets/svg/chevronLeft.svg",
                color: CFColors.twilight,
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(
          top: 10,
          left: SizingUtilities.standardPadding,
          right: SizingUtilities.standardPadding,
          bottom: SizingUtilities.standardPadding,
        ),
        child: Column(
          children: [
            _buildWarningMessage(),
            SizedBox(
              height: 32,
            ),
            _buildMnemonicView(context),
            Spacer(),
            _buildButtons(context),
          ],
        ),
      ),
    );
  }

  _buildWarningMessage() {
    return Container(
      decoration: BoxDecoration(
        color: CFColors.mist,
        border: Border.all(
          color: CFColors.smoke,
        ),
        borderRadius: BorderRadius.circular(SizingUtilities.circularBorderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: SizingUtilities.standardPadding,
          vertical: 16,
        ),
        child: Text(
          "Please write down your backup key. Keep it safe and never share it with anyone." +
              " Your backup key is the only way you can access your funds if you forget PIN, " +
              "lose your phone, etc.\n\nCampfire Wallet does not keep nor is able to" +
              " restore your backup key. Only you have access to your wallet.",
          style: GoogleFonts.workSans(
            color: CFColors.dusk,
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  _buildMnemonicView(BuildContext context) {
    return FutureBuilder(
      future: _getMnemonic(context),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return _buildMnemonicTable(snapshot.data);
        } else {
          return Center(
              child: SpinKitThreeBounce(
            color: CFColors.spark,
            size: MediaQuery.of(context).size.width * 0.1,
          ));
        }
      },
    );
  }

  _buildMnemonicTable(List<String> words) {
    final int wordsCount = 12;
    List<TableRow> rows = [];

    for (int i = 0; i < wordsCount / 2; i++) {
      final row = TableRow(
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Material(
              color: CFColors.fog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
                side: BorderSide(
                  width: 1,
                  color: CFColors.dew,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Material(
                        color: CFColors.dew,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                            bottomLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                          ),
                          side: BorderSide(
                            width: 1,
                            color: CFColors.dew,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              "${i + 1}",
                              style: GoogleFonts.workSans(
                                color: CFColors.starryNight,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "${words[i]}",
                          style: GoogleFonts.workSans(
                            color: CFColors.starryNight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TableCell(
            child: SizedBox(
              width: 20,
            ),
          ),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Material(
              color: CFColors.fog,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SizingUtilities.checkboxBorderRadius),
                side: BorderSide(
                  width: 1,
                  color: CFColors.dew,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Material(
                        color: CFColors.dew,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                            bottomLeft:
                                Radius.circular(SizingUtilities.checkboxBorderRadius),
                          ),
                          side: BorderSide(
                            width: 1,
                            color: CFColors.dew,
                          ),
                        ),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              "${i + (wordsCount ~/ 2) + 1}",
                              style: GoogleFonts.workSans(
                                color: CFColors.starryNight,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          "${words[i + wordsCount ~/ 2]}",
                          style: GoogleFonts.workSans(
                            color: CFColors.starryNight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      rows.add(row);

      // add space between each row hack
      if (i < (wordsCount / 2) - 1) {
        final spacerRow = TableRow(
          children: [
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 10,
            ),
          ],
        );
        rows.add(spacerRow);
      }
    }

    return SingleChildScrollView(
      child: Table(
        columnWidths: {
          0: FlexColumnWidth(),
          1: IntrinsicColumnWidth(),
          2: FlexColumnWidth(),
        },
        children: rows,
      ),
    );
  }

  _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: SimpleButton(
              onTap: () => _onQrcodeButtonPressed(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svg/qr-code.svg",
                    color: CFColors.dusk,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  FittedBox(
                    child: Text(
                      "QR CODE",
                      style: GoogleFonts.workSans(
                        color: CFColors.dusk,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: 16,
        ),
        Expanded(
          child: SizedBox(
            height: 48,
            child: SimpleButton(
              onTap: () => _onCopyButtonPressed(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    "assets/svg/copy.svg",
                    color: CFColors.dusk,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "COPY",
                    style: GoogleFonts.workSans(
                      color: CFColors.dusk,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  _onQrcodeButtonPressed(BuildContext context) {
    final _qrSize = MediaQuery.of(context).size.width * 0.42;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (context) {
        return buildModalDialog(
          context,
          Column(
            children: [
              SizedBox(
                height: 28,
              ),
              FittedBox(
                child: Text(
                  "Backup Key QR Code",
                  style: CFTextStyles.pinkHeader.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                height: _qrSize * 1.1,
                width: _qrSize * 1.1,
                color: CFColors.white,
                child: Material(
                  color: CFColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(SizingUtilities.circularBorderRadius),
                    side: BorderSide(
                      color: CFColors.smoke,
                      width: 1,
                    ),
                  ),
                  child: FutureBuilder(
                    future: _getMnemonic(context),
                    builder:
                        (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return Center(
                          child: PrettyQr(
                            data: snapshot.data.join(' '),
                            roundEdges: Constants.roundedQrCode,
                            elementColor: CFColors.midnight,
                            typeNumber: 5,
                            size: _qrSize,
                          ),
                        );
                      } else {
                        return Container(
                          height: _qrSize,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  // crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: SimpleButton(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: FittedBox(
                            child: Text(
                              "CANCEL",
                              style: GoogleFonts.workSans(
                                color: CFColors.dusk,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 16,
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: GradientButton(
                          onTap: () {
                            //TODO: implement save
                            print("SAVE mnemonic key pressed");
                          },
                          child: FittedBox(
                            child: Text(
                              "SAVE",
                              style: GoogleFonts.workSans(
                                color: CFColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _onCopyButtonPressed(BuildContext context) async {
    final mnemonic = await _getMnemonic(context);
    Clipboard.setData(
      ClipboardData(
        text: mnemonic.join(" "),
      ),
    );
    OverlayNotification.showInfo(
      context,
      "Copied to clipboard",
      Duration(seconds: 2),
    );
  }
}