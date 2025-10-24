const String apiBaseUrl = "http://localhost:3008";
// print("sdfsdf");

class ApiConfig {
  static String getBaseUrl() {
    // if (Uri.base.origin.contains("localhost")) {
    //   return apiBaseUrl;
    // } else {
    // return "${Uri.base.origin}/api";
    return apiBaseUrl;
    // }
  }
}
