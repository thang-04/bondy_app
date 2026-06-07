import 'dart:convert';

import 'package:bondy/services/chat_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses relationship invitation realtime events', () {
    final event = ChatRealtimeEvent.tryParse(
      jsonEncode({
        'type': 'relationship_invited',
        'data': {
          'matchId': 'match-1',
          'invitation': {'id': 'invite-1', 'inviterId': 'user-1'},
        },
      }),
    );

    expect(event?.kind, ChatRealtimeEventKind.relationshipInvited);
    expect(event?.data['matchId'], 'match-1');
  });
}
