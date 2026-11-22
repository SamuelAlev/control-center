part of 'agent_run_gateway.dart';

/// The environment endpoint ([AgentRunGateway.envPath]): `cc-env`, the
/// `docker` shim and declared pass-through tools, decided by
/// [AgentRunGateway.environments] for the run the request authenticated as.
extension _GatewayEnvironmentCommands on AgentRunGateway {
  Future<void> _environmentCommand(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final environments = this.environments;
    final spaceId = grant.spaceId;
    final tool = request.headers.value('X-CC-Env-Tool');
    if (environments == null || spaceId == null || tool == null) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.notFound,
        'This run has no environment.',
      );
    }
    final body = await AgentRunGateway._readCapped(request, _maxEnvBodyBytes);
    if (body == null) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.requestEntityTooLarge,
        'Command too long.',
      );
    }
    final text = utf8.decode(body, allowMalformed: true);
    final arguments = text.isEmpty
        ? const <String>[]
        : (text.split('\u0000')..removeLast());
    final result = await environments.handle(
      AgentEnvironmentCaller(
        workspaceId: grant.workspaceId,
        spaceId: spaceId,
        conversationId: grant.conversationId,
        runId: grant.runLogId,
        agentId: grant.agentId,
        mode: grant.mode,
        actingUserId: grant.actingUserId,
        autonomy: await AgentRunGateway._autonomyOf(grant),
        // The calling command's listener, as for a push: an approval card
        // this command waits on stops its tool call's clocks.
        onPersonWait: _callWaitOf(secret, request),
        // And what the gateway decided labels that tool call's record.
        onDecided: _callDecidedOf(secret, request),
        // A card it raises counts against the run's scripts in flight.
        scriptApprovals: [...?_scriptApprovals[secret]],
      ),
      tool,
      arguments,
    );
    final stderr = utf8.encode(result.stderr);
    // Headers are bounded, and stderr's tail is the useful part.
    final tail = stderr.length > _maxEnvStderrBytes
        ? stderr.sublist(stderr.length - _maxEnvStderrBytes)
        : stderr;
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.set('X-CC-Exit-Code', '${result.exitCode}')
      ..headers.set('X-CC-Stderr', base64.encode(tail))
      ..headers.contentType = ContentType.text
      ..write(result.stdout);
    await request.response.close();
  }

  static const int _maxEnvBodyBytes = 1024 * 1024;
  static const int _maxEnvStderrBytes = 6 * 1024;
}
