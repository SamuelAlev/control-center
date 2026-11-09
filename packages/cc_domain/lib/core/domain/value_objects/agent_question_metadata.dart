/// Message-metadata keys of an `ask_user` question (`user_question` rows) and
/// the server's wait bound. One definition for the server's waiter, the
/// persistence layer and every client that renders or answers the form.
library;

/// Message metadata key marking the rendered question as answered.
const String kQuestionAnsweredKey = 'answered';

/// Message metadata key holding the serialized `AgentQuestionAnswer`.
const String kQuestionAnswerKey = 'answer';

/// Message metadata key marking a question that closed without an answer
/// (the asking agent stopped waiting: it timed out, gave up or was stopped, or
/// the server restarted under it). Set together with [kQuestionAnsweredKey]
/// so every "is this still open" reader treats it as resolved.
const String kQuestionExpiredKey = 'expired';

/// Message metadata key holding the UTC ISO-8601 instant the asking agent
/// stops waiting. Absent when the service waits indefinitely.
const String kQuestionExpiresAtKey = 'expiresAt';

/// Message metadata key holding the full wait, in milliseconds, so a client
/// can draw how much of it is left.
const String kQuestionTimeoutMsKey = 'timeoutMs';

/// How long the server's question waiter blocks before the question expires.
///
/// Shared with the client's wait reminder so it never re-raises a question
/// the server has already closed.
const Duration kAgentQuestionTimeout = Duration(minutes: 30);
