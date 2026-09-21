import 'attachment.dart';
import 'collaborator.dart';
import 'collaborator_assignment.dart';
import 'milestone.dart';
import 'money_transaction.dart';
import 'profile.dart';
import 'task_item.dart';
import 'timeline_event.dart';
import 'work_group.dart';
import 'work_stage.dart';

class ExportSnapshot {
  ExportSnapshot({
    required this.exportedAt,
    required this.appVersion,
    required this.sourceMode,
    required this.repositoryRevision,
    required List<WorkGroup> groups,
    required List<Profile> profiles,
    required List<WorkStage> stages,
    required List<Milestone> milestones,
    required List<TaskItem> tasks,
    required List<TimelineEvent> timelineEvents,
    required List<MoneyTransaction> transactions,
    required List<Collaborator> collaborators,
    required List<CollaboratorAssignment> collaboratorAssignments,
    required List<Attachment> attachments,
  }) : groups = List.unmodifiable(groups),
       profiles = List.unmodifiable(profiles),
       stages = List.unmodifiable(stages),
       milestones = List.unmodifiable(milestones),
       tasks = List.unmodifiable(tasks),
       timelineEvents = List.unmodifiable(timelineEvents),
       transactions = List.unmodifiable(transactions),
       collaborators = List.unmodifiable(collaborators),
       collaboratorAssignments = List.unmodifiable(collaboratorAssignments),
       attachments = List.unmodifiable(attachments);

  final DateTime exportedAt;
  final String appVersion;
  final String sourceMode;
  final int repositoryRevision;
  final List<WorkGroup> groups;
  final List<Profile> profiles;
  final List<WorkStage> stages;
  final List<Milestone> milestones;
  final List<TaskItem> tasks;
  final List<TimelineEvent> timelineEvents;
  final List<MoneyTransaction> transactions;
  final List<Collaborator> collaborators;
  final List<CollaboratorAssignment> collaboratorAssignments;
  final List<Attachment> attachments;

  Map<String, int> get recordCounts => {
    'groups': groups.length,
    'profiles': profiles.length,
    'stages': stages.length,
    'milestones': milestones.length,
    'tasks': tasks.length,
    'timelineEvents': timelineEvents.length,
    'transactions': transactions.length,
    'collaborators': collaborators.length,
    'collaboratorAssignments': collaboratorAssignments.length,
    'attachments': attachments.length,
  };
}
