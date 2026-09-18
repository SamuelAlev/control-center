import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/work_product_service.dart';
import 'package:cc_mcp/src/tools/governance_work_product_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeWorkProducts products;
  late CreateWorkProductTool tool;

  setUp(() {
    products = _FakeWorkProducts();
    tool = CreateWorkProductTool(
      service: WorkProductService(repository: products),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'title': 'Launch plan'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('creates a work product with a title', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'title': 'Launch plan',
    });
    expect(result.isError, isFalse);
    expect(products.store, hasLength(1));
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['title'], 'Launch plan');
  });
}

class _FakeWorkProducts implements WorkProductRepository {
  final Map<String, WorkProduct> store = {};

  @override
  Future<void> upsert(WorkProduct workProduct) async =>
      store[workProduct.id] = workProduct;

  @override
  Future<WorkProduct?> getById(String workspaceId, String id) async {
    final product = store[id];
    return product?.workspaceId == workspaceId ? product : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
