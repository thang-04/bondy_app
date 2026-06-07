import 'package:bondy/services/relationship_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rewrites relative inviter photos for display', () {
    final invitation = RelationshipInvitation.fromJson({
      'id': 'invite-1',
      'inviterId': 'user-1',
      'inviterName': 'An',
      'inviterPhoto': '/uploads/profiles/an.jpg',
      'status': 'PENDING',
      'createdAt': '2026-06-07T10:00:00.000Z',
    });

    expect(invitation.inviterPhoto, isNotNull);
    expect(invitation.inviterPhoto, endsWith('/uploads/profiles/an.jpg'));
    expect(invitation.inviterPhoto, startsWith('http'));
  });

  test('rewrites relative partner photos for the relationship home', () {
    final dashboard = RelationshipDashboard.fromJson({
      'hasRelationship': true,
      'relationshipId': 'relationship-1',
      'partner': {
        'id': 'user-2',
        'name': 'Bình',
        'photoUrl': '/uploads/profiles/binh.jpg',
      },
    });

    expect(dashboard.partnerPhotoUrl, isNotNull);
    expect(dashboard.partnerPhotoUrl, endsWith('/uploads/profiles/binh.jpg'));
    expect(dashboard.partnerPhotoUrl, startsWith('http'));
  });
}
