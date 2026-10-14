import '../../models/models.dart';

enum SmartPasteStatus { recognized, review, unresolved }

class SmartPasteField {
  const SmartPasteField({
    required this.sourceLabel,
    required this.rawValue,
    required this.status,
    this.fieldId,
    this.fieldLabel,
    this.value,
    this.message,
  });

  final String sourceLabel;
  final String rawValue;
  final SmartPasteStatus status;
  final String? fieldId;
  final String? fieldLabel;
  final String? value;
  final String? message;
}

class SmartPasteResult {
  const SmartPasteResult(this.items);
  final List<SmartPasteField> items;

  Map<String, String> get applicableValues => {
    for (final item in items)
      if (item.status == SmartPasteStatus.recognized &&
          item.fieldId != null &&
          item.value != null)
        item.fieldId!: item.value!,
  };
}

class _TargetField {
  const _TargetField({
    required this.id,
    required this.label,
    required this.type,
    required this.order,
    this.options = const [],
  });
  final String id;
  final String label;
  final ProfileFieldType type;
  final int order;
  final List<CustomFieldOption> options;
}

/// Deterministic, local-only parser for information copied from documents or
/// messages. It deliberately prefers leaving a line for review over guessing.
class ProfileSmartPasteParser {
  const ProfileSmartPasteParser();

  static const _aliases = <String, List<String>>{
    'fullName': ['ho ten', 'ten', 'ho va ten', 'fullname'],
    'dateOfBirth': [
      'ngay sinh',
      'sinh ngay',
      'ngay thang nam sinh',
      'ns',
      'dob',
    ],
    'citizenId': [
      'cccd',
      'cmnd',
      'so cccd',
      'can cuoc',
      'can cuoc cong dan',
      'so can cuoc',
    ],
    'phone': ['sdt', 'dien thoai', 'so dien thoai', 'phone'],
    'rank': ['cap bac', 'quan ham'],
    'position': ['chuc vu', 'cv'],
    'unit': ['don vi', 'dv'],
    'enlistment': ['nhap ngu', 'nam nhap ngu'],
    'hometown': ['que quan', 'que'],
    'currentResidence': [
      'noi o hien nay',
      'noi o',
      'noi o hien tai',
      'cho o hien nay',
      'dia chi hien nay',
    ],
    'educationLevel': ['trinh do', 'trinh do hoc van'],
    'specialty': ['chuyen nganh'],
    'schoolHistory': ['qua truong', 'truong da hoc'],
    'officerRating': ['xep loai can bo', 'xep loai'],
    'fatherFullName': ['ho ten bo', 'ho va ten bo', 'ten bo'],
    'fatherBirthYear': ['nam sinh bo', 'bo sinh nam'],
    'fatherOccupation': ['nghe nghiep bo'],
    'fatherHometown': ['que quan bo'],
    'fatherCurrentResidence': ['noi o hien nay cua bo', 'noi o cua bo'],
    'motherFullName': ['ho ten me', 'ho va ten me', 'ten me'],
    'motherBirthYear': ['nam sinh me', 'me sinh nam'],
    'motherOccupation': ['nghe nghiep me'],
    'motherHometown': ['que quan me'],
    'motherCurrentResidence': ['noi o hien nay cua me', 'noi o cua me'],
    'workTarget': [
      'muc tieu',
      'noi dung cong viec',
      'muc tieu noi dung cong viec',
    ],
    'description': ['mo ta', 'yeu cau', 'mo ta yeu cau'],
    'note': ['ghi chu'],
    'aspiration1': ['nguyen vong 1', 'nv1', 'nguyen vong thu nhat'],
    'aspiration2': ['nguyen vong 2', 'nv2'],
    'aspiration3': ['nguyen vong 3', 'nv3'],
  };

