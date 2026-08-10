import 'package:internsfe/domain/entities/activity_item.dart';
import 'package:internsfe/domain/entities/uploaded_file.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';

/// Maps app content to share/delete API types.
class ShareableItem {
  const ShareableItem({
    required this.deleteType,
    this.shareType,
    this.resourceId,
    this.companyName,
    this.query,
    this.requiresSensitiveConfirm = false,
    this.label,
  });

  final String deleteType;
  final ShareResourceType? shareType;
  final String? resourceId;
  final String? companyName;
  final String? query;
  final bool requiresSensitiveConfirm;
  final String? label;

  factory ShareableItem.fromActivity(ActivityItem item) {
    final targetId = item.targetId;
    switch (item.type) {
      case 'resume':
      case 'scan':
        return ShareableItem(
          deleteType: 'activity',
          shareType: ShareResourceType.scan,
          resourceId: targetId,
          requiresSensitiveConfirm: true,
          label: item.title,
        );
      case 'offer':
        return ShareableItem(
          deleteType: 'activity',
          shareType: ShareResourceType.offerCheck,
          resourceId: targetId,
          requiresSensitiveConfirm: true,
          label: item.title,
        );
      case 'company':
        return ShareableItem(
          deleteType: 'activity',
          shareType: ShareResourceType.companyVerify,
          companyName: item.subtitle.isNotEmpty ? item.subtitle : item.title,
          label: item.title,
        );
      case 'blacklist':
        return ShareableItem(
          deleteType: 'activity',
          shareType: ShareResourceType.blacklist,
          query: item.subtitle.isNotEmpty ? item.subtitle : item.title,
          label: item.title,
        );
      case 'data_safety':
        return ShareableItem(
          deleteType: 'activity',
          shareType: ShareResourceType.dataSafety,
          resourceId: targetId,
          label: item.title,
        );
      default:
        return ShareableItem(
          deleteType: 'activity',
          resourceId: item.id,
          label: item.title,
        );
    }
  }

  factory ShareableItem.fromUpload(UploadedFile file) {
    return ShareableItem(
      deleteType: 'file',
      shareType: ShareResourceType.upload,
      resourceId: file.id,
      requiresSensitiveConfirm: true,
      label: file.fileName,
    );
  }
}
