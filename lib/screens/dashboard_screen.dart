import 'package:flutter/material.dart';
import 'package:req_man/list_of_request/po_mapping.dart';
import 'package:req_man/list_of_request/cloud_management/cloud_access.dart';
import 'package:req_man/list_of_request/user_list.dart';
import 'package:req_man/list_of_request/onboarding_process.dart';
import 'package:req_man/list_of_request/credits_adding.dart';
import 'package:req_man/list_of_request/cloud_management/machine_access.dart';
import 'package:req_man/screens/welcome_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> requests = [
    {"id": 1, "title": "PO Mapping"},
    {"id": 2, "title": "Cloud Access"},
    {"id": 3, "title": "User list"},
    {"id": 4, "title": "Onboarding MID"},
    {"id": 5, "title": "Credits Adding"},
    {"id": 6, "title": "Machine Access"},
  ];

  Widget _getRequestScreen(int id, String title) {
    switch (id) {
      case 1:
        return PoMappingScreen(requestId: id, requestTitle: title);
      case 2:
        return CloudAccessScreen(requestId: id, requestTitle: title);
      case 3:
        return UserListScreen(requestId: id, requestTitle: title);
      case 4:
        return OnboardingScreen(requestId: id, requestTitle: title);
      case 5:
        return CreditsListScreen(requestId: id, requestTitle: title);
      case 6:
        return MachineAccessScreen(requestId: id, requestTitle: title);
      default:
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text("The page for \"$title\" is not implemented yet."),
          ),
        );
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignInScreen(),
                  ),
                  (route) => false,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade700,
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 0, 154, 154),
                  Color.fromARGB(255, 3, 160, 195)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Cloud Admin",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
         
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => _handleLogout(context),
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      "Track your clients, roles & machines",
                      style: TextStyle(
                        color: Colors.black.withOpacity(1.0),
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20.0, 30.0, 20.0, 15.0),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 23, 187, 212),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "List Of Requests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: Colors.teal.withOpacity(0.3),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 20),
                            leading: CircleAvatar(
                              backgroundColor: Colors.teal.shade100,
                              child: Icon(
                                Icons.dashboard_customize,
                                color: Colors.teal.shade800,
                              ),
                            ),
                            title: Text(
                              requests[index]["title"],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => _getRequestScreen(
                                    requests[index]["id"],
                                    requests[index]["title"],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
