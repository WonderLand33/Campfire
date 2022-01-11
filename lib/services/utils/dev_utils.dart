import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../wallets_service.dart';

class DevUtilities {
  static debugPrintWalletState() async {
    final _currentWallet = await WalletsService().currentWalletName;
    final wallets = await Hive.openBox('wallets');
    final names = await wallets.get('names');
    final id = names[_currentWallet];
    final wallet = await Hive.openBox(id);
    final ra = wallet.get('receivingAddresses');
    final ca = wallet.get('changeAddresses');
    final ri = wallet.get('receivingIndex');
    final ci = wallet.get('changeIndex');

    final secureStore = new FlutterSecureStorage();
    final mnemonic = await secureStore.read(key: '${id}_mnemonic');

    print("""
    ===========================================================================
    Current (external) receiving index, array: $ri, $ra\n
    Current (internal) change index, array: $ci, $ca\n
    ===========================================================================
    BIP39 seed phrase: $mnemonic
    """);
  }

  static checkReceivingAndChangeArrays() async {
    final wallet = await Hive.openBox('wallet');
    final ra = wallet.get('receivingAddresses');
    final ca = wallet.get('changeAddresses');
    final ri = wallet.get('receivingIndex');
    final ci = wallet.get('changeIndex');

    print("$ri Receiving Addresses:\n");
    for (var i = 0; i < ra.length; i++) {
      print(i.toString() + ra[i].toString());
    }
    print('\n\n');
    print("$ci Change Addresses:\n");
    for (var i = 0; i < ca.length; i++) {
      print(i.toString() + ca[i].toString());
    }
    print('\n\n');
  }
}
