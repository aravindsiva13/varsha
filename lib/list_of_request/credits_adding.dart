import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:html' as html;
import 'package:universal_platform/universal_platform.dart';

class CreditsListScreen extends StatefulWidget {
  const CreditsListScreen(
      {super.key, required int requestId, required String requestTitle});

  @override
  State<CreditsListScreen> createState() => _CreditsListScreenState();
}

class _CreditsListScreenState extends State<CreditsListScreen> {
  bool _loading = false;
  List<dynamic> _credits = [];
  int _currentPage = 1;
  final int _limit = 10;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  Future<void> _fetchList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse("http://localhost:3000/CreditsAdding/list");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _credits = data;
          _hasNextPage = data.length == _limit;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
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
          "http://localhost:3000/CreditsAdding/download/${credit["id"]}";

      if (UniversalPlatform.isWeb) {
        html.AnchorElement anchorElement = html.AnchorElement(href: url);
        anchorElement.download = "credit_file_${credit["id"]}";
        anchorElement.click();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download started")),
        );
      } else {
        final dio = Dio();
        final response = await dio.get(url,
            options: Options(responseType: ResponseType.bytes));

        if (response.statusCode == 200) {
          final bytes = response.data as List<int>;
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/credit_file_${credit["id"]}.pdf');
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

  void _openDetails(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditsDetailsScreen(
            item: item, onDownload: () => _downloadFile(item)),
      ),
    );
  }

  void _openForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CreditsFormScreen(onSubmit: _fetchList)),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        itemCount: _credits.length,
                        itemBuilder: (context, index) {
                          final c = _credits[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                c['clientName'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text("Client ID: ${c['clientId'] ?? ''}"),
                                  Text("Portal: ${c['portal'] ?? ''}"),
                                  Text(
                                      "Credits: ${c['credits']?.toString() ?? ''}"),
                                  if (c["uploadFile"] != null)
                                    Text("File attached",
                                        style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Download button directly in list
                                  if (c["uploadFile"] != null)
                                    IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.blue, size: 20),
                                      onPressed: () => _downloadFile(c),
                                      tooltip: "Download File",
                                    ),
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                                ],
                              ),
                              onTap: () =>
                                  _openDetails(Map<String, dynamic>.from(c)),
                            ),
                          );
                        },
                      ),
                    ),
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
                                    _fetchList();
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
                                    _fetchList();
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
  final Map<String, dynamic> item;
  final VoidCallback? onDownload;
  const CreditsDetailsScreen({super.key, required this.item, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Credits Details"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if (item["uploadFile"] != null && onDownload != null)
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
          children: item.entries.map((e) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                title: Text(e.key,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(e.value?.toString() ?? ""),
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
  String _portal = "iCloud";
  String? _resetInterval;
  final _creditsController = TextEditingController();
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
    if (_resetInterval == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Select Reset Interval")));
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'clientName': _clientNameController.text.trim(),
        'clientId': _clientIdController.text.trim(),
        'portal': _portal,
        'creditsResetInterval': _resetInterval,
        'addInitialBalance': 'No',
        'creditsType': 'Standard',
        'credits': _creditsController.text.trim(),
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
        "http://localhost:3000/CreditsAdding/create",
        data: formData,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credits created successfully")),
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
        title: const Text("New Credits"),
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientIdController,
                decoration: const InputDecoration(labelText: "Client ID *"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _portal,
                decoration: const InputDecoration(labelText: "Portal"),
                items: const [
                  DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                  DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                ],
                onChanged: (v) => setState(() => _portal = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _resetInterval,
                decoration:
                    const InputDecoration(labelText: "Reset Interval *"),
                items: const [
                  DropdownMenuItem(value: "Monthly", child: Text("Monthly")),
                  DropdownMenuItem(value: "Daily", child: Text("Daily")),
                  DropdownMenuItem(
                      value: "Quarterly", child: Text("Quarterly")),
                  DropdownMenuItem(value: "Yearly", child: Text("Yearly")),
                ],
                onChanged: (v) => setState(() => _resetInterval = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _creditsController,
                decoration: const InputDecoration(labelText: "Credits *"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
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
                      ? Text("📎 ${_selectedFile!.name}")
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text("Download Template"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 9, 162, 180),
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
