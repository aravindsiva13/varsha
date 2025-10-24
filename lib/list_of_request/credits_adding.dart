import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:login_signup/config.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:html' as html;
import 'package:universal_platform/universal_platform.dart';

class CreditsListScreen extends StatefulWidget {
  const CreditsListScreen({
    super.key,
    required int requestId,
    required String requestTitle,
  });

  @override
  State<CreditsListScreen> createState() => _CreditsListScreenState();
}

class _CreditsListScreenState extends State<CreditsListScreen> {
  bool _loading = false;
  List<dynamic> _credits = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchCreditsList();
  }

  Future<void> _fetchCreditsList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("${ApiConfig.getBaseUrl()}/CreditsAdding/list");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "page": _currentPage,
          "limit": _limit,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pagination = data['pagination'] ?? {};

        setState(() {
          _credits = data['data'] ?? [];
          _hasNextPage = pagination['currentPage'] < pagination['totalPages'];
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

  Future<void> _downloadFile(Map<String, dynamic> credit) async {
    if (credit["uploadFile"] == null ||
        credit["uploadFile"].toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available for download")),
      );
      return;
    }

    try {
      final url =
          "${ApiConfig.getBaseUrl()}/CreditsAdding/download/${credit["id"]}";

      if (UniversalPlatform.isWeb) {
        html.AnchorElement anchorElement = html.AnchorElement(href: url);
        anchorElement.download = "credits_file_${credit["id"]}";
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
          final file = File('${dir.path}/credits_file_${credit["id"]}.pdf');
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

  void _openDetails(Map<String, dynamic> credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditsDetailsScreen(
          credit: credit,
          onDownload: () => _downloadFile(credit),
        ),
      ),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditsFormScreen(onSubmit: _fetchCreditsList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("Credits Adding"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _credits.isEmpty
              ? const Center(child: Text("No credits found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _credits.length,
                        itemBuilder: (context, index) {
                          final credit = _credits[index];
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
                                credit["clientName"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text(
                                      "Client ID: ${credit["clientId"] ?? ""}"),
                                  Text("Portal: ${credit["portal"] ?? ""}"),
                                  Text(
                                      "Credit Reset Interval: ${credit["creditsResetInterval"] ?? ""}"),
                                  Text(
                                      "Add Initial Balance: ${credit["addInitialBalance"] ?? ""}"),
                                  Text(
                                      "Credits Type: ${credit["creditsType"] ?? ""}"),
                                  Text(
                                      "Credits: ${credit["credits"]?.toString() ?? ""}"),
                                  if (credit["uploadFile"] != null)
                                    Text("📎 File attached",
                                        style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (credit["uploadFile"] != null)
                                    IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.blue, size: 20),
                                      onPressed: () => _downloadFile(credit),
                                      tooltip: "Download File",
                                    ),
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                                ],
                              ),
                              onTap: () => _openDetails(
                                  Map<String, dynamic>.from(credit)),
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
                                    _fetchCreditsList();
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
                                    _fetchCreditsList();
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

class CreditsDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> credit;
  final VoidCallback? onDownload;
  const CreditsDetailsScreen(
      {super.key, required this.credit, this.onDownload});

  Map<String, dynamic> _filterFields(Map<String, dynamic> data) {
    final filtered = Map<String, dynamic>.from(data);

    filtered.remove('created_at');
    filtered.remove('updated_at');
    filtered.remove('createdAt');
    filtered.remove('updatedAt');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filterFields(credit);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Credits Details"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if (credit["uploadFile"] != null && onDownload != null)
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
          children: credit.entries.map((entry) {
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

class CreditsFormScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const CreditsFormScreen({super.key, required this.onSubmit});

  @override
  State<CreditsFormScreen> createState() => _CreditsFormScreenState();
}

class _CreditsFormScreenState extends State<CreditsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _creditsController = TextEditingController();
  final _creditsTypeController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  String _portal = "iCloud";
  String? _resetInterval;
  String? _addInitialBalance;

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _loading = false;

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
        print("  - Size: ${file.size} bytes");

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
        } else {
          print("File bytes are null");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to read file data"),
              backgroundColor: Colors.red,
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
    if (_resetInterval == null || _addInitialBalance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      print("\n=== Starting Submit ===");
      print("Selected file name: $_selectedFileName");
      print("Selected file bytes: ${_selectedFileBytes?.length ?? 0} bytes");

      final dio = Dio();

      final formData = FormData.fromMap({
        'clientName': _clientNameController.text.trim(),
        'clientId': int.tryParse(_clientIdController.text.trim()) ?? 0,
        'portal': _portal,
        'creditsResetInterval': _resetInterval!,
        'addInitialBalance': _addInitialBalance!,
        'creditsType': _creditsTypeController.text.trim(),
        'credits': int.tryParse(_creditsController.text.trim()) ?? 0,
        'initialBalance': _addInitialBalance == "Yes"
            ? int.tryParse(_initialBalanceController.text.trim()) ?? 0
            : 0,
      });

      if (_selectedFileBytes != null && _selectedFileName != null) {
        print(
            "📎 Adding file to FormData: $_selectedFileName (${_selectedFileBytes!.length} bytes)");
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
        "${ApiConfig.getBaseUrl()}/CreditsAdding/create",
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
            content: Text("Credits created successfully"),
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
    // const templateUrl =
    //     "https://riotain-my.sharepoint.com/:x:/g/personal/bhavyashree_riota_in/EW8d1ss9tl1JprY04C9j_yIBOIeL_0eVcgNw-Qf4BawomQ?e=JFonuX";

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
        title: const Text("Add Credits"),
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
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter Client Name" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(
                  labelText: "Client ID *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter Client ID" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _portal,
                items: ["iCloud", "eCloud"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _portal = v!),
                decoration: const InputDecoration(
                  labelText: "Portal",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _resetInterval,
                items: ["Monthly", "Daily", "Quarterly", "Yearly"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _resetInterval = v),
                decoration: const InputDecoration(
                  labelText: "Credit Reset Interval *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? "Select an interval" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _addInitialBalance,
                items: ["Yes", "No"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _addInitialBalance = v),
                decoration: const InputDecoration(
                  labelText: "Add Initial Balance *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? "Select an option" : null,
              ),
              const SizedBox(height: 12),
              if (_addInitialBalance == "Yes")
                TextFormField(
                  controller: _initialBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Initial Balance *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter Initial Balance" : null,
                ),
              if (_addInitialBalance == "Yes") const SizedBox(height: 12),
              TextFormField(
                controller: _creditsTypeController,
                decoration: const InputDecoration(
                  labelText: "Credits Type *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter Credits Type" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Credits *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter Credits" : null,
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
