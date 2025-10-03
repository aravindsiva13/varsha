import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          "http://localhost:3000/cloudAccess/list?page=$_currentPage&limit=$_limit");

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

  void _changePage(int i) {
    setState(() {
      _currentPage += i;
    });
    _fetchCloudList();
  }

  void _openDetails(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CloudAccessDetailsScreen(item: item),
      ),
    );
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
                                item["roleName"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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

class CloudAccessDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  const CloudAccessDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloud Access Details"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: item.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(entry.value?.toString() ?? ""),
              ),
            );
          }).toList(),
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
        Uri.parse("http://localhost:3000/cloudAccess/create"),
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
                decoration: const InputDecoration(labelText: "Portal Name"),
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
                    labelText: "Role Action (Create/Update)"),
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
                decoration: const InputDecoration(labelText: "Role Name *"),
                validator: (v) => v!.isEmpty ? "Role Name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
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
