abstract class ContentRepository {
  Future<void> deleteContent({
    required String contentType,
    required String contentId,
  });
}
