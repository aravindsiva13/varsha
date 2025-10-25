
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:req_man/config.dart';

class CloudAccessScreen extends StatefulWidget {
  const CloudAccessScreen({
    super.key,
    required this.requestId,
    required this.requestTitle,
  });

  final int requestId;
  final String requestTitle;

  @override
  State<CloudAccessScreen> createState() => _CloudAccessScreenState();
}

class _CloudAccessScreenState extends State<CloudAccessScreen> {
  bool _loading = false;
  List<dynamic> _cloudList = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchCloudList();
  }

  Future<void> _fetchCloudList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          "${ApiConfig.getBaseUrl()}/cloudAccess/list?page=$_currentPage&limit=$_limit");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cloudList = data;
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

  void _openDetails(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CloudAccessDetailsScreen(item: item),
      ),
    ).then((_) => _fetchCloudList());
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CloudAccessFormScreen(onSubmit: _fetchCloudList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("Cloud Access"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _cloudList.isEmpty
              ? const Center(child: Text("No Cloud Access requests found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cloudList.length,
                        itemBuilder: (context, index) {
                          final item = _cloudList[index];
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
                                item["createRoleName"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text("Portal: ${item["portal"] ?? ""}"),
                                  Text("Action: ${item["roleAction"] ?? ""}"),
                                ],
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () =>
                                  _openDetails(Map<String, dynamic>.from(item)),
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
                                    _fetchCloudList();
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
                                    _fetchCloudList();
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

class CloudAccessDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const CloudAccessDetailsScreen({super.key, required this.item});

  @override
  State<CloudAccessDetailsScreen> createState() =>
      _CloudAccessDetailsScreenState();
}

class _CloudAccessDetailsScreenState extends State<CloudAccessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roleNameController;
  late TextEditingController _descController;
  late String _portal;
  late String _roleAction;
  bool _isEditMode = false;
  bool _isSubmitting = false;

  bool get isExisting => widget.item.isNotEmpty && widget.item["id"] != null;

  @override
  void initState() {
    super.initState();
    _portal = widget.item["portal"]?.toString() ?? "iCloud";
    _roleAction = widget.item["roleAction"]?.toString() ?? "Create";
    _roleNameController = TextEditingController(
        text: widget.item["createRoleName"]?.toString() ?? "");
    _descController =
        TextEditingController(text: widget.item["description"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = Dio();
      final data = {
        'portal': _portal,
        'roleAction': _roleAction,
        'createRoleName': _roleNameController.text,
        'description': _descController.text,
        if (isExisting) 'id': widget.item["id"]?.toString(),
      };

      final url = isExisting
          ? "${ApiConfig.getBaseUrl()}/cloudAccess/update"
          : "${ApiConfig.getBaseUrl()}/cloudAccess/create";

      final response = await dio.post(url, data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                isExisting ? "Updated successfully" : "Created successfully")));
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Confirm Delete"),
              content: const Text(
                  "Are you sure you want to delete this Cloud Access record?"),
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
          "${ApiConfig.getBaseUrl()}/cloudAccess/delete/${widget.item["id"]}";
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
        title: Text(isExisting ? "Cloud Access Details" : "New Cloud Access"),
        backgroundColor: const Color(0xFF009688),
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
                      value: _roleAction,
                      decoration: const InputDecoration(
                        labelText: "Role Action",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Create", child: Text("Create")),
                        DropdownMenuItem(value: "Update", child: Text("Update")),
                      ],
                      onChanged: (val) => setState(() => _roleAction = val!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _roleNameController,
                        decoration: _inputDecoration("Role Name *"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: _inputDecoration("Description"),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(isExisting ? "Update" : "Save"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _submit,
                          ),
                  ],
                ),
              )
            : ListView(
                children: [
                  _readonlyCard("Portal", _portal),
                  _readonlyCard("Role Action", _roleAction),
                  _readonlyCard("Role Name", _roleNameController.text),
                  _readonlyCard("Description", _descController.text),
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

class CloudAccessFormScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const CloudAccessFormScreen({super.key, required this.onSubmit});

  @override
  State<CloudAccessFormScreen> createState() => _CloudAccessFormScreenState();
}

class _CloudAccessFormScreenState extends State<CloudAccessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleNameController = TextEditingController();
  final _descController = TextEditingController();

  String _portalName = "iCloud";
  String _roleAction = "Create";
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = {
      "portal": _portalName,
      "roleAction": _roleAction,
      "createRoleName": _roleNameController.text,
      "description": _descController.text,
    };

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.getBaseUrl()}/cloudAccess/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloud Access created successfully")),
        );
        widget.onSubmit();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Cloud Access"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _portalName,
                decoration: const InputDecoration(
                  labelText: "Portal Name",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                  DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _portalName = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _roleAction,
                decoration: const InputDecoration(
                  labelText: "Role Action (Create/Update)",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Create", child: Text("Create")),
                  DropdownMenuItem(value: "Update", child: Text("Update")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _roleAction = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleNameController,
                decoration: const InputDecoration(
                  labelText: "Role Name *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Role Name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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