  SmartPasteResult parse(String input, WorkGroup group) {
    final targets = _targets(group);
    final items = <SmartPasteField>[];
    final used = <String>{};
    var sourceOrder = 0;
    for (final pair in _blocks(input)) {
      final label = pair.$1;
      final raw = pair.$2;
      if (label.isEmpty) {
        items.add(
          SmartPasteField(
            sourceLabel: raw,
            rawValue: '',
            status: SmartPasteStatus.unresolved,
            message: 'Không nhận ra nhãn và giá trị',
          ),
        );
        continue;
      }
      final matches = _matches(label, targets, sourceOrder);
      sourceOrder++;
      if (matches.isEmpty) {
        items.add(
          SmartPasteField(
            sourceLabel: label,
            rawValue: raw,
            status: SmartPasteStatus.unresolved,
            message: 'Không có trường phù hợp trong Nhóm',
          ),
        );
        continue;
      }
      final best = matches.first;
      final tied = matches.length > 1 && matches[1].$2 == best.$2;
      if (tied || used.contains(best.$1.id)) {
        items.add(
          SmartPasteField(
            sourceLabel: label,
            rawValue: raw,
            status: SmartPasteStatus.review,
            fieldId: best.$1.id,
            fieldLabel: best.$1.label,
            message: tied
                ? 'Nhãn có nhiều kết quả tương đương'
                : 'Trường xuất hiện nhiều lần',
          ),
        );
        continue;
      }
      final converted = _convert(raw, best.$1);
      if (converted.$1 == null) {
        items.add(
          SmartPasteField(
            sourceLabel: label,
            rawValue: raw,
            status: SmartPasteStatus.review,
            fieldId: best.$1.id,
            fieldLabel: best.$1.label,
            message: converted.$2,
          ),
        );
        continue;
      }
      used.add(best.$1.id);
      items.add(
        SmartPasteField(
          sourceLabel: label,
          rawValue: raw,
          status: SmartPasteStatus.recognized,
          fieldId: best.$1.id,
          fieldLabel: best.$1.label,
          value: converted.$1,
        ),
      );
    }
    return SmartPasteResult(items);
  }

  List<(String, String)> _blocks(String input) {
    final result = <(String, String)>[];
    String? label;
    final valueLines = <String>[];
    void flush() {
      if (label != null) result.add((label!, valueLines.join('\n').trim()));
      label = null;
      valueLines.clear();
    }

    for (final original in input.replaceAll('\r\n', '\n').split('\n')) {
      final line = original.trim();
      if (line.isEmpty || _isTemplateHeader(line)) continue;
      final pair = _split(line);
      if (pair != null) {
        flush();
        label = pair.$1;
        if (pair.$2.isNotEmpty) valueLines.add(pair.$2);
      } else if (label != null) {
        valueLines.add(line);
      } else {
        result.add(('', line));
      }
    }
    flush();
    return result;
  }

  bool _isTemplateHeader(String line) {
    final value = _normalize(line);
    return value == 'thong tin ho so' ||
        value == 'trich ngang' ||
        value.startsWith('vui long dien cac thong tin duoi day');
  }

  List<_TargetField> _targets(WorkGroup group) {
    final result = <_TargetField>[];
    for (final config in group.effectiveFieldConfigs.where((c) => c.enabled)) {
      final builtIn = ProfileFieldCatalog.byId(config.fieldId);
      CustomFieldDefinition? custom;
      for (final definition in group.customFieldDefinitions) {
        if (definition.id == config.fieldId) custom = definition;
      }
      if (builtIn == null && (custom == null || !custom.active)) continue;
      result.add(
        _TargetField(
          id: config.fieldId,
          label: builtIn?.labelVi ?? custom!.label,
          type: builtIn?.type ?? custom!.type,
          order: config.order,
          options: custom?.options.where((o) => o.active).toList() ?? const [],
        ),
      );
    }
    return result;
  }

  (String, String)? _split(String line) {
    final cleaned = line
        .replaceFirst(RegExp(r'^(?:(?:[\s•*\-–—]+)|(?:\d+[.)]\s*))+'), '')
        .trim();
    final match = RegExp(r'^(.{1,80}?)(?:\s*[:：=]\s*|\s+[\-–—]\s+)(.*)$')
        .firstMatch(cleaned);
    if (match == null) return null;
    final label = match.group(1)!.trim();
    final value = match.group(2)!.trim();
    if (label.isEmpty) return null;
    return (label, value);
  }

