import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

ModelInfo _model(
  String id, {
  required int context,
  String? promotionTarget,
  String provider = 'anthropic',
}) => ModelInfo(
  id: id,
  providerId: provider,
  name: id,
  limits: ModelLimits(context: context),
  contextPromotionTarget: promotionTarget,
);

ModelCatalog _catalog(List<ModelInfo> models) {
  // Build a catalog directly from ModelInfo objects (bypassing models.dev).
  final byProvider = <String, Map<String, ModelInfo>>{};
  for (final m in models) {
    byProvider.putIfAbsent(m.providerId, () => {})[m.id] = m;
  }
  return ModelCatalog({
    for (final e in byProvider.entries)
      e.key: ProviderEntry(
        provider: ModelProvider(
          id: e.key,
          name: e.key,
          enablement: const ProviderEnabledViaEnv('K'),
        ),
        models: e.value,
      ),
  });
}

void main() {
  const promoter = ContextPromoter();

  test('no promotion below the pressure threshold', () {
    final sonnet = _model('sonnet', context: 200000);
    final decision = promoter.decide(sonnet, 100000, _catalog([sonnet]));
    expect(decision.shouldPromote, isFalse);
    expect(decision.pressure, closeTo(0.5, 0.001));
  });

  test('follows the declared promotion target when context fills', () {
    final sonnet = _model(
      'sonnet',
      context: 200000,
      promotionTarget: 'anthropic/opus-1m',
    );
    final opus = _model('opus-1m', context: 1000000);
    final catalog = _catalog([sonnet, opus]);
    final decision = promoter.decide(sonnet, 190000, catalog);
    expect(decision.shouldPromote, isTrue);
    expect(decision.target!.id, 'opus-1m');
    expect(decision.reason, contains('opus-1m'));
  });

  test('falls back to the smallest larger-window same-provider model', () {
    final small = _model('small', context: 200000); // no declared target
    final mid = _model('mid', context: 500000);
    final big = _model('big', context: 1000000);
    final catalog = _catalog([small, mid, big]);
    final decision = promoter.decide(small, 195000, catalog);
    expect(decision.shouldPromote, isTrue);
    // Smallest window that still relieves pressure.
    expect(decision.target!.id, 'mid');
  });

  test('no promotion when no larger model exists', () {
    final only = _model('only', context: 200000);
    final decision = promoter.decide(only, 195000, _catalog([only]));
    expect(decision.shouldPromote, isFalse);
  });

  test('unknown context window cannot promote', () {
    const m = ModelInfo(id: 'm', providerId: 'p', name: 'm');
    final decision = promoter.decide(m, 999999, _catalog([m]));
    expect(decision.shouldPromote, isFalse);
    expect(decision.pressure, 0);
  });
}
