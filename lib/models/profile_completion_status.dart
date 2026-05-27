// ignore_for_file: constant_identifier_names

enum MissingField {
  fullName,
  gender,
  birthDate,
  city,
  photos,
  geohash,
  interests,
  survey,
}

enum NextOnboardingAction {
  COMPLETE_PROFILE,
  ADD_PHOTOS,
  SET_LOCATION,
  ADD_INTERESTS,
  COMPLETE_SURVEY,
  READY,
}

class ProfileCompletionStatus {
  final bool isComplete;
  final int percentComplete;
  final List<MissingField> missingFields;
  final NextOnboardingAction nextAction;

  const ProfileCompletionStatus({
    required this.isComplete,
    required this.percentComplete,
    required this.missingFields,
    required this.nextAction,
  });

  factory ProfileCompletionStatus.fromJson(Map<String, dynamic> json) {
    return ProfileCompletionStatus(
      isComplete: json['isComplete'] as bool? ?? false,
      percentComplete: json['percentComplete'] as int? ?? 0,
      missingFields:
          (json['missingFields'] as List<dynamic>?)
              ?.map(
                (e) => MissingField.values.firstWhere(
                  (v) => v.name == e,
                  orElse: () => MissingField.fullName,
                ),
              )
              .toList() ??
          [],
      nextAction: NextOnboardingAction.values.firstWhere(
        (v) => v.name == json['nextAction'],
        orElse: () => NextOnboardingAction.COMPLETE_PROFILE,
      ),
    );
  }
}

class ProfileIncompleteException implements Exception {
  final List<String> missingRequirements;
  final String? nextAction;

  ProfileIncompleteException({
    required this.missingRequirements,
    this.nextAction,
  });

  @override
  String toString() =>
      'ProfileIncompleteException(missingRequirements: $missingRequirements, nextAction: $nextAction)';
}
