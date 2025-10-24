import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:login_signup/config.dart';

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
    );
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

class OnboardingDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> onboarding;
  const OnboardingDetailsScreen({super.key, required this.onboarding});

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
    final filteredData = _filterFields(onboarding);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Onboarding Details"),
        backgroundColor: const Color(0xFF009688),
        centerTitle: true,
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
