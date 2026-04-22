abstract interface class WebFetchDatasource {
  Future<String> fetch({required String url});
}
