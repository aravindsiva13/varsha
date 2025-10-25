import 'dart:io';
import 'dart:typed_data';
import 'package:req_man/config.dart';
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
          "${ApiConfig.getBaseUrl()}/poMapping/list?page=$_currentPage&limit=$_limit");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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

  void _openPoDetails(Map<String, dynamic> po) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PoDetailsScreen(po: po)),
    ).then((_) => _fetchPoList());
  }

  void _openNewPo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PoDetailsScreen(po: {})),
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
                                    Text(" File attached",
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
                                  _openPoDetails(Map<String, dynamic>.from(po)),
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

  Future<void> _downloadFile(
      Map<String, dynamic> po, BuildContext context) async {
    final id = po["id"] as int?;
    final filePath = po["uploadFile"] as String?;
    if (id == null || filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file available")),
      );
      return;
    }
    try {
      final dio = Dio();
      final url = "${ApiConfig.getBaseUrl()}/poMapping/download/$id";
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
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final savePath = '${dir.path}/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Downloaded to $savePath")));
        }
      } else {
        throw Exception("Download failed: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
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
  late TextEditingController _clientNameController;
  late TextEditingController _clientPhoneController;
  late TextEditingController _clientMailController;
  late TextEditingController _clientAddressController;
  late TextEditingController _branchController;
  late TextEditingController _machineIdController;
  late TextEditingController _expiryDateController;
  String _portal = "iCloud";
  Uint8List? _pickedFileBytes;
  String? _pickedFileName;
  bool _isSubmitting = false;
  bool _isEditMode = false;
  bool get isExistingPo => widget.po.isNotEmpty && widget.po["id"] != null;

  @override
  void initState() {
    super.initState();
    _portal = widget.po["portal"]?.toString() ?? "iCloud";
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
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, withData: true);
    if (result != null && result.files.isNotEmpty) {
      _pickedFileBytes = result.files.single.bytes;
      _pickedFileName = result.files.single.name;
      setState(() {});
    }
  }

  Future<void> _downloadFile() async {
    final id = widget.po["id"] as int?;
    final filePath = _isEditMode
        ? _pickedFileName ?? widget.po["uploadFile"]
        : widget.po["uploadFile"];
    if (id == null || filePath == null || filePath.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No file available")));
      return;
    }
    try {
      final dio = Dio();
      final url = "${ApiConfig.getBaseUrl()}/poMapping/download/$id";
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
        } else {
          final dir = await getApplicationDocumentsDirectory();
          final savePath = '${dir.path}/$fileName';
          final file = File(savePath);
          await file.writeAsBytes(bytes);
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Downloaded to $savePath")));
        }
      } else {
        throw Exception("Download failed: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Download failed: $e")));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        if (_pickedFileBytes != null && _pickedFileName != null)
          'file': MultipartFile.fromBytes(_pickedFileBytes!,
              filename: _pickedFileName!),
        'clientName': _clientNameController.text,
        'clientPhoneNumber': _clientPhoneController.text,
        'clientMailId': _clientMailController.text,
        'clientAddress': _clientAddressController.text,
        'branch': _branchController.text,
        'machineId': _machineIdController.text,
        'expiryPoDate': _expiryDateController.text,
        'portal': _portal,
        if (isExistingPo) 'id': widget.po["id"]?.toString(),
      });
      final url = isExistingPo
          ? "${ApiConfig.getBaseUrl()}/poMapping/update"
          : "${ApiConfig.getBaseUrl()}/poMapping/create";
      final response = await dio.post(url, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isExistingPo
                ? "Updated successfully"
                : "Created successfully")));
        Navigator.pop(context);
      } else {
        throw Exception(response.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Operation failed: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deletePo() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Confirm Delete"),
              content: const Text("Are you sure you want to delete this PO?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete")),
              ],
            ));
    if (confirmed != true) return;

    try {
      final dio = Dio();
      final url =
          "${ApiConfig.getBaseUrl()}/poMapping/delete/${widget.po["id"]}";
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
        title: Text(isExistingPo ? "PO Details" : "New PO Mapping"),
        backgroundColor: const Color(0xFF009688),
        actions: [
          if ((isExistingPo && !_isEditMode) || (_pickedFileName != null))
            IconButton(
                icon: const Icon(Icons.download), onPressed: _downloadFile),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isEditMode
            ? Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _portal,
                      decoration: const InputDecoration(labelText: "Portal"),
                      items: const [
                        DropdownMenuItem(
                            value: "iCloud", child: Text("iCloud")),
                        DropdownMenuItem(
                            value: "eCloud", child: Text("eCloud")),
                      ],
                      onChanged: (val) => setState(() => _portal = val!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _clientNameController,
                        decoration: _inputDecoration("Client Name *"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _clientPhoneController,
                        decoration: _inputDecoration("Phone Number *"),
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _clientMailController,
                        decoration: _inputDecoration("Email ID *"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _clientAddressController,
                        decoration: _inputDecoration("Client Address")),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _branchController,
                        decoration: _inputDecoration("Branch")),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _machineIdController,
                        decoration: _inputDecoration("Machine ID *"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _expiryDateController,
                        decoration: _inputDecoration("Expiry PO Date *"),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100));
                          if (picked != null)
                            _expiryDateController.text =
                                DateFormat('yyyy-MM-dd').format(picked);
                        }),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text(_pickedFileName ?? "Pick File"),
                        onPressed: _pickFile),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(isExistingPo ? "Update" : "Save"),
                        onPressed: _submit),
                  ],
                ),
              )
            : ListView(
                children: [
                  _readonlyCard("Portal", _portal),
                  _readonlyCard("Client Name", _clientNameController.text),
                  _readonlyCard("Phone Number", _clientPhoneController.text),
                  _readonlyCard("Email ID", _clientMailController.text),
                  _readonlyCard(
                      "Client Address", _clientAddressController.text),
                  _readonlyCard("Branch", _branchController.text),
                  _readonlyCard("Machine ID", _machineIdController.text),
                  _readonlyCard("Expiry PO Date", _expiryDateController.text),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      title: const Text("Uploaded File",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(widget.po["uploadFile"]?.toString() ??
                          "No file uploaded"),
                      trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: _downloadFile),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit"),
                          onPressed: () => setState(() => _isEditMode = true)),
                      const SizedBox(width: 16),
                      if (isExistingPo)
                        ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            label: const Text("Delete"),
                            onPressed: _deletePo),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
