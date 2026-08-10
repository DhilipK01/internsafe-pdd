import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/domain/entities/activity_item.dart';

/// Opens the premium report viewer for a history activity row.
void openHistoryReport(BuildContext context, ActivityItem item) {
  context.push(AppRoutes.historyDetail(item.id));
}

/// Opens the report viewer for an uploaded file.
void openUploadReport(BuildContext context, String fileId) {
  context.push(AppRoutes.uploadDetail(fileId));
}

/// Opens analysis by resource id (scan, offer, activity, or file).
void openAnalysisReport(BuildContext context, String id) {
  context.push(AppRoutes.analysisDetail(id));
}
