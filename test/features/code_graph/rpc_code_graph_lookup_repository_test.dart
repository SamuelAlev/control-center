import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/code_symbol_kind.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_rpc_client.dart';

void main() {
  test('decodes codeGraph.symbolLookup into lookup candidates', () async {
    final host = FakeRpcHost()
      ..onCall = (op, args) {
        expect(op, 'codeGraph.symbolLookup');
        expect(args['workspace_id'], 'ws');
        expect(args['repo_id'], 'repo');
        expect(args['name'], 'Animal');
        expect(args['space_id'], 'space-1');
        return {
          'from_base': true,
          'definitions': [
            {
              'id': 'cls-1',
              'name': 'Animal',
              'qualified_name': 'animals.Animal',
              'kind': 'classKind',
              'file_path': 'lib/animal.dart',
              'start_line': 12,
              'end_line': 40,
              'parent_name': 'pkg',
              'signature': 'class Animal',
              'caller_count': 3,
              'implementors': [
                {
                  'id': 'cls-2',
                  'name': 'Dog',
                  'qualified_name': 'animals.Dog',
                  'kind': 'classKind',
                  'file_path': 'lib/dog.dart',
                  'start_line': 4,
                  'end_line': 10,
                },
              ],
            },
          ],
        };
      };
    final repo = RpcCodeGraphLookupRepository(host.client());
    final result = await repo.lookup(
      workspaceId: 'ws',
      repoId: 'repo',
      name: 'Animal',
      spaceId: 'space-1',
    );
    expect(result.fromBasePartition, isTrue);
    expect(result.definitions, hasLength(1));
    final def = result.definitions.single;
    expect(def.name, 'Animal');
    expect(def.kind, CodeSymbolKind.classKind);
    expect(def.callerCount, 3);
    expect(def.filePath, 'lib/animal.dart');
    expect(def.startLine, 12);
    expect(def.implementors, hasLength(1));
    expect(def.implementors.single.name, 'Dog');
    expect(def.implementors.single.implementors, isEmpty);
  });
}