  List<(_TargetField, int, int)> _matches(
    String source,
    List<_TargetField> targets,
    int sourceOrder,
  ) {
    final key = _normalize(source);
    final candidates = <(_TargetField, int, int)>[];
    for (final target in targets) {
      final names = <String>{_normalize(target.label), ...?_aliases[target.id]};
      var score = 999;
      for (final name in names) {
        if (key == name) {
          score = 0;
          break;
        }
        final distance = _levenshtein(key, name);
        final limit = name.length <= 6 ? 1 : (name.length <= 14 ? 2 : 3);
        if (distance <= limit && distance < score) score = distance + 10;
      }
      if (score < 999) {
        candidates.add((target, score, (target.order - sourceOrder).abs()));
      }
    }
    candidates.sort((a, b) {
      final byScore = a.$2.compareTo(b.$2);
      return byScore != 0 ? byScore : a.$3.compareTo(b.$3);
    });
    return candidates;
  }

  (String?, String?) _convert(String raw, _TargetField field) {
    final value = raw.trim();
    switch (field.type) {
      case ProfileFieldType.date:
        final m = RegExp(r'^(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4})$')
            .firstMatch(value);
        if (m == null) return (null, 'Ngày phải có dạng dd/MM/yyyy');
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        final year = int.parse(m.group(3)!);
        final date = DateTime(year, month, day);
        if (date.day != day || date.month != month || date.year != year) {
          return (null, 'Ngày không hợp lệ');
        }
        return (
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}',
          null,
        );
      case ProfileFieldType.year:
        final year = int.tryParse(value);
        if (year == null || value.length != 4) {
          return (null, 'Năm không hợp lệ');
        }
        return (year.toString(), null);
      case ProfileFieldType.number:
        return num.tryParse(value.replaceAll(',', '.')) == null
            ? (null, 'Số không hợp lệ')
            : (value.replaceAll(',', '.'), null);
      case ProfileFieldType.boolean:
        final normalized = _normalize(value);
        if (const {'co', 'yes', 'true', '1', 'x'}.contains(normalized)) {
          return ('true', null);
        }
        if (const {'khong', 'no', 'false', '0'}.contains(normalized)) {
          return ('false', null);
        }
        return (null, 'Chỉ chấp nhận Có hoặc Không');
      case ProfileFieldType.singleSelect:
        final key = _normalize(value);
        final exact = field.options
            .where((o) => _normalize(o.label) == key)
            .toList();
        if (exact.length == 1) return (exact.single.id, null);
        if (exact.length > 1) return (null, 'Khớp nhiều lựa chọn');
        final fuzzy = <(CustomFieldOption, int)>[];
        for (final option in field.options) {
          final optionKey = _normalize(option.label);
          final distance = _levenshtein(key, optionKey);
          final limit = optionKey.length <= 6 ? 1 : 2;
          if (distance <= limit) fuzzy.add((option, distance));
        }
        fuzzy.sort((a, b) => a.$2.compareTo(b.$2));
        if (fuzzy.length == 1 ||
            (fuzzy.length > 1 && fuzzy.first.$2 < fuzzy[1].$2)) {
          return (fuzzy.first.$1.id, null);
        }
        return (
          null,
          fuzzy.isEmpty ? 'Không khớp lựa chọn nào' : 'Khớp nhiều lựa chọn',
        );
      case ProfileFieldType.text:
      case ProfileFieldType.multiline:
        return (value, null);
    }
  }

  String _normalize(String value) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var result = value.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  int _levenshtein(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = <int>[i + 1];
      for (var j = 0; j < b.length; j++) {
        current.add(
          [
            current[j] + 1,
            previous[j + 1] + 1,
            previous[j] + (a[i] == b[j] ? 0 : 1),
          ].reduce((x, y) => x < y ? x : y),
        );
      }
      previous = current;
    }
    return previous.last;
  }
}
