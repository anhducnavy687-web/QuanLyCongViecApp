import 'package:flutter/material.dart';

import '../../../widgets/attachment_section.dart';
import '../../../widgets/profile_timeline_section.dart';

class ProfileDocumentsHistoryTab extends StatelessWidget {
  const ProfileDocumentsHistoryTab({super.key, required this.profileId});
  final String profileId;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          AttachmentSection(profileId: profileId),
          const SizedBox(height: 12),
          ProfileTimelineSection(profileId: profileId),
        ],
      ),
    ),
  );
}
