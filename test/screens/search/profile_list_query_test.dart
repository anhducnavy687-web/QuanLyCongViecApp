import 'package:flutter_test/flutter_test.dart';
import 'package:quanlycongviecapp/models/models.dart';
import 'package:quanlycongviecapp/screens/search/profile_list_query.dart';

void main() {
  final now = DateTime(2026, 10, 4, 12);

  ProfileAggregate item({
    required String id,
    required String name,
    required String groupId,
    required DateTime updatedAt,
    ProfileStatus status = ProfileStatus.inProgress,
    DateTime? deadline,
    String phone = '',
    String? citizenId,
    String? rank,
    String? position,
    String? unit,
    String? aspiration1,
    Map<String, dynamic> customFields = const {},
  }) {
    return ProfileAggregate(
      profile: Profile(
        id: id,
        groupId: groupId,
        fullName: name,
        phone: phone,
        workTarget: 'Hoàn thiện hồ sơ',
        startDate: now.subtract(const Duration(days: 30)),
        deadline: deadline,
        hasDeadline: deadline != null,
        status: status,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: updatedAt,
        citizenId: citizenId,
        rank: rank,
        position: position,
        unit: unit,
        aspiration1: aspiration1,
        customFieldValues: customFields,
      ),
    );
  }

  late List<ProfileAggregate> source;

  setUp(() {
    source = [
      item(
        id: 'lan',
        name: 'Trần Thị Lan',
        groupId: 'g1',
        updatedAt: now.subtract(const Duration(days: 2)),
        deadline: now.subtract(const Duration(days: 1)),
        phone: '0901234567',
        citizenId: '001234567890',
        rank: 'Đại úy',
        position: 'Trợ lý',
        unit: 'Phòng Tham mưu',
        aspiration1: 'Học viện Kỹ thuật',
        customFields: const {'priority': 'Ưu tiên tháng mười'},
      ),
      item(
        id: 'an',
        name: 'Nguyễn Văn An',
        groupId: 'g2',
        updatedAt: now.subtract(const Duration(days: 4)),
        status: ProfileStatus.waiting,
        deadline: now.add(const Duration(days: 5)),
      ),
      item(
        id: 'binh',
        name: 'Lê Bình',
        groupId: 'g1',
        updatedAt: now,
        status: ProfileStatus.completed,
      ),
    ];
  });

  test('search is diacritic-insensitive across profile fields', () {
    for (final query in [
      'tran thi lan',
      '0901234567',
      '001234567890',
      'dai uy',
      'tro ly',
      'tham muu',
      'hoc vien ky thuat',
      'thang muoi',
    ]) {
      expect(
        ProfileListQuery.apply(
          source: source,
          query: query,
        ).map((e) => e.profile.id),
        ['lan'],
        reason: query,
      );
    }
  });

  test('status and deadline filters return the expected profiles', () {
    expect(
      ProfileListQuery.apply(
        source: source,
        filter: ProfileFilter.overdue,
      ).map((e) => e.profile.id),
      ['lan'],
    );
    expect(
      ProfileListQuery.apply(
        source: source,
        filter: ProfileFilter.waiting,
      ).map((e) => e.profile.id),
      ['an'],
    );
    expect(
      ProfileListQuery.apply(
        source: source,
        filter: ProfileFilter.completed,
      ).map((e) => e.profile.id),
      ['binh'],
    );
  });

  test('group filter combines with search and can return no results', () {
    expect(
      ProfileListQuery.apply(
        source: source,
        groupId: 'g1',
        query: 'le binh',
      ).map((e) => e.profile.id),
      ['binh'],
    );
    expect(
      ProfileListQuery.apply(source: source, groupId: 'g2', query: 'le binh'),
      isEmpty,
    );
  });

  test('supports newest and Vietnamese A-Z sorting', () {
    expect(
      ProfileListQuery.apply(
        source: source,
        sort: ProfileSort.updatedNewest,
      ).map((e) => e.profile.id),
      ['binh', 'lan', 'an'],
    );
    expect(
      ProfileListQuery.apply(
        source: source,
        sort: ProfileSort.nameAZ,
      ).map((e) => e.profile.id),
      ['binh', 'an', 'lan'],
    );
  });
}
