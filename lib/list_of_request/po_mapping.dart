import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:universal_platform/universal_platform.dart';
import 'dart:html' as html;

class PoMappingScreen extends StatefulWidget {
  const PoMappingScreen({
    super.key,
    required this.requestId,
    required this.requestTitle,
  });

  final int requestId;
  final String requestTitle;

  @override
  State<PoMappingScreen> createState() => _PoMappingScreenState();
}

class _PoMappingScreenState extends State<PoMappingScreen> {
  bool _loading = false;
  List<dynamic> _poList = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchPoList();
  }

  Future<void> _fetchPoList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          "http://localhost:3000/poMapping/list?page=$_currentPage&limit=$_limit");

      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Fetched PO data: $data"); // Debug log
        final pagination = data['pagination'] ?? {};
        setState(() {
          _poList = data['data'] ?? [];
          _totalPages = pagination['totalPages'] ?? 1;
          _hasNextPage = pagination['currentPage'] < pagination['totalPages'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching list: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadFile(
      Map<String, dynamic> po, BuildContext context) async {
    print("Calling _downloadFile with po: $po");
    final id = po["id"] as int?;
    final filePath = po["uploadFile"] as String?;
    if (id == null || filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available or invalid ID")),
      );
      print("Download failed: id=$id, filePath=$filePath");
      return;
    }
    try {
      final dio = Dio();
      final url = "http://localhost:3000/poMapping/download/$id";
      print("Attempting download from: $url");
      final response = await dio.get(url,
          options: Options(responseType: ResponseType.bytes));
      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileName = path.basename(filePath.replaceAll('\\', '/'));
        if (UniversalPlatform.isWeb) {
          final blob = html.Blob([bytes]);
          final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: downloadUrl)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(downloadUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download started: $fileName")),
          );
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final savePath = '${dir.path}/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded to $savePath")),
          );
        }
      } else {
        throw Exception("Download failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  void _openMandatory(Map<String, dynamic> po) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PoFormScreen(po: po),
      ),
    );
  }

  void _openNewPo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PoDetailsScreen(po: {}),
      ),
    ).then((_) => _fetchPoList());
  }

  void _changePage(int i) {
    setState(() {
      _currentPage += i;
      if (_currentPage < 1) _currentPage = 1;
    });
    _fetchPoList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("PO Mapping"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _poList.isEmpty
              ? const Center(child: Text("No PO requests found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _poList.length,
                        itemBuilder: (context, index) {
                          final po = _poList[index];
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
                                po["clientName"]?.toString() ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Text("Portal: ${po["portal"] ?? ""}"),
                                  Text(
                                      "Machine ID: ${po["machineId"]?.toString() ?? ""}"),
                                  Text(
                                      "Expiry Date: ${po["expiryPoDate"]?.toString() ?? ""}"),
                                  if (po["uploadFile"] != null &&
                                      po["uploadFile"].toString().isNotEmpty)
                                    Text("📎 File attached",
                                        style: TextStyle(
                                            color: Colors.green.shade600,
                                            fontSize: 12)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (po["uploadFile"] != null &&
                                      po["uploadFile"].toString().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.blue, size: 20),
                                      onPressed: () =>
                                          _downloadFile(po, context),
                                      tooltip: "Download File",
                                    ),
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                                ],
                              ),
                              onTap: () =>
                                  _openMandatory(Map<String, dynamic>.from(po)),
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
                                    _fetchPoList();
                                  }
                                : null,
                            child: const Icon(Icons.chevron_left,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "Page $_currentPage of $_totalPages",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton.small(
                            heroTag: "nextPage",
                            backgroundColor: Colors.blue,
                            onPressed: _hasNextPage
                                ? () {
                                    setState(() => _currentPage++);
                                    _fetchPoList();
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
        onPressed: _openNewPo,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PoDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> po;
  const PoDetailsScreen({super.key, required this.po});

  @override
  State<PoDetailsScreen> createState() => _PoDetailsScreenState();
}

class _PoDetailsScreenState extends State<PoDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _portal = "iCloud";

  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientMailController;
  late TextEditingController _clientAddressController;
  late TextEditingController _branchController;
  late TextEditingController _machineIdController;
  late TextEditingController _expiryDateController;

  String? _pickedFileName;
  String? _pickedFilePath;

  late File localFile;
  Uint8List? pickedFileBytes;
  String? pickedFileName;
  bool _isSubmitting = false;

  bool get isEditMode => widget.po.isNotEmpty && widget.po["id"] != null;

  @override
  void initState() {
    super.initState();
    _clientNameController =
        TextEditingController(text: widget.po["clientName"]?.toString() ?? "");
    _clientPhoneController = TextEditingController(
        text: widget.po["clientPhoneNumber"]?.toString() ?? "");
    _clientMailController = TextEditingController(
        text: widget.po["clientMailId"]?.toString() ?? "");
    _clientAddressController = TextEditingController(
        text: widget.po["clientAddress"]?.toString() ?? "");
    _branchController =
        TextEditingController(text: widget.po["branch"]?.toString() ?? "");
    _machineIdController =
        TextEditingController(text: widget.po["machineId"]?.toString() ?? "");
    _expiryDateController = TextEditingController(
        text: widget.po["expiryPoDate"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientMailController.dispose();
    _clientAddressController.dispose();
    _branchController.dispose();
    _machineIdController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      pickedFileBytes = result.files.single.bytes;
      pickedFileName = result.files.single.name;
      setState(() {});
    }
  }

  Future<void> _downloadFile(BuildContext context) async {
    final po = widget.po;
    print("Calling _downloadFile with po: $po");
    if (!isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download available only in edit mode")),
      );
      return;
    }
    final id = po["id"] as int?;
    final filePath = isEditMode ? po["uploadFile"] as String? : _pickedFileName;
    if (id == null || filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available or invalid ID")),
      );
      print("Download failed: id=$id, filePath=$filePath");
      return;
    }
    try {
      final dio = Dio();
      final url = "http://localhost:3000/poMapping/download/$id";
      print("Attempting download from: $url");
      final response = await dio.get(url,
          options: Options(responseType: ResponseType.bytes));
      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileName = path.basename(filePath.replaceAll('\\', '/'));
        if (UniversalPlatform.isWeb) {
          final blob = html.Blob([bytes]);
          final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: downloadUrl)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(downloadUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download started: $fileName")),
          );
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final savePath = '${dir.path}/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded to $savePath")),
          );
        }
      } else {
        throw Exception("Download failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        if (pickedFileBytes != null && pickedFileName != null)
          'file': MultipartFile.fromBytes(pickedFileBytes!,
              filename: pickedFileName!),
        'clientName': _clientNameController.text,
        'clientPhoneNumber': _clientPhoneController.text,
        'clientMailId': _clientMailController.text,
        'clientAddress': _clientAddressController.text,
        'branch': _branchController.text,
        'machineId': _machineIdController.text,
        'expiryPoDate': _expiryDateController.text,
        'portal': _portal,
        if (isEditMode) 'id': widget.po["id"]?.toString(),
      });
      final url = isEditMode
          ? "http://localhost:3000/poMapping/update"
          : "http://localhost:3000/poMapping/create";
      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEditMode
                  ? "Updated successfully"
                  : "Created successfully")),
        );
        Navigator.pop(context);
      } else {
        throw Exception(response.data['error'] ?? 'Unknown error');
      }
    } on DioException catch (e) {
      String errorMsg = 'Operation failed';
      if (e.response?.data['error'] != null) {
        errorMsg = e.response!.data['error'];
      } else if (e.message != null) {
        errorMsg = e.message!;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to ${isEditMode ? 'update' : 'create'}: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Edit PO Mapping" : "New PO Mapping"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              TextFormField(
                controller: _clientNameController,
                decoration: _inputDecoration("Client Name *"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientPhoneController,
                decoration: const InputDecoration(labelText: "Phone Number *"),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Phone Number is required";
                  }
                  final regex = RegExp(r'^[0-9]{10}$');
                  if (!regex.hasMatch(v.trim())) {
                    return "Phone Number must be 10 digits";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientMailController,
                decoration: const InputDecoration(labelText: "Email ID *"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Email ID is required";
                  }
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!regex.hasMatch(v.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientAddressController,
                decoration: _inputDecoration("Client Address"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _branchController,
                decoration: _inputDecoration("Branch"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _machineIdController,
                decoration: _inputDecoration("Machine ID *"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiryDateController,
                decoration: _inputDecoration("Expiry Date of PO *"),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.tryParse(_expiryDateController.text) ??
                            DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _expiryDateController.text =
                        "${picked.day}/${picked.month}/${picked.year}";
                  }
                },
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
                  subtitle: pickedFileName != null
                      ? Text("📎 $pickedFileName")
                      : (isEditMode && widget.po["uploadFile"] != null
                          ? Text("📎 Current: ${widget.po["uploadFile"]}")
                          : const Text("No file selected")),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditMode && widget.po["uploadFile"] != null)
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue),
                          onPressed: () => _downloadFile(context),
                          tooltip: "Download Current File",
                        ),
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Choose"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pickedFileName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_pickedFileName!),
                ),
              const SizedBox(height: 20),
              _isSubmitting
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                      ),
                      onPressed: _submit,
                      child: Text(isEditMode ? "Update" : "Submit"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class PoFormScreen extends StatelessWidget {
  final Map<String, dynamic> po;
  const PoFormScreen({super.key, required this.po});

  Widget _readonlyCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value.isEmpty ? "-" : value),
      ),
    );
  }

  Future<void> _downloadFile(int? id, BuildContext context) async {
    print("Calling _downloadFile with po: $po");
    if (id == null ||
        po["uploadFile"] == null ||
        (po["uploadFile"] as String).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available or invalid ID")),
      );
      print("Download failed: id=$id, filePath=${po["uploadFile"]}");
      return;
    }
    try {
      final dio = Dio();
      final url = "http://localhost:3000/poMapping/download/$id";
      print("Attempting download from: $url");
      final response = await dio.get(url,
          options: Options(responseType: ResponseType.bytes));
      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        final fileName =
            path.basename((po["uploadFile"] as String).replaceAll('\\', '/'));
        if (UniversalPlatform.isWeb) {
          final blob = html.Blob([bytes]);
          final downloadUrl = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: downloadUrl)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(downloadUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download started: $fileName")),
          );
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final savePath = '${dir.path}/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Downloaded to $savePath")),
          );
        }
      } else {
        throw Exception("Download failed with status ${response.statusCode}");
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mandatory PO Mapping"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if (po["uploadFile"] != null &&
              po["uploadFile"].toString().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _downloadFile(po["id"] as int?, context),
              tooltip: "Download File",
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _readonlyCard("Client Name", po["clientName"]?.toString() ?? ""),
            _readonlyCard("Client Phone Number",
                po["clientPhoneNumber"]?.toString() ?? ""),
            _readonlyCard(
                "Client Mail ID", po["clientMailId"]?.toString() ?? ""),
            _readonlyCard(
                "Client Address", po["clientAddress"]?.toString() ?? ""),
            _readonlyCard("Branch", po["branch"]?.toString() ?? ""),
            _readonlyCard("Machine ID", po["machineId"]?.toString() ?? ""),
            _readonlyCard(
                "Expiry Date of PO", po["expiryPoDate"]?.toString() ?? ""),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                title: const Text("Uploaded File",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: po["uploadFile"] != null &&
                        po["uploadFile"].toString().isNotEmpty
                    ? Text("📎 ${po["uploadFile"].toString()}")
                    : const Text("No file uploaded"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
