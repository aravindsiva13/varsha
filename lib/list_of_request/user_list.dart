

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import 'package:path_provider/path_provider.dart';
import 'package:req_man/config.dart';
import 'dart:io';
import 'dart:html' as html;
import 'package:universal_platform/universal_platform.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

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
      print("\n=== Fetching User List ===");
      print("Page: $_currentPage, Limit: $_limit");

      final url = Uri.parse(
          "${ApiConfig.getBaseUrl()}/UserList/list?page=$_currentPage&limit=$_limit");

      print("Request URL: $url");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData is Map && responseData.containsKey('data')) {
          final List<dynamic> data = responseData['data'] ?? [];
          final pagination = responseData['pagination'] ?? {};

          print("Received ${data.length} records");
          print("Pagination: $pagination");

          setState(() {
            _userList = data;
            _hasNextPage = (pagination['currentPage'] ?? _currentPage) <
                (pagination['totalPages'] ?? 1);
          });
        } else if (responseData is List) {
          print("Received ${responseData.length} records (old format)");

          setState(() {
            _userList = responseData;
            _hasNextPage = responseData.length == _limit;
          });
        } else {
          print("Unexpected response format");
          throw Exception("Unexpected response format");
        }
      } else {
        print("Failed with status: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch: ${response.statusCode}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error fetching list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
      print("=== Fetch Complete ===\n");
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
      final url = "${ApiConfig.getBaseUrl()}/UserList/download/${user["id"]}";

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
    ).then((_) => _fetchUserList());
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
// UserDetailsScreen with Edit and Delete
class UserDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDownload;
  const UserDetailsScreen({super.key, required this.user, this.onDownload});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientNameController;
  late TextEditingController _clientIdController;
  late String _portal;
  late String _replace;
  bool _isEditMode = false;
  bool _isSubmitting = false;
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;

  bool get isExisting => widget.user.isNotEmpty && widget.user["id"] != null;

  @override
  void initState() {
    super.initState();
    _portal = widget.user["portal"]?.toString() ?? "iCloud";
    _replace = widget.user["replace"]?.toString() ?? "No";
    _clientNameController =
        TextEditingController(text: widget.user["clientName"]?.toString() ?? "");
    _clientIdController =
        TextEditingController(text: widget.user["clientId"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFileWeb() async {
    try {
      print("Opening HTML file picker for web...");

      final html.FileUploadInputElement input = html.FileUploadInputElement()
        ..accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg,.xlsx,.xls'
        ..multiple = false;

      html.document.body?.append(input);
      input.click();

      print("Waiting for file selection...");

      await input.onChange.first.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print("File selection timeout");
          throw TimeoutException("File selection timeout");
        },
      );

      print("File selection event received");

      if (input.files != null && input.files!.isNotEmpty) {
        final html.File file = input.files!.first;

        print("File selected via HTML picker:");
        print("  - Name: ${file.name}");
        print("  - Size: ${file.size} bytes");
        print("  - Type: ${file.type}");

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        print("Reading file data...");
        await reader.onLoad.first;

        final Uint8List fileBytes = reader.result as Uint8List;

        print("File bytes loaded: ${fileBytes.length} bytes");

        setState(() {
          _pickedFileBytes = fileBytes;
          _pickedFileName = file.name;
        });

        input.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "File selected: ${file.name} (${(file.size / 1024).toStringAsFixed(2)} KB)"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        print("No file selected");
        input.remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No file selected"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("HTML file picker error: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickFileNative() async {
    try {
      print("Opening native file picker...");

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'png',
          'jpg',
          'jpeg',
          'xlsx',
          'xls'
        ],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        print("File selected: ${file.name}");

        if (file.bytes != null && file.bytes!.isNotEmpty) {
          setState(() {
            _pickedFileBytes = file.bytes;
            _pickedFileName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File selected: ${file.name}"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Native file picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    if (kIsWeb) {
      await _pickFileWeb();
    } else {
      await _pickFileNative();
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      print("\n=== Starting User List Update ===");
      print("Picked file name: $_pickedFileName");
      print("Picked file bytes: ${_pickedFileBytes?.length ?? 0} bytes");

      final dio = Dio();

      final formData = FormData.fromMap({
        'clientName': _clientNameController.text.trim(),
        'clientId': _clientIdController.text.trim(),
        'portal': _portal,
        'replace': _replace,
        if (isExisting) 'id': widget.user["id"]?.toString(),
      });

      if (_pickedFileBytes != null && _pickedFileName != null) {
        print("📎 Adding file to FormData: $_pickedFileName");
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            _pickedFileBytes!,
            filename: _pickedFileName!,
          ),
        ));
        print("File added to FormData successfully");
      } else {
        print("No new file to upload");
      }

      print("Sending request to server...");
      final url = isExisting
          ? "${ApiConfig.getBaseUrl()}/UserList/update"
          : "${ApiConfig.getBaseUrl()}/UserList/create";

      final response = await dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Success!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isExisting
                ? "User updated successfully"
                : "User created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        throw Exception("Unexpected status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
      print("=== Submit Complete ===\n");
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Confirm Delete"),
              content:
                  const Text("Are you sure you want to delete this user?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.red))),
              ],
            ));
    if (confirmed != true) return;

    try {
      final dio = Dio();
      final url =
          "${ApiConfig.getBaseUrl()}/UserList/delete/${widget.user["id"]}";
      final response = await dio.delete(url);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Deleted successfully")));
        Navigator.pop(context);
      } else {
        throw Exception("Delete failed: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Delete failed: $e")));
    }
  }

  Widget _readonlyCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? "-" : value),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isExisting ? "User Details" : "New User"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if ((isExisting && !_isEditMode && widget.user["uploadFile"] != null) ||
              (_pickedFileName != null && widget.onDownload != null))
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: widget.onDownload,
              tooltip: "Download File",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isEditMode
            ? Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                        controller: _clientNameController,
                        decoration: _inputDecoration("Client Name *"),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Client Name is required"
                            : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _clientIdController,
                        decoration: _inputDecoration("Client ID *"),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Required";
                          final regex = RegExp(r'^[a-zA-Z0-9]+$');
                          return regex.hasMatch(v.trim())
                              ? null
                              : "Alphanumeric only";
                        }),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _portal,
                      decoration: const InputDecoration(
                        labelText: "Portal",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                        DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                      ],
                      onChanged: (val) => setState(() => _portal = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _replace,
                      decoration: const InputDecoration(
                        labelText: "Replace",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Yes", child: Text("Yes")),
                        DropdownMenuItem(value: "No", child: Text("No")),
                      ],
                      onChanged: (val) => setState(() => _replace = val!),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Upload File",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_pickedFileName != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Selected: $_pickedFileName",
                                        style: TextStyle(
                                          color: Colors.green.shade900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _pickedFileName = null;
                                          _pickedFileBytes = null;
                                        });
                                      },
                                      tooltip: "Remove file",
                                    ),
                                  ],
                                ),
                              )
                            else if (widget.user["uploadFile"] != null)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.attach_file,
                                        color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Current file attached",
                                        style: TextStyle(
                                          color: Colors.blue.shade900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Text(
                                "No file selected",
                                style: TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file),
                              label: Text(_pickedFileName != null
                                  ? "Change File"
                                  : "Choose File"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009688),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(isExisting ? "Update" : "Save"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: _submit,
                          ),
                  ],
                ),
              )
            : ListView(
                children: [
                  _readonlyCard("Client Name", _clientNameController.text),
                  _readonlyCard("Client ID", _clientIdController.text),
                  _readonlyCard("Portal", _portal),
                  _readonlyCard("Replace", _replace),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      title: const Text("Uploaded File",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.user["uploadFile"]?.toString() ??
                          "No file uploaded"),
                      trailing: widget.user["uploadFile"] != null
                          ? IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: widget.onDownload,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Edit"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () =>
                                setState(() => _isEditMode = true)),
                      ),
                      const SizedBox(width: 16),
                      if (isExisting)
                        Expanded(
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              label: const Text("Delete"),
                              onPressed: _delete),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// UserFormScreen - keeping original implementation
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
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  Future<void> _pickFileWeb() async {
    try {
      print("Opening HTML file picker for web...");

      final html.FileUploadInputElement input = html.FileUploadInputElement()
        ..accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg,.xlsx,.xls'
        ..multiple = false;

      html.document.body?.append(input);
      input.click();

      print("Waiting for file selection...");

      await input.onChange.first.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print("File selection timeout");
          throw TimeoutException("File selection timeout");
        },
      );

      print("File selection event received");

      if (input.files != null && input.files!.isNotEmpty) {
        final html.File file = input.files!.first;

        print("File selected via HTML picker:");
        print("  - Name: ${file.name}");
        print("  - Size: ${file.size} bytes");
        print("  - Type: ${file.type}");

        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);

        print("Reading file data...");
        await reader.onLoad.first;

        final Uint8List fileBytes = reader.result as Uint8List;

        print("File bytes loaded: ${fileBytes.length} bytes");

        setState(() {
          _selectedFileBytes = fileBytes;
          _selectedFileName = file.name;
        });

        input.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "File selected: ${file.name} (${(file.size / 1024).toStringAsFixed(2)} KB)"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        print("No file selected");
        input.remove();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No file selected"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print("HTML file picker error: $e");
      print("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _pickFileNative() async {
    try {
      print("Opening native file picker...");

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'png',
          'jpg',
          'jpeg',
          'xlsx',
          'xls'
        ],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        print("File selected: ${file.name}");

        if (file.bytes != null && file.bytes!.isNotEmpty) {
          setState(() {
            _selectedFileBytes = file.bytes;
            _selectedFileName = file.name;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("File selected: ${file.name}"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print("Native file picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickFile() async {
    if (kIsWeb) {
      await _pickFileWeb();
    } else {
      await _pickFileNative();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      print("\n=== Starting User List Submit ===");
      print("Selected file name: $_selectedFileName");
      print("Selected file bytes: ${_selectedFileBytes?.length ?? 0} bytes");

      final dio = Dio();

      final formData = FormData.fromMap({
        'clientName': _clientNameController.text.trim(),
        'clientId': _clientIdController.text.trim(),
        'portal': _portal,
        'replace': _replace,
      });

      if (_selectedFileBytes != null && _selectedFileName != null) {
        print("📎 Adding file to FormData: $_selectedFileName");
        formData.files.add(MapEntry(
          'file',
          MultipartFile.fromBytes(
            _selectedFileBytes!,
            filename: _selectedFileName!,
          ),
        ));
        print("File added to FormData successfully");
      } else {
        print("No file to upload");
      }

      print("Sending request to server...");
      final response = await dio.post(
        "${ApiConfig.getBaseUrl()}/UserList/create",
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print("Response status: ${response.statusCode}");
      print("Response data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Success!");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmit();
        Navigator.pop(context);
      } else {
        throw Exception("Unexpected status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
      print("=== Submit Complete ===\n");
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final url = "${ApiConfig.getBaseUrl()}/downloadTemplate/download";

      if (UniversalPlatform.isWeb) {
        html.AnchorElement anchorElement = html.AnchorElement(href: url);
        anchorElement.download = "sample_user";
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
          final file = File('${dir.path}/sample_user.xlsx');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New User Request"),
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
                decoration: const InputDecoration(
                  labelText: "Client Name *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? "Client Name is required"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: "Client ID *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Required";
                  final regex = RegExp(r'^[a-zA-Z0-9]+$');
                  return regex.hasMatch(v.trim()) ? null : "Alphanumeric only";
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _portal,
                decoration: const InputDecoration(
                  labelText: "Portal",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                  DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                ],
                onChanged: (val) => setState(() => _portal = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _replace,
                decoration: const InputDecoration(
                  labelText: "Replace",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Yes", child: Text("Yes")),
                  DropdownMenuItem(value: "No", child: Text("No")),
                ],
                onChanged: (val) => setState(() => _replace = val!),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Upload File",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_selectedFileName != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Selected: $_selectedFileName",
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _selectedFileName = null;
                                    _selectedFileBytes = null;
                                  });
                                },
                                tooltip: "Remove file",
                              ),
                            ],
                          ),
                        )
                      else
                        const Text(
                          "No file selected",
                          style: TextStyle(color: Colors.grey),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_selectedFileName != null
                            ? "Change File"
                            : "Choose File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text("Download Template"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}





