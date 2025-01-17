import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:paymint/electrumx_rpc/rpc.dart';
import 'package:paymint/utilities/logger.dart';
import 'package:paymint/utilities/misc_global_constants.dart';
import 'package:uuid/uuid.dart';

class ElectrumXNode {
  ElectrumXNode({this.address, this.port, this.name, this.id, this.useSSL});
  final String address;
  final int port;
  final String name;
  final String id;
  final bool useSSL;

  factory ElectrumXNode.from(ElectrumXNode node) {
    return ElectrumXNode(
      address: node.address,
      port: node.port,
      name: node.name,
      id: node.id,
      useSSL: node.useSSL,
    );
  }
}

class ElectrumX {
  String get server => _server;
  String _server;

  int get port => _port;
  int _port;

  bool get useSSL => _useSSL;
  bool _useSSL;

  ElectrumX(
      {@required String server, @required int port, @required bool useSSL}) {
    _server = server;
    _port = port;
    _useSSL = useSSL;
  }

  factory ElectrumX.from({@required ElectrumXNode node}) =>
      ElectrumX(server: node.address, port: node.port, useSSL: node.useSSL);

  /// Send raw rpc command
  Future<dynamic> request({
    String command,
    List<dynamic> args = const [],
    Duration connectionTimeout = const Duration(seconds: 5),
    Duration aliveTimerDuration = const Duration(seconds: 2),
  }) async {
    final address = CampfireConstants.allowTestnets
        ? CampfireConstants.defaultIpAddressTestNet
        : CampfireConstants.defaultIpAddress;
    final port = CampfireConstants.allowTestnets
        ? CampfireConstants.defaultPortTestNet
        : CampfireConstants.defaultPort;
    final client = JsonRPC(
      address: this.server ?? address,
      port: this.port ?? port,
      useSSL: this.useSSL ?? CampfireConstants.defaultUseSSL,
      connectionTimeout: connectionTimeout,
      aliveTimerDuration: aliveTimerDuration,
    );
    try {
      final requestId = Uuid().v1();
      final jsonArgs = json.encode(args);
      final jsonRequestString =
          '{"jsonrpc": "2.0", "id": "$requestId","method": "$command","params": $jsonArgs}';

      print("jsonRequestString: $jsonRequestString");

      final response = await client.request(jsonRequestString);

      if (response["result"] == null) {
        throw Exception("JSONRPC response error: $response");
      }

      return response;
    } catch (e) {
      throw e;
    }
  }

