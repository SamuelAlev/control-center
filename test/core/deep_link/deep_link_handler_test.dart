import 'package:control_center/core/deep_link/deep_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// [DeepLinkHandler.resolve]: the app's only entry point from outside the app.
///
/// Everything it parses arrives as a string from the OS — a Slack button, a
/// browser, `open` on a terminal — so the contract is that parsing is total
/// (nothing throws) and that a shape it does not recognize resolves to nothing
/// rather than to a best guess.
void main() {
  group('workspace links', () {
    test('a space link names its workspace and space', () {
      final target = DeepLinkHandler.resolve(
        'control-center://workspaces/ws-1/spaces/chan-1',
      );

      expect(target, isA<SpaceDeepLink>());
      final space = target! as SpaceDeepLink;
      expect(space.workspaceId, 'ws-1');
      expect(space.spaceId, 'chan-1');
    });

    test('a ticket link names its workspace and ticket', () {
      final target = DeepLinkHandler.resolve(
        'control-center://workspaces/ws-1/tickets/ticket-9',
      );

      expect(target, isA<TicketDeepLink>());
      expect((target! as TicketDeepLink).ticketId, 'ticket-9');
    });

    test('the shape the server bounce page writes resolves', () {
      // The `/open/...` path is rewritten into this scheme verbatim, so the two
      // halves only agree if this exact string parses.
      const id = '7f1c8e0a-1b2c-4d5e-8f90-abcdef123456';
      expect(
        DeepLinkHandler.resolve('control-center://workspaces/$id/spaces/$id'),
        isA<SpaceDeepLink>(),
      );
    });

    test('an unknown kind, arity or id is not a link', () {
      for (final url in [
        'control-center://workspaces/ws-1/secrets/x',
        'control-center://workspaces/ws-1/spaces',
        'control-center://workspaces/ws-1/spaces/chan-1/extra',
        'control-center://workspaces//spaces/chan-1',
        'control-center://elsewhere/ws-1/spaces/chan-1',
        // A separator or a query smuggled into an id.
        'control-center://workspaces/ws-1/spaces/chan 1',
        'control-center://workspaces/ws-1/spaces/chan-1?x=1',
        'control-center://workspaces/../spaces/chan-1',
      ]) {
        expect(DeepLinkHandler.resolve(url), isNull, reason: url);
      }
    });
  });

  group('pull requests', () {
    test('a PR link names the repo and the number', () {
      final target = DeepLinkHandler.resolve(
        'control-center://pr/acme/widgets/42',
      );

      expect(target, isA<PrDeepLink>());
      final pr = target! as PrDeepLink;
      expect(pr.owner, 'acme');
      expect(pr.repo, 'widgets');
      expect(pr.number, 42);
      expect(pr.commentId, isNull);
    });

    test('a comment permalink carries the comment id', () {
      final target = DeepLinkHandler.resolve(
        'control-center://pr/acme/widgets/42/comments/9001',
      );

      expect(target, isA<PrDeepLink>());
      final pr = target! as PrDeepLink;
      expect(pr.owner, 'acme');
      expect(pr.repo, 'widgets');
      expect(pr.number, 42);
      expect(pr.commentId, 9001);
    });

    test('the comment id must be numeric and the tail exact', () {
      for (final url in [
        'control-center://pr/acme/widgets/42/comments/abc',
        'control-center://pr/acme/widgets/42/comments',
        'control-center://pr/acme/widgets/42/comments/9001/extra',
        'control-center://pr/acme/widgets/42/comment/9001',
      ]) {
        expect(DeepLinkHandler.resolve(url), isNull, reason: url);
      }
    });

    test('a comment anchor as a QUERY is still refused', () {
      // The blanket refusal of a query or fragment is an anti-smuggling
      // invariant; the permalink extends the PATH grammar precisely so that
      // rule keeps holding.
      for (final url in [
        'control-center://pr/acme/widgets/42?comment=9001',
        'control-center://pr/acme/widgets/42#9001',
        'control-center://pr/acme/widgets/42/comments/9001?x=1',
      ]) {
        expect(DeepLinkHandler.resolve(url), isNull, reason: url);
      }
    });

    test('a PR link without a numeric number is not a link', () {
      for (final url in [
        'control-center://pr/acme/widgets/abc',
        'control-center://pr/acme/widgets',
        'control-center://pr/acme/widgets/42/files',
      ]) {
        expect(DeepLinkHandler.resolve(url), isNull, reason: url);
      }
    });
  });

  group('anything else', () {
    test('another scheme, or nonsense, resolves to nothing', () {
      for (final url in [
        'https://cc.example/open/workspaces/ws-1/spaces/chan-1',
        'control-centre://workspaces/ws-1/spaces/chan-1',
        'control-center://',
        '',
        ':::',
      ]) {
        expect(DeepLinkHandler.resolve(url), isNull, reason: url);
      }
    });
  });
}
