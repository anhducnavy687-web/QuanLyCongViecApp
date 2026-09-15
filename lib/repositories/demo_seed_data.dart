import '../core/constants/app_constants.dart';
import '../models/models.dart';

/// Toàn bộ dữ liệu demo được sinh ra ở đây, tách riêng khỏi [DemoRepository]
/// để dễ đọc/dễ chỉnh. Ngày tháng được tính TƯƠNG ĐỐI theo thời điểm chạy
/// app (DateTime.now()) để các trạng thái "quá hạn / hôm nay / sắp đến hạn"
/// luôn đúng chứ không bị lỗi thời như khi hard-code ngày cố định.
class DemoSeedBundle {
  final List<WorkGroup> groups;
  final List<Profile> profiles;
  final List<WorkStage> stages;
  final List<Milestone> milestones;
  final List<MoneyTransaction> transactions;
  final List<Collaborator> collaborators;
  final List<CollaboratorAssignment> assignments;
  final List<Attachment> attachments;

  const DemoSeedBundle({
    required this.groups,
    required this.profiles,
    required this.stages,
    required this.milestones,
    required this.transactions,
    required this.collaborators,
    required this.assignments,
    required this.attachments,
  });
}

DemoSeedBundle buildDemoSeed() {
  final now = DateTime.now();
  DateTime daysAgo(int d) => DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: d));
  DateTime daysFromNow(int d) =>
      DateTime(now.year, now.month, now.day).add(Duration(days: d));

  // ---------------------------------------------------------------------
  // Nhóm công việc
  // ---------------------------------------------------------------------
  final groups = <WorkGroup>[
    WorkGroup(
      id: 'g1',
      name: 'Đất đai',
      description: 'Thủ tục liên quan tới đất đai, sổ đỏ, tách thửa...',
      createdAt: daysAgo(200),
      updatedAt: daysAgo(5),
    ),
    WorkGroup(
      id: 'g2',
      name: 'Hành chính',
      description: 'Giấy tờ hành chính: CCCD, hộ khẩu, kết hôn...',
      createdAt: daysAgo(200),
      updatedAt: daysAgo(10),
    ),
    WorkGroup(
      id: 'g3',
      name: 'Hồ sơ cá nhân',
      description: 'Lý lịch tư pháp, hộ chiếu, giấy tờ cá nhân khác.',
      createdAt: daysAgo(180),
      updatedAt: daysAgo(20),
    ),
    WorkGroup(
      id: 'g4',
      name: 'Khác',
      description: 'Các công việc không thuộc nhóm trên.',
      createdAt: daysAgo(150),
      updatedAt: daysAgo(30),
    ),
  ];

  // ---------------------------------------------------------------------
  // Cộng tác viên
  // ---------------------------------------------------------------------
  final collaborators = <Collaborator>[
    Collaborator(
      id: 'ctv1',
      name: 'Nguyễn Thị Hoa',
      phone: '0901234567',
      note: 'Chuyên viên địa chính, hỗ trợ đo đạc.',
      active: true,
      createdAt: daysAgo(200),
      updatedAt: daysAgo(5),
    ),
    Collaborator(
      id: 'ctv2',
      name: 'Trần Văn Đức',
      phone: '0912345678',
      note: 'CTV pháp lý, hỗ trợ soạn hồ sơ.',
      active: true,
      createdAt: daysAgo(180),
      updatedAt: daysAgo(15),
    ),
    Collaborator(
      id: 'ctv3',
      name: 'Lê Thị Thanh',
      phone: '0923456789',
      note: 'CTV hành chính khu vực Quận 1.',
      active: true,
      createdAt: daysAgo(160),
      updatedAt: daysAgo(40),
    ),
    Collaborator(
      id: 'ctv4',
      name: 'Phạm Văn Sơn',
      phone: '0934567890',
      note: 'CTV thu hồ sơ tận nơi.',
      active: false,
      createdAt: daysAgo(120),
      updatedAt: daysAgo(60),
    ),
  ];

  final profiles = <Profile>[];
  final stages = <WorkStage>[];
  final milestones = <Milestone>[];
  final transactions = <MoneyTransaction>[];
  final assignments = <CollaboratorAssignment>[];
  final attachments = <Attachment>[];

  int stageSeq = 1;
  int msSeq = 1;
  int txSeq = 1;
  int asSeq = 1;
  int attSeq = 1;

  List<WorkStage> makeStages(
    String profileId,
    List<StageStatus> statusList, {
    DateTime? baseStart,
  }) {
    final result = <WorkStage>[];
    for (var i = 0; i < AppConstants.defaultStageNames.length; i++) {
      final status = i < statusList.length ? statusList[i] : StageStatus.pending;
      result.add(WorkStage(
        id: 's${stageSeq++}',
        profileId: profileId,
        name: AppConstants.defaultStageNames[i],
        order: i,
        status: status,
        startDate: status == StageStatus.pending
            ? null
            : (baseStart ?? daysAgo(30)).add(Duration(days: i * 3)),
        completedAt: status == StageStatus.completed
            ? (baseStart ?? daysAgo(30)).add(Duration(days: i * 3 + 2))
            : null,
        note: '',
      ));
    }
    return result;
  }

  // =======================================================================
  // 1. Nguyễn Văn Minh — Đất đai — sắp đến hạn, đang xử lý
  // =======================================================================
  final p1 = Profile(
    id: 'p1',
    groupId: 'g1',
    fullName: 'Nguyễn Văn Minh',
    phone: '0987111222',
    workTarget: 'Làm thủ tục chuyển nhượng quyền sử dụng đất',
    description: 'Chuyển nhượng thửa đất 120m2 tại phường Tân Phú.',
    startDate: daysAgo(20),
    deadline: daysFromNow(5),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 20000000,
    note: 'Khách quen, cần ưu tiên xử lý nhanh.',
    createdAt: daysAgo(20),
    updatedAt: daysAgo(1),
  );
  profiles.add(p1);
  stages.addAll(makeStages(
    p1.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(20),
  ));
  milestones.addAll([
    Milestone(
      id: 'm${msSeq++}',
      profileId: p1.id,
      title: 'Nộp hồ sơ tại văn phòng đăng ký đất đai',
      dueDate: daysAgo(15),
      status: MilestoneStatus.completed,
      completedAt: daysAgo(15),
    ),
    Milestone(
      id: 'm${msSeq++}',
      profileId: p1.id,
      title: 'Làm việc với bên mua để bổ sung giấy tờ',
      dueDate: daysFromNow(2),
      status: MilestoneStatus.pending,
    ),
    Milestone(
      id: 'm${msSeq++}',
      profileId: p1.id,
      title: 'Nhận kết quả sang tên',
      dueDate: daysFromNow(5),
      status: MilestoneStatus.pending,
    ),
  ]);
  transactions.addAll([
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p1.id,
      type: TransactionType.received,
      amount: 8000000,
      date: daysAgo(20),
      note: 'Tạm ứng lần 1',
      createdAt: daysAgo(20),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p1.id,
      type: TransactionType.received,
      amount: 4000000,
      date: daysAgo(8),
      note: 'Tạm ứng lần 2',
      createdAt: daysAgo(8),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p1.id,
      type: TransactionType.expense,
      amount: 500000,
      date: daysAgo(10),
      note: 'Phí đo đạc lại',
      createdAt: daysAgo(10),
    ),
  ]);
  final a1 = CollaboratorAssignment(
    id: 'as${asSeq++}',
    profileId: p1.id,
    collaboratorId: 'ctv1',
    role: 'Đo đạc, xác minh ranh giới',
    commissionAmount: 1500000,
    paidAmount: 1000000,
    createdAt: daysAgo(20),
    updatedAt: daysAgo(5),
  );
  assignments.add(a1);
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p1.id,
    type: TransactionType.collaboratorPayment,
    amount: 1000000,
    date: daysAgo(5),
    note: 'Tạm ứng công đo đạc',
    createdAt: daysAgo(5),
    collaboratorAssignmentId: a1.id,
  ));
  attachments.addAll([
    Attachment(
      id: 'att${attSeq++}',
      profileId: p1.id,
      fileName: 'So_do_thua_dat.pdf',
      type: AttachmentType.pdf,
      localPathOrUrl: 'demo_assets/so_do_thua_dat.pdf',
      sizeBytes: 245000,
      createdAt: daysAgo(18),
      updatedAt: daysAgo(18),
    ),
    Attachment(
      id: 'att${attSeq++}',
      profileId: p1.id,
      fileName: 'CCCD_ben_ban.jpg',
      type: AttachmentType.jpg,
      localPathOrUrl: 'demo_assets/cccd_ben_ban.jpg',
      sizeBytes: 890000,
      createdAt: daysAgo(18),
      updatedAt: daysAgo(18),
    ),
  ]);

  // =======================================================================
  // 2. Trần Thị Lan — Hành chính — QUÁ HẠN
  // =======================================================================
  final p2 = Profile(
    id: 'p2',
    groupId: 'g2',
    fullName: 'Trần Thị Lan',
    phone: '0977222333',
    workTarget: 'Làm căn cước công dân gắn chip',
    description: 'Cấp lại CCCD do mất, cần gấp để làm hồ sơ vay vốn.',
    startDate: daysAgo(25),
    deadline: daysAgo(2),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 3000000,
    note: 'Khách hối nhiều lần, ưu tiên xử lý.',
    createdAt: daysAgo(25),
    updatedAt: daysAgo(6),
  );
  profiles.add(p2);
  stages.addAll(makeStages(
    p2.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(25),
  ));
  milestones.add(Milestone(
    id: 'm${msSeq++}',
    profileId: p2.id,
    title: 'Nhận kết quả tại công an quận',
    dueDate: daysAgo(2),
    status: MilestoneStatus.pending,
  ));
  transactions.addAll([
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p2.id,
      type: TransactionType.received,
      amount: 3000000,
      date: daysAgo(25),
      note: 'Thu đủ ngay từ đầu',
      createdAt: daysAgo(25),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p2.id,
      type: TransactionType.expense,
      amount: 200000,
      date: daysAgo(20),
      note: 'Lệ phí nhà nước',
      createdAt: daysAgo(20),
    ),
  ]);

  // =======================================================================
  // 3. Lê Hoàng Nam — Đất đai — HÔM NAY
  // =======================================================================
  final p3 = Profile(
    id: 'p3',
    groupId: 'g1',
    fullName: 'Lê Hoàng Nam',
    phone: '0966333444',
    workTarget: 'Tách thửa đất nông nghiệp',
    description: 'Tách thửa 500m2 thành 2 thửa cho 2 con.',
    startDate: daysAgo(30),
    deadline: daysFromNow(0),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 15000000,
    note: '',
    createdAt: daysAgo(30),
    updatedAt: daysAgo(2),
  );
  profiles.add(p3);
  stages.addAll(makeStages(
    p3.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(30),
  ));
  milestones.add(Milestone(
    id: 'm${msSeq++}',
    profileId: p3.id,
    title: 'Nhận kết quả đo đạc tách thửa',
    dueDate: daysFromNow(0),
    status: MilestoneStatus.pending,
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p3.id,
    type: TransactionType.received,
    amount: 10000000,
    date: daysAgo(30),
    note: 'Tạm ứng',
    createdAt: daysAgo(30),
  ));

  // =======================================================================
  // 4. Phạm Thị Hương — Hồ sơ cá nhân — KHÔNG CÓ DEADLINE (trì trệ)
  // =======================================================================
  final p4 = Profile(
    id: 'p4',
    groupId: 'g3',
    fullName: 'Phạm Thị Hương',
    phone: '0955444555',
    workTarget: 'Làm lý lịch tư pháp số 1',
    description: 'Phục vụ xin việc tại công ty nước ngoài.',
    startDate: daysAgo(37),
    deadline: null,
    hasDeadline: false,
    status: ProfileStatus.inProgress,
    totalAmount: 500000,
    note: 'Khách chưa hối, không gấp nhưng cần theo dõi để không quên.',
    createdAt: daysAgo(37),
    updatedAt: daysAgo(20),
  );
  profiles.add(p4);
  stages.addAll(makeStages(
    p4.id,
    [StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(37),
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p4.id,
    type: TransactionType.received,
    amount: 500000,
    date: daysAgo(37),
    note: 'Thu đủ',
    createdAt: daysAgo(37),
  ));

  // =======================================================================
  // 5. Vũ Đức Thắng — Khác — đang xử lý bình thường
  // =======================================================================
  final p5 = Profile(
    id: 'p5',
    groupId: 'g4',
    fullName: 'Vũ Đức Thắng',
    phone: '0944555666',
    workTarget: 'Xin giấy phép kinh doanh hộ cá thể',
    description: 'Mở quán cà phê nhỏ tại nhà.',
    startDate: daysAgo(5),
    deadline: daysFromNow(20),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 4000000,
    note: '',
    createdAt: daysAgo(5),
    updatedAt: daysAgo(1),
  );
  profiles.add(p5);
  stages.addAll(makeStages(
    p5.id,
    [StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(5),
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p5.id,
    type: TransactionType.received,
    amount: 2000000,
    date: daysAgo(5),
    note: 'Tạm ứng lần 1',
    createdAt: daysAgo(5),
  ));

  // =======================================================================
  // 6. Đặng Thị Mai — Đất đai — ĐANG CHỜ
  // =======================================================================
  final p6 = Profile(
    id: 'p6',
    groupId: 'g1',
    fullName: 'Đặng Thị Mai',
    phone: '0933666777',
    workTarget: 'Cấp sổ đỏ lần đầu',
    description: 'Đất khai hoang từ 1995, chưa có giấy tờ.',
    startDate: daysAgo(60),
    deadline: daysFromNow(10),
    hasDeadline: true,
    status: ProfileStatus.waiting,
    totalAmount: 25000000,
    note: 'Đang chờ xác minh nguồn gốc đất từ UBND xã.',
    createdAt: daysAgo(60),
    updatedAt: daysAgo(12),
  );
  profiles.add(p6);
  stages.addAll(makeStages(
    p6.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(60),
  ));
  milestones.add(Milestone(
    id: 'm${msSeq++}',
    profileId: p6.id,
    title: 'UBND xã xác minh nguồn gốc đất',
    dueDate: daysFromNow(10),
    status: MilestoneStatus.pending,
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p6.id,
    type: TransactionType.received,
    amount: 15000000,
    date: daysAgo(60),
    note: 'Tạm ứng lần 1',
    createdAt: daysAgo(60),
  ));
  final a2 = CollaboratorAssignment(
    id: 'as${asSeq++}',
    profileId: p6.id,
    collaboratorId: 'ctv2',
    role: 'Hỗ trợ pháp lý, làm việc với UBND xã',
    commissionAmount: 3000000,
    paidAmount: 0,
    createdAt: daysAgo(60),
    updatedAt: daysAgo(60),
  );
  assignments.add(a2);

  // =======================================================================
  // 7. Hoàng Văn Long — Hành chính — MỚI TIẾP NHẬN
  // =======================================================================
  final p7 = Profile(
    id: 'p7',
    groupId: 'g2',
    fullName: 'Hoàng Văn Long',
    phone: '0922777888',
    workTarget: 'Đăng ký kết hôn có yếu tố nước ngoài',
    description: 'Kết hôn với người Hàn Quốc, cần hợp pháp hóa lãnh sự.',
    startDate: daysAgo(1),
    deadline: daysFromNow(15),
    hasDeadline: true,
    status: ProfileStatus.newProfile,
    totalAmount: 6000000,
    note: 'Mới tiếp nhận, chưa thu tiền.',
    createdAt: daysAgo(1),
    updatedAt: daysAgo(1),
  );
  profiles.add(p7);
  stages.addAll(makeStages(
    p7.id,
    [StageStatus.inProgress],
    baseStart: daysAgo(1),
  ));

  // =======================================================================
  // 8. Bùi Thị Thu — Hồ sơ cá nhân — HOÀN THÀNH
  // =======================================================================
  final p8 = Profile(
    id: 'p8',
    groupId: 'g3',
    fullName: 'Bùi Thị Thu',
    phone: '0911888999',
    workTarget: 'Làm hộ chiếu phổ thông',
    description: 'Làm mới hộ chiếu để đi du lịch.',
    startDate: daysAgo(45),
    deadline: daysAgo(15),
    hasDeadline: true,
    status: ProfileStatus.completed,
    totalAmount: 1500000,
    note: 'Đã bàn giao tận tay khách.',
    createdAt: daysAgo(45),
    updatedAt: daysAgo(14),
    completedAt: daysAgo(14),
  );
  profiles.add(p8);
  stages.addAll(makeStages(
    p8.id,
    [
      StageStatus.completed,
      StageStatus.completed,
      StageStatus.completed,
      StageStatus.completed,
      StageStatus.completed,
    ],
    baseStart: daysAgo(45),
  ));
  milestones.add(Milestone(
    id: 'm${msSeq++}',
    profileId: p8.id,
    title: 'Bàn giao hộ chiếu cho khách',
    dueDate: daysAgo(14),
    status: MilestoneStatus.completed,
    completedAt: daysAgo(14),
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p8.id,
    type: TransactionType.received,
    amount: 1500000,
    date: daysAgo(45),
    note: 'Thu đủ',
    createdAt: daysAgo(45),
  ));

  // =======================================================================
  // 9. Ngô Văn Tùng — Khác — SẮP ĐẾN HẠN (2 ngày)
  // =======================================================================
  final p9 = Profile(
    id: 'p9',
    groupId: 'g4',
    fullName: 'Ngô Văn Tùng',
    phone: '0900999111',
    workTarget: 'Công chứng hợp đồng mua bán xe ô tô',
    description: 'Xe Toyota Vios đời 2020.',
    startDate: daysAgo(3),
    deadline: daysFromNow(2),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 1000000,
    note: '',
    createdAt: daysAgo(3),
    updatedAt: daysAgo(1),
  );
  profiles.add(p9);
  stages.addAll(makeStages(
    p9.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(3),
  ));
  transactions.add(MoneyTransaction(
    id: 't${txSeq++}',
    profileId: p9.id,
    type: TransactionType.received,
    amount: 1000000,
    date: daysAgo(3),
    note: 'Thu đủ',
    createdAt: daysAgo(3),
  ));

  // =======================================================================
  // 10. Đỗ Thị Ngọc — Đất đai — QUÁ HẠN NẶNG, nhiều CTV
  // =======================================================================
  final p10 = Profile(
    id: 'p10',
    groupId: 'g1',
    fullName: 'Đỗ Thị Ngọc',
    phone: '0888111222',
    workTarget: 'Giải quyết tranh chấp ranh giới đất',
    description: 'Tranh chấp với hộ liền kề, cần hòa giải tại xã.',
    startDate: daysAgo(90),
    deadline: daysAgo(10),
    hasDeadline: true,
    status: ProfileStatus.inProgress,
    totalAmount: 30000000,
    note: 'Hồ sơ phức tạp, kéo dài do hai bên chưa thống nhất.',
    createdAt: daysAgo(90),
    updatedAt: daysAgo(25),
  );
  profiles.add(p10);
  stages.addAll(makeStages(
    p10.id,
    [StageStatus.completed, StageStatus.completed, StageStatus.inProgress],
    baseStart: daysAgo(90),
  ));
  milestones.addAll([
    Milestone(
      id: 'm${msSeq++}',
      profileId: p10.id,
      title: 'Hòa giải tại UBND xã',
      dueDate: daysAgo(10),
      status: MilestoneStatus.pending,
    ),
    Milestone(
      id: 'm${msSeq++}',
      profileId: p10.id,
      title: 'Đo đạc lại ranh giới thực tế',
      dueDate: daysAgo(30),
      status: MilestoneStatus.completed,
      completedAt: daysAgo(28),
    ),
  ]);
  transactions.addAll([
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p10.id,
      type: TransactionType.received,
      amount: 15000000,
      date: daysAgo(90),
      note: 'Tạm ứng lần 1',
      createdAt: daysAgo(90),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p10.id,
      type: TransactionType.received,
      amount: 5000000,
      date: daysAgo(40),
      note: 'Tạm ứng lần 2',
      createdAt: daysAgo(40),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p10.id,
      type: TransactionType.expense,
      amount: 1200000,
      date: daysAgo(35),
      note: 'Chi phí đo đạc lại ranh giới',
      createdAt: daysAgo(35),
    ),
  ]);
  final a3 = CollaboratorAssignment(
    id: 'as${asSeq++}',
    profileId: p10.id,
    collaboratorId: 'ctv1',
    role: 'Đo đạc thực địa',
    commissionAmount: 2000000,
    paidAmount: 2000000,
    createdAt: daysAgo(90),
    updatedAt: daysAgo(35),
  );
  final a4 = CollaboratorAssignment(
    id: 'as${asSeq++}',
    profileId: p10.id,
    collaboratorId: 'ctv3',
    role: 'Làm việc với UBND xã',
    commissionAmount: 2500000,
    paidAmount: 1000000,
    createdAt: daysAgo(80),
    updatedAt: daysAgo(20),
  );
  assignments.addAll([a3, a4]);
  transactions.addAll([
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p10.id,
      type: TransactionType.collaboratorPayment,
      amount: 2000000,
      date: daysAgo(35),
      note: 'Thanh toán đủ công đo đạc',
      createdAt: daysAgo(35),
      collaboratorAssignmentId: a3.id,
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p10.id,
      type: TransactionType.collaboratorPayment,
      amount: 1000000,
      date: daysAgo(20),
      note: 'Tạm ứng công làm việc với xã',
      createdAt: daysAgo(20),
      collaboratorAssignmentId: a4.id,
    ),
  ]);
  attachments.add(Attachment(
    id: 'att${attSeq++}',
    profileId: p10.id,
    fileName: 'Bien_ban_hoa_giai.docx',
    type: AttachmentType.docx,
    localPathOrUrl: 'demo_assets/bien_ban_hoa_giai.docx',
    sizeBytes: 52000,
    createdAt: daysAgo(30),
    updatedAt: daysAgo(30),
  ));

  // =======================================================================
  // 11. Trịnh Văn Bình — Khác — ĐÃ HỦY
  // =======================================================================
  final p11 = Profile(
    id: 'p11',
    groupId: 'g4',
    fullName: 'Trịnh Văn Bình',
    phone: '0877222333',
    workTarget: 'Làm thủ tục thừa kế nhà đất',
    description: 'Khách hàng rút hồ sơ do gia đình tự thỏa thuận được.',
    startDate: daysAgo(50),
    deadline: daysAgo(20),
    hasDeadline: true,
    status: ProfileStatus.cancelled,
    totalAmount: 10000000,
    note: 'Đã hoàn lại tiền tạm ứng cho khách.',
    createdAt: daysAgo(50),
    updatedAt: daysAgo(22),
  );
  profiles.add(p11);
  stages.addAll(makeStages(
    p11.id,
    [StageStatus.completed, StageStatus.skipped, StageStatus.skipped, StageStatus.skipped, StageStatus.skipped],
    baseStart: daysAgo(50),
  ));
  transactions.addAll([
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p11.id,
      type: TransactionType.received,
      amount: 3000000,
      date: daysAgo(50),
      note: 'Tạm ứng ban đầu',
      createdAt: daysAgo(50),
    ),
    MoneyTransaction(
      id: 't${txSeq++}',
      profileId: p11.id,
      type: TransactionType.expense,
      amount: 3000000,
      date: daysAgo(22),
      note: 'Hoàn lại tiền tạm ứng cho khách (hủy hồ sơ)',
      createdAt: daysAgo(22),
    ),
  ]);

  return DemoSeedBundle(
    groups: groups,
    profiles: profiles,
    stages: stages,
    milestones: milestones,
    transactions: transactions,
    collaborators: collaborators,
    assignments: assignments,
    attachments: attachments,
  );
}