  /// Get most recent block header.
  ///
  /// Returns a map with keys 'height' and 'hex' corresponding to the block height
  /// and the binary header as a hexadecimal string.
  /// Ex:
  /// {
  //   "height": 520481,
  //   "hex": "00000020890208a0ae3a3892aa047c5468725846577cfcd9b512b50000000000000000005dc2b02f2d297a9064ee103036c14d678f9afc7e3d9409cf53fd58b82e938e8ecbeca05a2d2103188ce804c4"
  // }
  Future<Map<String, dynamic>> getBlockHeadTip() async {
    try {
      final response = await request(
        command: 'blockchain.headers.subscribe',
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  /// Get most recent block header.
  ///
  /// Returns a map with keys 'height' and 'hex' corresponding to the block height
  /// and the binary header as a hexadecimal string.
  /// Ex:
  // {
  // "genesis_hash": "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943",
  // "hosts": {"14.3.140.101": {"tcp_port": 51001, "ssl_port": 51002}},
  // "protocol_max": "1.0",
  // "protocol_min": "1.0",
  // "pruning": null,
  // "server_version": "ElectrumX 1.0.17",
  // "hash_function": "sha256"
  // }
  Future<Map<String, dynamic>> getServerFeatures() async {
    try {
      final response = await request(
        command: 'server.features',
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  /// Broadcast a transaction to the network.
  ///
  /// The transaction hash as a hexadecimal string.
  Future<String> broadcastTransaction({String rawTx}) async {
    try {
      final response = await request(
        command: 'blockchain.transaction.broadcast',
        args: [
          rawTx,
        ],
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  /// Return the confirmed and unconfirmed balances for the scripthash of a given scripthash
  ///
  /// Returns a map with keys confirmed and unconfirmed. The value of each is
  /// the appropriate balance in minimum coin units (satoshis).
  /// Ex:
  /// {
  ///   "confirmed": 103873966,
  ///   "unconfirmed": 23684400
  /// }
  Future<Map<String, dynamic>> getBalance({String scripthash}) async {
    try {
      final response = await request(
        command: 'blockchain.scripthash.get_balance',
        args: [
          scripthash,
        ],
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  /// Return the confirmed and unconfirmed history for the given scripthash.
  ///
  /// Returns a list of maps that contain the tx_hash and height of the tx.
  /// Ex:
  /// [
  //   {
  //     "height": 200004,
  //     "tx_hash": "acc3758bd2a26f869fcc67d48ff30b96464d476bca82c1cd6656e7d506816412"
  //   },
  //   {
  //     "height": 215008,
  //     "tx_hash": "f3e1bf48975b8d6060a9de8884296abb80be618dc00ae3cb2f6cee3085e09403"
  //   }
  // ]
  Future<List<Map<String, dynamic>>> getHistory({String scripthash}) async {
    try {
      final response = await request(
        command: 'blockchain.scripthash.get_history',
        args: [
          scripthash,
        ],
      );
      return List<Map<String, dynamic>>.from(response["result"]);
    } catch (e) {
      throw e;
    }
  }

  /// Return an ordered list of UTXOs sent to a script hash of the given scripthash.
  ///
  /// Returns a list of maps.
  /// Ex:
  /// [
  //   {
  //     "tx_pos": 0,
  //     "value": 45318048,
  //     "tx_hash": "9f2c45a12db0144909b5db269415f7319179105982ac70ed80d76ea79d923ebf",
  //     "height": 437146
  //   },
  //   {
  //     "tx_pos": 0,
  //     "value": 919195,
  //     "tx_hash": "3d2290c93436a3e964cfc2f0950174d8847b1fbe3946432c4784e168da0f019f",
  //     "height": 441696
  //   }
  // ]
  Future<List<Map<String, dynamic>>> getUTXOs({String scripthash}) async {
    try {
      final response = await request(
        command: 'blockchain.scripthash.listunspent',
        args: [
          scripthash,
        ],
      );
      return List<Map<String, dynamic>>.from(response["result"]);
    } catch (e) {
      throw e;
    }
  }

  /// Returns a raw transaction given the tx_hash.
  ///
  /// Returns a list of maps.
  /// Ex when verbose=false:
  /// "01000000015bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b48"
  /// "4000000006a4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a824"
  /// "6a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee76921"
  /// "3ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1"
  /// "f6a4feffffff02c6b68200000000001976a9141041fb024bd7a1338ef1959026bbba86006"
  /// "4fe5f88ac50a8cf00000000001976a91445dac110239a7a3814535c15858b939211f85298"
  /// "88ac61ee0700"
  ///
  ///
  /// Ex when verbose=true:
  /// {
  ///   "blockhash": "0000000000000000015a4f37ece911e5e3549f988e855548ce7494a0a08b2ad6",
  ///   "blocktime": 1520074861,
  ///   "confirmations": 679,
  ///   "hash": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
  ///   "hex": "01000000015bb9142c960a838329694d3fe9ba08c2a6421c5158d8f7044cb7c48006c1b484000000006a4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4feffffff02c6b68200000000001976a9141041fb024bd7a1338ef1959026bbba860064fe5f88ac50a8cf00000000001976a91445dac110239a7a3814535c15858b939211f8529888ac61ee0700",
  ///   "locktime": 519777,
  ///   "size": 225,
  ///   "time": 1520074861,
  ///   "txid": "36a3692a41a8ac60b73f7f41ee23f5c917413e5b2fad9e44b34865bd0d601a3d",
  ///   "version": 1,
  ///   "vin": [ {
  ///     "scriptSig": {
  ///       "asm": "30440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b[ALL|FORKID] 03bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4",
  ///       "hex": "4730440220229ea5359a63c2b83a713fcc20d8c41b20d48fe639a639d2a8246a137f29d0fc02201de12de9c056912a4e581a62d12fb5f43ee6c08ed0238c32a1ee769213ca8b8b412103bcf9a004f1f7a9a8d8acce7b51c983233d107329ff7c4fb53e44c855dbe1f6a4"
  ///     },
  ///     "sequence": 4294967294,
  ///     "txid": "84b4c10680c4b74c04f7d858511c42a6c208bae93f4d692983830a962c14b95b",
  ///     "vout": 0}],
  ///   "vout": [ { "n": 0,
  ///              "scriptPubKey": { "addresses": [ "12UxrUZ6tyTLoR1rT1N4nuCgS9DDURTJgP"],
  ///                                "asm": "OP_DUP OP_HASH160 1041fb024bd7a1338ef1959026bbba860064fe5f OP_EQUALVERIFY OP_CHECKSIG",
  ///                                "hex": "76a9141041fb024bd7a1338ef1959026bbba860064fe5f88ac",
  ///                                "reqSigs": 1,
  ///                                "type": "pubkeyhash"},
  ///              "value": 0.0856647},
  ///            { "n": 1,
  ///              "scriptPubKey": { "addresses": [ "17NMgYPrguizvpJmB1Sz62ZHeeFydBYbZJ"],
  ///                                "asm": "OP_DUP OP_HASH160 45dac110239a7a3814535c15858b939211f85298 OP_EQUALVERIFY OP_CHECKSIG",
  ///                                "hex": "76a91445dac110239a7a3814535c15858b939211f8529888ac",
  ///                                "reqSigs": 1,
  ///                                "type": "pubkeyhash"},
  ///              "value": 0.1360904}]}
  Future<Map<String, dynamic>> getTransaction(
      {String tx_hash, bool verbose = true}) async {
    try {
      final response = await request(
        command: 'blockchain.transaction.get',
        args: [
          tx_hash,
          verbose,
        ],
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  /// Returns the whole anonymity set for denomination in the groupId.
  ///
  /// ex:
  ///  {
  ///     "blockHash": "37effb57352693f4efcb1710bf68e3a0d79ff6b8f1605529de3e0706d9ca21da",
  ///     "setHash": "aae1a64f19f5ccce1c242dfe331d8db2883a9508d998efa3def8a64844170fe4",
  ///     "serializedCoins": [
  ///         "1a0d9a5aa8ec83771ead4271d90b6bac2b99879a6233c4d7700eafcd312e5a020100",
  ///         "47c3a2c837fa67a10b6d32d1f92e42c19b6bb88fa65034f778307bfc0305f12d0000",
  ///         ...
  ///         "7a9e57560d4abc384a48bf850a12df94e83d33496bb456aad26e7317921845330000",
  ///         "a7a8ddf79fdaf6846c0c19eb00ba7a95713a1a62df91761cb74b122606385fb80000"
  ///      ]
  ///   }
  Future<Map<String, dynamic>> getAnonymitySet(
      {String groupId, String blockhash}) async {
    try {
      final response = await request(
        command: 'sigma.getanonymityset',
        args: [
          groupId ?? "1",
          blockhash ?? "",
        ],
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  //TODO add example to docs
  ///
  ///
  /// Returns the block height and groupId of pubcoin.
  Future<dynamic> getMintData({dynamic mints}) async {
    try {
      final response = await request(
        command: 'sigma.getmintmetadata',
        args: [
          mints,
        ],
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }

  //TODO add example to docs
  /// Returns the whole set of the used coin serials.
  Future<dynamic> getUsedCoinSerials() async {
    try {
      final response = await request(
        command: 'sigma.getusedcoinserials',
      );
      return response["result"];
    } catch (e) {
      Logger.print(e);
      throw e;
    }
  }

  /// Returns the latest set id
  ///
  /// ex: 1
  Future<int> getLatestCoinId() async {
    try {
      final response = await request(
        command: 'sigma.getlatestcoinid',
      );
      return response["result"];
    } catch (e) {
      Logger.print(e);
      throw e;
    }
  }

  //TODO add example to docs
  ///
  ///
  /// Returns getcoinsforrecovery
  Future<Map<String, dynamic>> getCoinsForRecovery({dynamic setId}) async {
    try {
      final response = await request(
        command: 'sigma.getcoinsforrecovery',
        args: [
          setId ?? 1,
        ],
      );
      return response["result"];
    } catch (e) {
      Logger.print(e);
      throw e;
    }
  }

  /// Get the current fee rate.
  ///
  /// Returns a map with the kay "rate" that corresponds to the free rate in satoshis
  /// Ex:
  /// {
  //   "rate": 1000,
  // }
  Future<Map<String, dynamic>> getFeeRate() async {
    try {
      final response = await request(
        command: 'blockchain.getfeerate',
      );
      return response["result"];
    } catch (e) {
      throw e;
    }
  }
}
