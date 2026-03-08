sealed class ServerWebSocketMessage {
  const ServerWebSocketMessage();
}

class LibraryChangedMessage extends ServerWebSocketMessage {
  final List<String> itemsAdded;
  final List<String> itemsUpdated;
  final List<String> itemsRemoved;

  const LibraryChangedMessage({
    this.itemsAdded = const [],
    this.itemsUpdated = const [],
    this.itemsRemoved = const [],
  });
}

class UserDataChangedMessage extends ServerWebSocketMessage {
  final String userId;
  final List<String> itemIds;

  const UserDataChangedMessage({
    required this.userId,
    this.itemIds = const [],
  });
}

class PlayMessage extends ServerWebSocketMessage {
  final List<String> itemIds;
  final int? startPositionTicks;
  final String playCommand;

  const PlayMessage({
    required this.itemIds,
    this.startPositionTicks,
    this.playCommand = 'PlayNow',
  });
}

class PlaystateMessage extends ServerWebSocketMessage {
  final String command;
  final int? seekPositionTicks;

  const PlaystateMessage({
    required this.command,
    this.seekPositionTicks,
  });
}

class GeneralCommandMessage extends ServerWebSocketMessage {
  final String name;
  final Map<String, String> arguments;

  const GeneralCommandMessage({
    required this.name,
    this.arguments = const {},
  });
}

class ServerRestartingMessage extends ServerWebSocketMessage {
  const ServerRestartingMessage();
}

class ServerShuttingDownMessage extends ServerWebSocketMessage {
  const ServerShuttingDownMessage();
}

class SessionEndedMessage extends ServerWebSocketMessage {
  final String sessionId;
  const SessionEndedMessage({required this.sessionId});
}

class ScheduledTaskEndedMessage extends ServerWebSocketMessage {
  final String taskId;
  final String taskName;
  final String status;

  const ScheduledTaskEndedMessage({
    required this.taskId,
    required this.taskName,
    required this.status,
  });
}
