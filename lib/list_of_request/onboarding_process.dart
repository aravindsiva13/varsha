


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:req_man/config.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen(
      {super.key, required int requestId, required String requestTitle});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _loading = false;
  List<dynamic> _onboardingList = [];
  int _currentPage = 1;
  final int _limit = 5;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchOnboardingList();
  }

  Future<void> _fetchOnboardingList() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse(
          "${ApiConfig.getBaseUrl()}/OnboardingMid/list?page=$_currentPage&limit=$_limit");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _onboardingList = data;
          _hasNextPage = data.length == _limit;
        });
      } else {
        debugPrint("Failed to fetch: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching onboarding list: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openDetails(Map<String, dynamic> onboarding) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingDetailsScreen(onboarding: onboarding),
      ),
    ).then((_) => _fetchOnboardingList());
  }

  void _openForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingFormScreen(onSubmit: _fetchOnboardingList),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF009688),
        title: const Text("Onboarding"),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _onboardingList.isEmpty
              ? const Center(
                  child: Text(
                    "No Onboarding Records found",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _onboardingList.length,
                        itemBuilder: (context, index) {
                          final ob = _onboardingList[index];

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ob["displayName"] ??
                                        ob["display_name"] ??
                                        "No Name",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Email: ${ob["clientMailId"] ?? ob["client_mail_id"] ?? ""}",
                                  ),
                                  Text(
                                    "Phone: ${ob["clientPhoneNumber"] ?? ob["client_phone_number"] ?? ""}",
                                  ),
                                  Text(
                                    "MID: ${ob["MID"] ?? ""}",
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => _openDetails(
                                          Map<String, dynamic>.from(ob)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16, top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.small(
                            heroTag: "prevPage",
                            backgroundColor: _currentPage > 1
                                ? Colors.blue
                                : Colors.grey.shade400,
                            onPressed: _currentPage > 1
                                ? () {
                                    setState(() => _currentPage--);
                                    _fetchOnboardingList();
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
                            backgroundColor: _hasNextPage
                                ? Colors.blue
                                : Colors.grey.shade400,
                            onPressed: _hasNextPage
                                ? () {
                                    setState(() => _currentPage++);
                                    _fetchOnboardingList();
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

class OnboardingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> onboarding;
  const OnboardingDetailsScreen({super.key, required this.onboarding});

  @override
  State<OnboardingDetailsScreen> createState() =>
      _OnboardingDetailsScreenState();
}

class _OnboardingDetailsScreenState extends State<OnboardingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _midController;
  bool _isEditMode = false;
  bool _isSubmitting = false;

  bool get isExisting =>
      widget.onboarding.isNotEmpty && widget.onboarding["id"] != null;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
        text: widget.onboarding["displayName"]?.toString() ??
            widget.onboarding["display_name"]?.toString() ??
            "");
    _emailController = TextEditingController(
        text: widget.onboarding["clientMailId"]?.toString() ??
            widget.onboarding["client_mail_id"]?.toString() ??
            "");
    _phoneController = TextEditingController(
        text: widget.onboarding["clientPhoneNumber"]?.toString() ??
            widget.onboarding["client_phone_number"]?.toString() ??
            "");
    _midController = TextEditingController(
        text: widget.onboarding["MID"]?.toString() ?? "");
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _midController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = Dio();
      final data = {
        'displayName': _displayNameController.text,
        'clientPhoneNumber': _phoneController.text,
        'clientMailId': _emailController.text,
        'MID': _midController.text,
        if (isExisting) 'id': widget.onboarding["id"]?.toString(),
      };

      final url = isExisting
          ? "${ApiConfig.getBaseUrl()}/OnboardingMid/update"
          : "${ApiConfig.getBaseUrl()}/OnboardingMid/create";

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
                  "Are you sure you want to delete this Onboarding record?"),
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
          "${ApiConfig.getBaseUrl()}/OnboardingMid/delete/${widget.onboarding["id"]}";
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
        title: Text(isExisting ? "Onboarding Details" : "New Onboarding"),
        backgroundColor: const Color(0xFF009688),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isEditMode
            ? Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                        controller: _displayNameController,
                        decoration: _inputDecoration("Display Name *"),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? "Required" : null),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration("Email ID *"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Required";
                        final regex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        return regex.hasMatch(v.trim())
                            ? null
                            : "Enter a valid email";
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration("Phone Number *"),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Required";
                        final regex = RegExp(r'^[0-9]{10}$');
                        return regex.hasMatch(v.trim())
                            ? null
                            : "Must be 10 digits";
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _midController,
                      decoration: _inputDecoration("MID *"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Required";
                        final regex = RegExp(r'^[a-zA-Z0-9]+$');
                        return regex.hasMatch(v.trim())
                            ? null
                            : "Alphanumeric only";
                      },
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
                  _readonlyCard("Display Name", _displayNameController.text),
                  _readonlyCard("Email ID", _emailController.text),
                  _readonlyCard("Phone Number", _phoneController.text),
                  _readonlyCard("MID", _midController.text),
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

class OnboardingFormScreen extends StatefulWidget {
  final VoidCallback onSubmit;
  const OnboardingFormScreen({super.key, required this.onSubmit});

  @override
  State<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends State<OnboardingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _midController = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = {
      "displayName": _displayNameController.text.trim(),
      "clientPhoneNumber": _phoneController.text.trim(),
      "clientMailId": _emailController.text.trim(),
      "MID": _midController.text.trim(),
    };

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.getBaseUrl()}/OnboardingMid/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Onboarding created successfully")),
        );
        widget.onSubmit();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Onboarding Request"),
        backgroundColor: const Color(0xFF009688),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: "Display Name *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email ID *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Required";
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return regex.hasMatch(v.trim())
                      ? null
                      : "Enter a valid email";
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Phone Number *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Required";
                  final regex = RegExp(r'^[0-9]{10}$');
                  return regex.hasMatch(v.trim()) ? null : "Must be 10 digits";
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _midController,
                decoration: const InputDecoration(
                  labelText: "MID *",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Required";
                  final regex = RegExp(r'^[a-zA-Z0-9]+$');
                  return regex.hasMatch(v.trim()) ? null : "Alphanumeric only";
                },
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