import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Signature of a Supabase RPC call. Production uses the Supabase client;
/// tests pass a fake.
typedef RpcCaller = Future<dynamic> Function(String function, Map<String, dynamic> params);

enum ParentDataErrorKind {
  /// Not signed in, or the child is not (or no longer) linked to this account.
  notAuthorized,

  /// The database function is missing: 08_parents_app_integration.sql is not deployed.
  notDeployed,

  /// No connection / timeout.
  network,

  /// Any other database error.
  server,
}

/// A failed read or write. [message] is safe to show to a parent; raw
/// database text is never put into it.
class ParentDataException implements Exception {
  final ParentDataErrorKind kind;
  final String message;
  final String? code;

  const ParentDataException(this.kind, this.message, {this.code});

  @override
  String toString() => 'ParentDataException($kind, $code): $message';
}

/// Single gateway from the Parents App to the School OS database.
///
/// Every parent read goes through a SECURITY DEFINER RPC that verifies the
/// signed-in parent's link to the child on the server (see
/// `database_repair/08_parents_app_integration.sql` in the School OS repo).
/// The app never filters another family's data on the device.
class ParentApi {
  ParentApi(this._call);

  final RpcCaller _call;

  static ParentApi? _instance;

  /// Replace in tests: `ParentApi.instance = ParentApi(fakeCaller);`
  static set instance(ParentApi value) => _instance = value;

  static ParentApi get instance => _instance ??= ParentApi(_supabaseRpc);

  static Future<dynamic> _supabaseRpc(String fn, Map<String, dynamic> params) {
    if (!SupabaseService.isInitialized) {
      throw const ParentDataException(
        ParentDataErrorKind.network,
        'The app could not connect to the school server. Please check your connection and restart the app.',
      );
    }
    return SupabaseService.client.rpc(fn, params: params);
  }

  static const Duration timeout = Duration(seconds: 20);

  Future<dynamic> rpc(String function, [Map<String, dynamic> params = const {}]) async {
    try {
      return await _call(function, params).timeout(timeout);
    } on PostgrestException catch (e) {
      if (kDebugMode) debugPrint('[ParentApi] $function failed: ${e.code}');
      throw mapPostgrestError(e);
    } on TimeoutException {
      throw const ParentDataException(ParentDataErrorKind.network,
          'The school server did not respond in time. Please try again.');
    } on SocketException {
      throw const ParentDataException(ParentDataErrorKind.network,
          'No internet connection. Please check your connection and try again.');
    } on ParentDataException {
      rethrow;
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('socket') || text.contains('failed host lookup') || text.contains('clientexception') ||
          text.contains('connection')) {
        throw const ParentDataException(ParentDataErrorKind.network,
            'No internet connection. Please check your connection and try again.');
      }
      if (kDebugMode) debugPrint('[ParentApi] $function unexpected error: $e');
      throw const ParentDataException(ParentDataErrorKind.server,
          'Something went wrong while loading data from the school. Please try again.');
    }
  }

  /// RPC result as a JSON object; anything else is a server error.
  Future<Map<String, dynamic>> rpcObject(String function, [Map<String, dynamic> params = const {}]) async {
    final res = await rpc(function, params);
    if (res is Map) return Map<String, dynamic>.from(res);
    throw const ParentDataException(ParentDataErrorKind.server,
        'The school server returned an unexpected response. Please try again.');
  }

  /// RPC result as a list of JSON objects. `null` from the server is an empty list.
  Future<List<Map<String, dynamic>>> rpcList(String function, [Map<String, dynamic> params = const {}]) async {
    final res = await rpc(function, params);
    if (res == null) return const [];
    if (res is List) {
      return res.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    throw const ParentDataException(ParentDataErrorKind.server,
        'The school server returned an unexpected response. Please try again.');
  }
}

ParentDataException mapPostgrestError(PostgrestException e) {
  final code = e.code ?? '';
  if (code == '42501' || code == 'PGRST301' || code == '401') {
    return ParentDataException(ParentDataErrorKind.notAuthorized,
        'You do not have access to this information. The child may no longer be linked to your account.',
        code: code);
  }
  if (code == 'PGRST202' || code == '42883' || code == 'PGRST205' || code == '42P01') {
    return ParentDataException(ParentDataErrorKind.notDeployed,
        'This feature is not yet enabled on your school\'s server. Please contact the school office.',
        code: code);
  }
  if (code == 'P0002') {
    return ParentDataException(ParentDataErrorKind.server, 'The requested record was not found.', code: code);
  }
  return ParentDataException(ParentDataErrorKind.server,
      'The school server could not complete the request. Please try again.',
      code: code);
}

/// User-facing text for any error caught in the app.
String parentErrorMessage(Object error) {
  if (error is ParentDataException) return error.message;
  return 'Something went wrong. Please try again.';
}
