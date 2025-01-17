import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:paymint/utilities/logger.dart';

import 'electrumx.dart';

class CachedElectrumX {
  ElectrumX _client;
  String _hivePath;
  static const minCacheConfirms = 30;

  CachedElectrumX({String server, int port, bool useSSL, String hivePath}) {
    _hivePath = hivePath;
    _client = ElectrumX(server: server, port: port, useSSL: useSSL);
  }

  factory CachedElectrumX.from(
          {@required ElectrumXNode node, String hivePath}) =>
      CachedElectrumX(
          server: node.address,
          port: node.port,
          useSSL: node.useSSL,
          hivePath: hivePath);

  Future<Map<String, dynamic>> getAnonymitySet(
      {@required String groupId,
      @required String coinName,
      @required bool callOutSideMainIsolate}) async {
    try {
      // hive must be initialized when this function is called outside of flutter main
      // such as within an isolate
      if (callOutSideMainIsolate) {
        Hive.init(_hivePath);
      }
      final box = await Hive.openBox('${coinName}_anonymitySetCache');
      final cachedSet = await box.get(groupId);

      Map<String, dynamic> set;

      // null check to see if there is a cached set
      if (cachedSet == null) {
        set = {
          "setId": groupId,
          "blockHash": "",
          "setHash": "",
          "serializedCoins": <String>[],
        };
      } else {
        set = Map<String, dynamic>.from(cachedSet);
      }

      final newSet = await _client.getAnonymitySet(
        groupId: groupId,
        blockhash: set["blockHash"],
      );

      // update set with new data
      if (newSet["setHash"] != "" && set["setHash"] != newSet["setHash"]) {
        set["setHash"] = newSet["setHash"];
        set["blockHash"] = newSet["blockHash"];
        for (int i = newSet["serializedCoins"].length - 1; i >= 0; i--) {
          set["serializedCoins"].insert(0, newSet["serializedCoins"][i]);
        }
        // save set to db
        await box.put(groupId, set);
        Logger.print(
            "Updated currently anonymity set for $coinName with group ID $groupId");
      }

      return set;
    } catch (e) {
      Logger.print("Failed to process CachedElectrumX.getAnonymitySet(): $e");
      throw e;
    }
  }

  /// Call electrumx getTransaction on a per coin basis, storing the result in local db if not already there.
  ///
  /// ElectrumX api only called if the tx does not exist in local db
  Future<Map<String, dynamic>> getTransaction(
      {@required String tx_hash,
      bool verbose: true,
      @required String coinName,
      @required bool callOutSideMainIsolate}) async {
    if (coinName == null || coinName.isEmpty) {
      throw Exception("Invalid argument: coinName cannot be empty!");
    }

    try {
      // hive must be initialized when this function is called outside of flutter main
      // such as within an isolate
      if (callOutSideMainIsolate) {
        Hive.init(_hivePath);
      }
      final txCache = await Hive.openBox('${coinName}_txCache');
      final cachedTx = await txCache.get(tx_hash);
      if (cachedTx == null) {
        final Map<String, dynamic> result =
            await _client.getTransaction(tx_hash: tx_hash, verbose: verbose);

        result.remove("hex");
        result.remove("lelantusData");

        if (result["confirmations"] != null &&
            result["confirmations"] > minCacheConfirms) {
          await txCache.put(tx_hash, result);
        }

        Logger.print("using fetched result");
        return result;
      } else {
        Logger.print("using cached result");
        return Map<String, dynamic>.from(cachedTx);
      }
    } catch (e) {
      Logger.print("Failed to process CachedElectrumX.getTransaction(): $e");
      throw e;
    }
  }

  /// Clear all cached transactions for the specified coin
  Future<bool> clearSharedTransactionCache({String coinName}) async {
    try {
      await Hive.deleteBoxFromDisk('${coinName}_txCache');
      await Hive.deleteBoxFromDisk('${coinName}_anonymitySetCache');
      return true;
    } catch (e) {
      print("Clear transaction cache for coin $coinName failed.");
      return false;
    }
  }
}
