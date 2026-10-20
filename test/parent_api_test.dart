import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:parent_app/core/services/parent_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ParentApi error mapping (no raw database text reaches the UI)', () {
    Future<ParentDataException> failWith(Object error) async {
      final api = ParentApi((_, __) async => throw error);
      try {
        await api.rpc('parent_get_fees', {'p_student_id': 'x'});
      } on ParentDataException catch (e) {
        return e;
      }
      fail('expected ParentDataException');
    }

    test('42501 -> notAuthorized', () async {
      final e = await failWith(const PostgrestException(message: 'RAW-DB-TEXT-42501', code: '42501'));
      expect(e.kind, ParentDataErrorKind.notAuthorized);
      expect(e.message, isNot(contains('RAW-DB-TEXT')));
    });

    test('missing function (08 not deployed) -> notDeployed', () async {
      final e = await failWith(const PostgrestException(message: 'Could not find the function', code: 'PGRST202'));
      expect(e.kind, ParentDataErrorKind.notDeployed);
    });

    test('other database error -> server, raw message hidden', () async {
      final e = await failWith(const PostgrestException(message: 'column "secret_col" does not exist', code: '42703'));
      expect(e.kind, ParentDataErrorKind.server);
      expect(e.message, isNot(contains('secret_col')));
    });

    test('timeout -> network', () async {
      final e = await failWith(TimeoutException('slow'));
      expect(e.kind, ParentDataErrorKind.network);
    });

    test('rpcList: null is an empty list, a non-list is an error', () async {
      expect(await ParentApi((_, __) async => null).rpcList('f'), isEmpty);
      expect(
        () => ParentApi((_, __) async => {'not': 'a list'}).rpcList('f'),
        throwsA(isA<ParentDataException>()),
      );
    });

    test('rpcObject: a non-object is an error', () async {
      expect(() => ParentApi((_, __) async => [1, 2]).rpcObject('f'), throwsA(isA<ParentDataException>()));
    });
  });
}
