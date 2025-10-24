import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:login_signup/config.dart';

class MachineAccessScreen extends StatefulWidget {
  const MachineAccessScreen(
      {super.key, required int requestId, required String requestTitle});

  @override
  State<MachineAccessScreen> createState() => _MachineAccessScreenState();
}

class _MachineAccessScreenState extends State<MachineAccessScreen> {
  bool _loading = false;
  List<dynamic> _machineList = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchMachineList();
  }

  Future<void> _fetchMachineList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          "${ApiConfig.getBaseUrl()}/machineAccess/list?page=$_currentPage&limit=$_limit");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _machineList = data;
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

  void _openDetails(Map<String, dynamic> machine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MachineDetailsScreen(machine: machine),
      ),
    );
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MachineFormScreen(onSubmit: _fetchMachineList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("Machine Access"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _machineList.isEmpty
              ? const Center(child: Text("No machine records found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _machineList.length,
                        itemBuilder: (context, index) {
                          final machine = _machineList[index];
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
                                machine["clientName"] ?? "",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Text("MID: ${machine["machineId"] ?? ""}"),
                                  Text("Portal: ${machine["portal"] ?? ""}"),
                                  Text(
                                      "userRole: ${machine["userRole"] ?? ""}"),
                                ],
                              ),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 18),
                              onTap: () => _openDetails(
                                  Map<String, dynamic>.from(machine)),
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
                                    _fetchMachineList();
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
                                    _fetchMachineList();
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

class MachineDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> machine;
  const MachineDetailsScreen({super.key, required this.machine});

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
    final filteredData = _filterFields(machine);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Machine Details"),
        backgroundColor: const Color(0xFF009688),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: filteredData.entries.map((entry) {
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

class MachineFormScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const MachineFormScreen({super.key, required this.onSubmit});

  @override
  State<MachineFormScreen> createState() => _MachineFormScreenState();
}

class _MachineFormScreenState extends State<MachineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _machineIdController = TextEditingController();
  String _portal = "iCloud";
  String _userRole = "Admin";
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = {
      "clientName": _clientNameController.text,
      "machineId": _machineIdController.text,
      "portal": _portal,
      "userRole": _userRole,
    };

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.getBaseUrl()}/machineAccess/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Machine Access created successfully")),
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
        title: const Text("New Machine Access"),
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
                validator: (v) => v!.isEmpty ? "Client Name is required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _machineIdController,
                decoration: const InputDecoration(labelText: "Machine ID *"),
                validator: (v) => v!.isEmpty ? "Machine ID is required" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _portal,
                decoration: const InputDecoration(labelText: "Portal *"),
                items: const [
                  DropdownMenuItem(value: "iCloud", child: Text("iCloud")),
                  DropdownMenuItem(value: "eCloud", child: Text("eCloud")),
                ],
                onChanged: (val) => setState(() => _portal = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _userRole,
                decoration: const InputDecoration(labelText: "User Role *"),
                items: const [
                  DropdownMenuItem(value: "Admin", child: Text("Admin")),
                  DropdownMenuItem(
                      value: "Super Admin", child: Text("Super Admin")),
                  DropdownMenuItem(value: "Refiller", child: Text("Refiller")),
                ],
                onChanged: (val) => setState(() => _userRole = val!),
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
