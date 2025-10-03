import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:html' as html;
import 'package:universal_platform/universal_platform.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({
    super.key,
    required int requestId,
    required String requestTitle,
  });

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _loading = false;
  List<dynamic> _userList = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchUserList();
  }

  Future<void> _fetchUserList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("http://localhost:3000/UserList/list");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "page": _currentPage,
          "limit": _limit,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _userList = data;
          _hasNextPage = data.length == _limit;
        });
      } else {
        print("Failed to fetch: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error fetching list: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> user) async {
    if (user["uploadFile"] == null || user["uploadFile"].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available for download")),
      );
      return;
    }

    try {
      final url = "http://localhost:3000/UserList/download/${user["id"]}";

      if (UniversalPlatform.isWeb) {
        html.AnchorElement anchorElement = html.AnchorElement(href: url);
        anchorElement.download = "user_file_${user["id"]}";
        anchorElement.click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloaded")),
        );
      } else {
        final dio = Dio();
        final response = await dio.get(url,
            options: Options(responseType: ResponseType.bytes));

        if (response.statusCode == 200) {
          final bytes = response.data as List<int>;
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/user_file_${user["id"]}.pdf');
          await file.writeAsBytes(bytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded to ${file.path}")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  void _openDetails(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailsScreen(
          user: user,
          onDownload: () => _downloadFile(user),
        ),
      ),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserFormScreen(onSubmit: _fetchUserList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("User List"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _userList.isEmpty
              ? const Center(child: Text("No Users found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _userList.length,
                        itemBuilder: (context, index) {
                          final user = _userList[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                user["clientName"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text("Client ID: ${user["clientId"] ?? ""}"),
                                  Text("Portal: ${user["portal"] ?? ""}"),
                                  Text("Replace: ${user["replace"] ?? ""}"),
                                  if (user["uploadFile"] != null)
                                    Text("📎 File attached",
                                        style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (user["uploadFile"] != null)
                                    IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.blue, size: 20),
                                      onPressed: () => _downloadFile(user),
                                      tooltip: "Download File",
                                    ),
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                                ],
                              ),
                              onTap: () =>
                                  _openDetails(Map<String, dynamic>.from(user)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.small(
                            heroTag: "prevPage",
                            backgroundColor: Colors.blue,
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() => _currentPage--);
                                    _fetchUserList();
                                  }
                                : null,
                            child: const Icon(Icons.chevron_left,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "Page $_currentPage",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton.small(
                            heroTag: "nextPage",
                            backgroundColor: Colors.blue,
                            onPressed: _hasNextPage
                                ? () {
                                    setState(() => _currentPage++);
                                    _fetchUserList();
                                  }
                                : null,
                            child: const Icon(Icons.chevron_right,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF009688),
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDownload;
  const UserDetailsScreen({super.key, required this.user, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Details"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if (user["uploadFile"] != null && onDownload != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: onDownload,
              tooltip: "Download File",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: user.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                title: Text(entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(entry.value?.toString() ?? ""),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class UserFormScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const UserFormScreen({super.key, required this.onSubmit});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientIdController = TextEditingController();
  String _portal = "iCloud";
  String _replace = "No";
  bool _loading = false;
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'xlsx'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'clientName': _clientNameController.text.trim(),
        'clientId': _clientIdController.text.trim(),
        'portal': _portal,
        'replace': _replace,
      });

      if (_selectedFile != null && _selectedFile!.bytes != null) {
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            _selectedFile!.bytes!,
            filename: _selectedFile!.name,
          ),
        ));
      }

      final response = await dio.post(
        "http://localhost:3000/UserList/create",
        data: formData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User created successfully")),
        );
        widget.onSubmit();
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadTemplate() async {
    const templateUrl =
        "https://riotain-my.sharepoint.com/:x:/g/personal/bhavyashree_riota_in/EW8d1ss9tl1JprY04C9j_yIBOIeL_0eVcgNw-Qf4BawomQ?e=JFonuX";

    try {
      if (UniversalPlatform.isWeb) {
        final anchor = html.AnchorElement(href: templateUrl)
          ..download = "Template.xlsx"
          ..target = "_blank";
        anchor.click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Template download started...")),
        );
      } else {
        final dio = Dio();
        final response = await dio.get(
          templateUrl,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File("${dir.path}/Template.xlsx");
          await file.writeAsBytes(response.data);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded to ${file.path}")),
          );
        } else {
          throw "Failed with status: ${response.statusCode}";
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Request"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: "Client Name *"),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Client Name is required"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(labelText: "Client ID *"),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Client ID is required"
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _portal,
                decoration: const InputDecoration(labelText: "Portal"),
                items: const [
                  DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                  DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                ],
                onChanged: (val) => setState(() => _portal = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _replace,
                decoration: const InputDecoration(labelText: "Replace"),
                items: const [
                  DropdownMenuItem(value: "Yes", child: Text("Yes")),
                  DropdownMenuItem(value: "No", child: Text("No")),
                ],
                onChanged: (val) => setState(() => _replace = val!),
              ),
              const SizedBox(height: 20),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  title: const Text("Upload File",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: _selectedFile != null
                      ? Text(" ${_selectedFile!.name}")
                      : const Text("No file selected"),
                  trailing: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Choose"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text("Download Template"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                      ),
                      onPressed: _submit,
                      child: const Text("Submit"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
