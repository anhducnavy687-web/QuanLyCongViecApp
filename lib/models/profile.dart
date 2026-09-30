/// Trạng thái tổng thể của một hồ sơ.
enum ProfileStatus {
  newProfile,
  inProgress,
  waiting,
  completed,
  cancelled;

  static ProfileStatus fromValue(String value) {
    return ProfileStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ProfileStatus.newProfile,
    );
  }

  String get value {
    switch (this) {
      case ProfileStatus.newProfile:
        return 'new';
      case ProfileStatus.inProgress:
        return 'inProgress';
      case ProfileStatus.waiting:
        return 'waiting';
      case ProfileStatus.completed:
        return 'completed';
      case ProfileStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case ProfileStatus.newProfile:
        return 'Mới tiếp nhận';
      case ProfileStatus.inProgress:
        return 'Đang xử lý';
      case ProfileStatus.waiting:
        return 'Đang chờ';
      case ProfileStatus.completed:
        return 'Hoàn thành';
      case ProfileStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Hồ sơ / người cần xử lý — thực thể trung tâm của ứng dụng.
class Profile {
  final String id;
  final String groupId;
  final String fullName;
  final String phone;
  final String workTarget;
  final String description;
  final DateTime startDate;
  final DateTime? deadline;
  final bool hasDeadline;
  final ProfileStatus status;
  final num totalAmount;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? waitingReason;
  final DateTime? waitingSince;
  final DateTime? expectedResponseDate;
  final DateTime? dateOfBirth;
  final String? citizenId, rank, position, unit, enlistment, hometown;
  final String? currentResidence,
      educationLevel,
      specialty,
      schoolHistory,
      officerRating;
  final String? fatherFullName,
      fatherOccupation,
      fatherHometown,
      fatherCurrentResidence;
  final int? fatherBirthYear;
  final String? motherFullName,
      motherOccupation,
      motherHometown,
      motherCurrentResidence;
  final int? motherBirthYear;
  final String? aspiration1, aspiration2, aspiration3;
  final Map<String, dynamic> customFieldValues;

  const Profile({
    required this.id,
    required this.groupId,
    required this.fullName,
    this.phone = '',
    required this.workTarget,
    this.description = '',
    required this.startDate,
    this.deadline,
    this.hasDeadline = false,
    this.status = ProfileStatus.newProfile,
    this.totalAmount = 0,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.waitingReason,
    this.waitingSince,
    this.expectedResponseDate,
    this.dateOfBirth,
    this.citizenId,
    this.rank,
    this.position,
    this.unit,
    this.enlistment,
    this.hometown,
    this.currentResidence,
    this.educationLevel,
    this.specialty,
    this.schoolHistory,
    this.officerRating,
    this.fatherFullName,
    this.fatherBirthYear,
    this.fatherOccupation,
    this.fatherHometown,
    this.fatherCurrentResidence,
    this.motherFullName,
    this.motherBirthYear,
    this.motherOccupation,
    this.motherHometown,
    this.motherCurrentResidence,
    this.aspiration1,
    this.aspiration2,
    this.aspiration3,
    this.customFieldValues = const {},
  });

  Profile copyWith({
    String? id,
    String? groupId,
    String? fullName,
    String? phone,
    String? workTarget,
    String? description,
    DateTime? startDate,
    DateTime? deadline,
    bool? hasDeadline,
    ProfileStatus? status,
    num? totalAmount,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearDeadline = false,
    bool clearCompletedAt = false,
    String? waitingReason,
    bool clearWaitingReason = false,
    DateTime? waitingSince,
    bool clearWaitingSince = false,
    DateTime? expectedResponseDate,
    bool clearExpectedResponseDate = false,
    DateTime? dateOfBirth,
    String? citizenId,
    String? rank,
    String? position,
    String? unit,
    String? enlistment,
    String? hometown,
    String? currentResidence,
    String? educationLevel,
    String? specialty,
    String? schoolHistory,
    String? officerRating,
    String? fatherFullName,
    int? fatherBirthYear,
    String? fatherOccupation,
    String? fatherHometown,
    String? fatherCurrentResidence,
    String? motherFullName,
    int? motherBirthYear,
    String? motherOccupation,
    String? motherHometown,
    String? motherCurrentResidence,
    String? aspiration1,
    String? aspiration2,
    String? aspiration3,
    Map<String, dynamic>? customFieldValues,
  }) {
    return Profile(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      workTarget: workTarget ?? this.workTarget,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      hasDeadline: hasDeadline ?? this.hasDeadline,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      waitingReason: clearWaitingReason
          ? null
          : (waitingReason ?? this.waitingReason),
      waitingSince: clearWaitingSince
          ? null
          : (waitingSince ?? this.waitingSince),
      expectedResponseDate: clearExpectedResponseDate
          ? null
          : (expectedResponseDate ?? this.expectedResponseDate),
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      citizenId: citizenId ?? this.citizenId,
      rank: rank ?? this.rank,
      position: position ?? this.position,
      unit: unit ?? this.unit,
      enlistment: enlistment ?? this.enlistment,
      hometown: hometown ?? this.hometown,
      currentResidence: currentResidence ?? this.currentResidence,
      educationLevel: educationLevel ?? this.educationLevel,
      specialty: specialty ?? this.specialty,
      schoolHistory: schoolHistory ?? this.schoolHistory,
      officerRating: officerRating ?? this.officerRating,
      fatherFullName: fatherFullName ?? this.fatherFullName,
      fatherBirthYear: fatherBirthYear ?? this.fatherBirthYear,
      fatherOccupation: fatherOccupation ?? this.fatherOccupation,
      fatherHometown: fatherHometown ?? this.fatherHometown,
      fatherCurrentResidence:
          fatherCurrentResidence ?? this.fatherCurrentResidence,
      motherFullName: motherFullName ?? this.motherFullName,
      motherBirthYear: motherBirthYear ?? this.motherBirthYear,
      motherOccupation: motherOccupation ?? this.motherOccupation,
      motherHometown: motherHometown ?? this.motherHometown,
      motherCurrentResidence:
          motherCurrentResidence ?? this.motherCurrentResidence,
      aspiration1: aspiration1 ?? this.aspiration1,
      aspiration2: aspiration2 ?? this.aspiration2,
      aspiration3: aspiration3 ?? this.aspiration3,
      customFieldValues: customFieldValues ?? this.customFieldValues,
    );
  }

  /// Replaces every dynamic profile value, including with `null`.
  ///
  /// This is intentionally separate from [copyWith], whose nullable arguments
  /// mean "keep the current value" for backward compatibility.
  Profile replaceDynamicValues({
    DateTime? dateOfBirth,
    String? citizenId,
    String? rank,
    String? position,
    String? unit,
    String? enlistment,
    String? hometown,
    String? currentResidence,
    String? educationLevel,
    String? specialty,
    String? schoolHistory,
    String? officerRating,
    String? fatherFullName,
    int? fatherBirthYear,
    String? fatherOccupation,
    String? fatherHometown,
    String? fatherCurrentResidence,
    String? motherFullName,
    int? motherBirthYear,
    String? motherOccupation,
    String? motherHometown,
    String? motherCurrentResidence,
    String? aspiration1,
    String? aspiration2,
    String? aspiration3,
    required Map<String, dynamic> customFieldValues,
  }) => Profile(
    id: id,
    groupId: groupId,
    fullName: fullName,
    phone: phone,
    workTarget: workTarget,
    description: description,
    startDate: startDate,
    deadline: deadline,
    hasDeadline: hasDeadline,
    status: status,
    totalAmount: totalAmount,
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
    waitingReason: waitingReason,
    waitingSince: waitingSince,
    expectedResponseDate: expectedResponseDate,
    dateOfBirth: dateOfBirth,
    citizenId: citizenId,
    rank: rank,
    position: position,
    unit: unit,
    enlistment: enlistment,
    hometown: hometown,
    currentResidence: currentResidence,
    educationLevel: educationLevel,
    specialty: specialty,
    schoolHistory: schoolHistory,
    officerRating: officerRating,
    fatherFullName: fatherFullName,
    fatherBirthYear: fatherBirthYear,
    fatherOccupation: fatherOccupation,
    fatherHometown: fatherHometown,
    fatherCurrentResidence: fatherCurrentResidence,
    motherFullName: motherFullName,
    motherBirthYear: motherBirthYear,
    motherOccupation: motherOccupation,
    motherHometown: motherHometown,
    motherCurrentResidence: motherCurrentResidence,
    aspiration1: aspiration1,
    aspiration2: aspiration2,
    aspiration3: aspiration3,
    customFieldValues: customFieldValues,
  );

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String? ?? '',
      workTarget: json['workTarget'] as String,
      description: json['description'] as String? ?? '',
      startDate: DateTime.parse(json['startDate'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      hasDeadline: json['hasDeadline'] as bool? ?? false,
      status: ProfileStatus.fromValue(json['status'] as String? ?? 'new'),
      totalAmount: json['totalAmount'] as num? ?? 0,
      note: json['note'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      waitingReason: json['waitingReason'] as String?,
      waitingSince: json['waitingSince'] != null
          ? DateTime.parse(json['waitingSince'] as String)
          : null,
      expectedResponseDate: json['expectedResponseDate'] != null
          ? DateTime.parse(json['expectedResponseDate'] as String)
          : null,
      dateOfBirth: json['dateOfBirth'] == null
          ? null
          : DateTime.parse(json['dateOfBirth'] as String),
      citizenId: json['citizenId'] as String?,
      rank: json['rank'] as String?,
      position: json['position'] as String?,
      unit: json['unit'] as String?,
      enlistment: json['enlistment'] as String?,
      hometown: json['hometown'] as String?,
      currentResidence: json['currentResidence'] as String?,
      educationLevel: json['educationLevel'] as String?,
      specialty: json['specialty'] as String?,
      schoolHistory: json['schoolHistory'] as String?,
      officerRating: json['officerRating'] as String?,
      fatherFullName: json['fatherFullName'] as String?,
      fatherBirthYear: json['fatherBirthYear'] as int?,
      fatherOccupation: json['fatherOccupation'] as String?,
      fatherHometown: json['fatherHometown'] as String?,
      fatherCurrentResidence: json['fatherCurrentResidence'] as String?,
      motherFullName: json['motherFullName'] as String?,
      motherBirthYear: json['motherBirthYear'] as int?,
      motherOccupation: json['motherOccupation'] as String?,
      motherHometown: json['motherHometown'] as String?,
      motherCurrentResidence: json['motherCurrentResidence'] as String?,
      aspiration1: json['aspiration1'] as String?,
      aspiration2: json['aspiration2'] as String?,
      aspiration3: json['aspiration3'] as String?,
      customFieldValues: Map<String, dynamic>.from(
        json['customFieldValues'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'fullName': fullName,
      'phone': phone,
      'workTarget': workTarget,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'hasDeadline': hasDeadline,
      'status': status.value,
      'totalAmount': totalAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'waitingReason': waitingReason,
      'waitingSince': waitingSince?.toIso8601String(),
      'expectedResponseDate': expectedResponseDate?.toIso8601String(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'citizenId': citizenId,
      'rank': rank,
      'position': position,
      'unit': unit,
      'enlistment': enlistment,
      'hometown': hometown,
      'currentResidence': currentResidence,
      'educationLevel': educationLevel,
      'specialty': specialty,
      'schoolHistory': schoolHistory,
      'officerRating': officerRating,
      'fatherFullName': fatherFullName,
      'fatherBirthYear': fatherBirthYear,
      'fatherOccupation': fatherOccupation,
      'fatherHometown': fatherHometown,
      'fatherCurrentResidence': fatherCurrentResidence,
      'motherFullName': motherFullName,
      'motherBirthYear': motherBirthYear,
      'motherOccupation': motherOccupation,
      'motherHometown': motherHometown,
      'motherCurrentResidence': motherCurrentResidence,
      'aspiration1': aspiration1,
      'aspiration2': aspiration2,
      'aspiration3': aspiration3,
      'customFieldValues': customFieldValues,
    };
  }
}
