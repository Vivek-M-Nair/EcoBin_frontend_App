import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'main.dart';
import 'payment_page.dart';

// --- DEVELOPMENT ISOLATED RUNTIME BADGE ---
void main() => runApp(const TestWorkerApp());

class TestWorkerApp extends StatelessWidget {
  const TestWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CollectionWorkerPage(),
    );
  }
}

class CollectionWorkerPage extends StatefulWidget {
  const CollectionWorkerPage({super.key});

  @override
  State<CollectionWorkerPage> createState() => _CollectionWorkerPageState();
}

class _CollectionWorkerPageState extends State<CollectionWorkerPage> {
  // --- PRODUCTION DEVELOPMENT MODE ROUTER SWITCH ---
  final bool useMockBackend = true;

  // Tracked Operations Datastructure Manifest Model Variables
  final String _assignedWardName = "Ward 14 (Gandhi Nagar)";
  final int _assignedTotalHouseCount = 48;
  String _selectedPaymentVectorOption = "Pay as cash in office counter";
  bool _showCollectionUpdate = false;
  int _workerRating = 0;

  // Mock Notifications loaded dynamically
  final List<String> _notifications = [
    "🚨 ALERT: Route deviation detected near Ward 14.",
    "🌿 INFO: Garbage truck scheduled for maintenance tomorrow morning.",
    "⚠️ WARNING: High wind warnings are currently active for the sector.",
  ];

  // Active Manifest Collection Lists Model Mapping
  final List<Map<String, dynamic>> _houseManifestList = [
    {
      "houseNo": "14/A",
      "owner": "Vivek M Nair",
      "paymentStatus": "Paid",
      "feeAmount": 0,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/B",
      "owner": "Jacob Thomas",
      "paymentStatus": "Pending",
      "feeAmount": 240,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/C",
      "owner": "Jils Tom",
      "paymentStatus": "Paid",
      "feeAmount": 0,
      "collectStatus": "Pending",
    },
    {
      "houseNo": "14/D",
      "owner": "Dr. Varun Nair",
      "paymentStatus": "Pending",
      "feeAmount": 240,
      "collectStatus": "Pending",
    },
  ];

  // Submission Form Reporting Mapping Variables
  final TextEditingController _collectedCountController = TextEditingController(
    text: "46",
  );
  final TextEditingController _cashReceivedController = TextEditingController(
    text: "480",
  );
  final TextEditingController _pendingCountController = TextEditingController(
    text: "2",
  );
  final TextEditingController _pendingReasonController = TextEditingController(
    text: "Gate locked, dog inside properties",
  );
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _incidentReportController =
      TextEditingController();

  // Apply Leave Text Controllers
  final TextEditingController _leaveDateController = TextEditingController();
  final TextEditingController _leaveReasonController = TextEditingController();

  /// Deletes user profile configurations securely across Spring Boot backend services
  Future<void> _deleteAccountBackendCall() async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8081/api/worker/delete-account');
      await http.delete(url);
    } catch (_) {}
  }

  /// Clears active notification streams from cloud database registers
  Future<void> _clearNotificationsBackendCall() async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    try {
      final url = Uri.parse(
        'http://10.0.2.2:8081/api/worker/clear-notifications',
      );
      await http.post(url);
    } catch (_) {}
  }

  /// Submits dynamic worker leave parameters to centralized Spring Boot backend
  Future<void> _submitLeaveToBackend(String date, String reason) async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 800));
      return;
    }
    try {
      final url = Uri.parse('http://10.0.2.2:8081/api/worker/apply-leave');
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'leaveDate': date,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  /// Updates status configurations securely across Spring Boot backend services
  Future<void> _syncCollectionStatusToBackend(
    String houseNo,
    String status, {
    String exceptionReason = "",
  }) async {
    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 600));
      return;
    }
    try {
      final url = Uri.parse(
        'http://10.0.2.2:8081/api/worker/update-collect-status',
      );
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'houseNo': houseNo,
          'collectStatus': status,
          'exceptionReason': exceptionReason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  /// Sends the complete end-of-day revenue, metric balances, and expense reports to the server
  Future<void> _submitDayReportAndExpenses() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Synchronizing operations context data with head office database... 📦',
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );

    if (useMockBackend) {
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      try {
        final url = Uri.parse(
          'http://10.0.2.2:8081/api/worker/submit-route-report',
        );
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'wardName': _assignedWardName,
            'housesCollected': _collectedCountController.text,
            'cashAmountReceived': _cashReceivedController.text,
            'remittanceType': _selectedPaymentVectorOption,
            'pendingUnits': _pendingCountController.text,
            'pendingReason': _pendingReasonController.text,
            'expenseReported': _expenseAmountController.text,
            'incidentLog': _incidentReportController.text,
          }),
        );
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✓ System synchronized! Operational logs committed successfully.',
            style: TextStyle(
              color: Color(0xFF020617),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Displays the interactive profile dialog sheet popup with all native options
  void _openUserProfilePanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Dave R. Profile Context",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            "Verified Crew Lead profile node",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF1E293B)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFF10B981),
                    ),
                    title: const Text(
                      "View Shift Notifications",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "${_notifications.length} active logs found",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    onTap: () {
                      _showNotificationsDialog(context, setPanelState);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_outlined,
                      color: Color(0xFFF43F5E),
                    ),
                    title: const Text(
                      "Request Account Deletion",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDA4AF),
                      ),
                    ),
                    subtitle: const Text(
                      "Permanent removal handshake sequence",
                      style: TextStyle(fontSize: 10, color: Color(0xFFFDA4AF)),
                    ),
                    onTap: () {
                      _showDeleteAccountWarning(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.power_settings_new_rounded,
                      color: Color(0xFF64748B),
                    ),
                    title: const Text(
                      "Log Out securely",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => EcoBinLoginPage(
                            userDashboardScreen: EcoBinHomePage(),
                            workerDashboardScreen: CollectionWorkerPage(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsDialog(
    BuildContext parentContext,
    StateSetter setPanelState,
  ) {
    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppCustomAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Shift Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _clearNotificationsBackendCall();
                      setState(() {
                        _notifications.clear();
                      });
                      setDialogState(() {});
                      setPanelState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Notifications cleared successfully. 🧹",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Clear All",
                      style: TextStyle(
                        color: Color(0xFFF43F5E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 300),
              child: _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        "No new system logs detected.",
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Color(0xFF1E293B)),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _notifications[index],
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountWarning(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Delete Account permanently?",
          style: TextStyle(
            color: Color(0xFFF43F5E),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete the Account permanently? This action cannot be undone and will sever database linkages.",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
            ),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(parentContext);
              await _deleteAccountBackendCall();
              _showSecureDeletionResponseDialog();
            },
            child: const Text(
              "Delete Account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecureDeletionResponseDialog() {
    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Request Submitted",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Your account deletion request has been registered and sent to the server. This request will be checked by our Office.",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF020617),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => EcoBinLoginPage(
                    userDashboardScreen: EcoBinHomePage(),
                    workerDashboardScreen: CollectionWorkerPage(),
                  ),
                ),
              );
            },
            child: const Text(
              "Confirm & Logout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showTodayScheduleDialog() {
    final List<Map<String, String>> previousSectors = [
      {'day': '1 Day Ago', 'area': 'Ward 12 (Subhash Nagar)'},
      {'day': '2 Days Ago', 'area': 'Ward 5 (Shastri Nagar)'},
      {'day': '3 Days Ago', 'area': 'Ward 14 (Gandhi Nagar)'},
      {'day': '4 Days Ago', 'area': 'Ward 8 (Nehru Colony)'},
      {'day': '5 Days Ago', 'area': 'Ward 10 (Rajiv Circle)'},
      {'day': '6 Days Ago', 'area': 'Ward 3 (Tagore Nagar)'},
      {'day': '7 Days Ago', 'area': 'Ward 7 (Kamaraj Avenue)'},
    ];

    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Duty Schedule Grid",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Assigned sectors & landmarks",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 380),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "TODAY'S COORDINATES",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Area: $_assignedWardName",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Total Load: $_assignedTotalHouseCount Houses",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFF1E293B)),
                      const SizedBox(height: 8),
                      const Text(
                        "📍 LANDMARK",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Near Gandhi Statue, Main Intersection",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Fully Addressed",
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Sectors A-H, Main Gandhi Road Junction",
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "LAST 7 DAYS ASSIGNED SECTORS",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: previousSectors.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Color(0xFF1E293B)),
                  itemBuilder: (context, index) {
                    final item = previousSectors[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['area']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                          Text(
                            item['day']!,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close Schedule View",
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveModal() {
    _leaveDateController.clear();
    _leaveReasonController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppCustomAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Apply Operational Leave",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Submit leave parameter request",
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 10),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TARGET DATE REQUESTED",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _leaveDateController,
                readOnly: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "Select Date (YYYY-MM-DD)",
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  prefixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  fillColor: const Color(0xFF020617),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFF10B981),
                            onPrimary: Color(0xFF020617),
                            surface: Color(0xFF0F172A),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _leaveDateController.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                "REASON FOR LEAVE",
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _leaveReasonController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "e.g. Medical issue, personal commitment...",
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  fillColor: const Color(0xFF020617),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E293B)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                if (_leaveDateController.text.isEmpty ||
                    _leaveReasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please complete leave parameters!"),
                    ),
                  );
                  return;
                }
                final String targetDate = _leaveDateController.text;
                final String reasonStr = _leaveReasonController.text.trim();
                Navigator.pop(context);

                await _submitLeaveToBackend(targetDate, reasonStr);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✓ Leave request for $targetDate sent to office database! 📅",
                        style: const TextStyle(
                          color: Color(0xFF020617),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                "Submit Leave Application",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHouseProcessingOverlay(int index) {
    final house = _houseManifestList[index];
    final TextEditingController otpInputController = TextEditingController();
    bool cashCollectedInternalFlag = house['paymentStatus'] == 'Paid';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AppCustomAlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "House Node: ${house['houseNo']}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Owner: ${house['owner']}",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!cashCollectedInternalFlag) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⚠️ ARREARS DUE: ₹${house['feeAmount']}",
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Collect cash parameter updates from householder before validation processing.",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: const Color(0xFF020617),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  cashCollectedInternalFlag = true;
                                });
                              },
                              child: const Text(
                                "Confirm Cash Received",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (house['paymentStatus'] == 'Pending') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "✓ Cash Collected Successfully",
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "SECURE AUTHENTICATION OTP",
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: otpInputController,
                    enabled: cashCollectedInternalFlag,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "• • • •",
                      hintStyle: const TextStyle(
                        color: Color(0xFF334155),
                        letterSpacing: 4,
                      ),
                      fillColor: const Color(0xFF020617),
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => _handleSkippedLiftAction(index),
                child: const Text(
                  "Skip / Exception",
                  style: TextStyle(
                    color: Color(0xFFF43F5E),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ), // Correctly closed TextButton

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF020617),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog gate

                  final double fee = (house['feeAmount'] as num).toDouble();

                  // Direct the worker to process the transaction on the payment page
                  final bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentPage(amountToPay: fee),
                    ),
                  );

                  if (result == true) {
                    setState(() {
                      _houseManifestList[index]['collectStatus'] = "Collected";
                      _houseManifestList[index]['paymentStatus'] = "Paid";
                    });
                    await _syncCollectionStatusToBackend(
                      house['houseNo'],
                      "Collected",
                    );
                  }
                },
                child: const Text(
                  "Confirm Lift",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ), // Added the missing child property back here safely
              ), // Closed ElevatedButton
            ], // Closed actions array
          ); // Closed AppCustomAlertDialog
        }, // Closed StatefulBuilder builder function
      ), // Closed StatefulBuilder widget
    ); // Closed showDialog wrapper execution block
  } // Closed _openHouseProcessingOverlay method block

  void _handleSkippedLiftAction(int index) {
    Navigator.pop(context);
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AppCustomAlertDialog(
        title: const Text(
          "Log Collection Exception",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: const InputDecoration(
            hintText: "e.g. Bin empty, Access blocked, Hazardous material",
            hintStyle: TextStyle(color: Color(0xFF475569)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
            ),
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() {
                _houseManifestList[index]['collectStatus'] = "Skipped";
              });
              await _syncCollectionStatusToBackend(
                _houseManifestList[index]['houseNo'],
                "Skipped",
                exceptionReason: reasonController.text.trim(),
              );
            },
            child: const Text(
              "Log Exception",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppHeaderRow(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActiveDeploymentCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'FIELD OPERATION MODULES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF64748B),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildOperationNavigationRow(),
                    const SizedBox(height: 24),
                    if (_showCollectionUpdate) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'LIVE UNIT MANIFEST TRACKING',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF64748B),
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Today Route',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildManifestListViewBlock(),
                      const SizedBox(height: 24),
                    ],
                    _buildRemittanceReportingSection(),
                    const SizedBox(height: 24),
                    _buildIncidentLoggerSection(),
                    const SizedBox(height: 24),
                    _buildFeedbackEvaluationSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBarWidget(),
    );
  }

  Widget _buildAppHeaderRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  text: 'Eco',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: 'Bin',
                      style: TextStyle(color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              const Text(
                'OPERATIONS GATEWAY',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _openUserProfilePanel(context),
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(4).copyWith(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                border: Border.all(color: const Color(0xFF334155)),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: const Text(
                      'DR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'CREW LEAD',
                        style: TextStyle(
                          fontSize: 7,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dave R.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeploymentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE DISPATCHED ASSIGNMENT',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Text(
                'Shift AM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _assignedWardName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDispatchStatColumn(
                "LOAD METRIC",
                "$_assignedTotalHouseCount Houses",
              ),
              _buildDispatchStatColumn("DUTY CLASS", "Main Area Shift"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchStatColumn(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            color: Color(0xFF99F6E4),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildOperationNavigationRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickOpButton(
            Icons.alt_route_rounded,
            "View Schedule",
            const Color(0xFF10B981),
            _showTodayScheduleDialog,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickOpButton(
            Icons.fact_check_rounded,
            "Collection Update",
            const Color(0xFF06B6D4),
            () {
              setState(() {
                _showCollectionUpdate = !_showCollectionUpdate;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _showCollectionUpdate
                        ? "Live tracking manifest expanded below! 🔍"
                        : "Live tracking manifest minimized.",
                  ),
                  backgroundColor: const Color(0xFF06B6D4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickOpButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManifestListViewBlock() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _houseManifestList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final house = _houseManifestList[index];
        final bool isCollected = house['collectStatus'] == 'Collected';
        final bool isSkipped = house['collectStatus'] == 'Skipped';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border.all(color: const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "House No: ${house['houseNo']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(house['paymentStatus']),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Owner: ${house['owner']}",
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCollected)
                _buildActionCompletedIndicator(
                  Icons.check_circle_rounded,
                  "Lifted",
                  const Color(0xFF10B981),
                )
              else if (isSkipped)
                _buildActionCompletedIndicator(
                  Icons.warning_amber_rounded,
                  "Skipped",
                  const Color(0xFFF43F5E),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: house['paymentStatus'] == 'Paid'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF020617),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _openHouseProcessingOverlay(index),
                      child: Text(
                        house['paymentStatus'] == 'Paid'
                            ? 'Process'
                            : 'Collect',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF43F5E),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => _handleSkippedLiftAction(index),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final bool isPaid = status == 'Paid';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isPaid ? "PAID" : "PENDING FEES",
        style: TextStyle(
          color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionCompletedIndicator(
    IconData icon,
    String text,
    Color targetColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: targetColor, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: targetColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRemittanceReportingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "REPORT & EXPENSE SUBMISSION",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Houses Lifted",
                  _collectedCountController,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Cash Handled (₹)",
                  _cashReceivedController,
                  true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "OFFICE REMITTANCE VECTOR",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF020617),
              border: Border.all(color: const Color(0xFF1E293B)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentVectorOption,
                dropdownColor: const Color(0xFF0F172A),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                items:
                    [
                          "Pay as cash in office counter",
                          "Pay online instantly (Digital Settlement)",
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (val) => setState(() {
                  _selectedPaymentVectorOption = val!;
                }),
              ),
            ),
          ),
          if (_selectedPaymentVectorOption.contains("online")) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {},
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: const Text(
                  "Launch Digital Remittance Portal",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Units Pending",
                  _pendingCountController,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Reason for Pending",
                  _pendingReasonController,
                  false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF1E293B), height: 1),
          const SizedBox(height: 16),
          const Text(
            "ROUTE RUNTIME EXPENSE VOUCHER",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildFormFieldLabelAndInput(
                  "Amount (₹)",
                  _expenseAmountController,
                  true,
                  hintStr: "e.g. 350",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF020617),
                    border: Border.all(color: const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt_rounded,
                        color: Color(0xFF475569),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Upload Voucher",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submitDayReportAndExpenses,
              child: const Text(
                "Submit Operational Logs & Balances",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFieldLabelAndInput(
    String title,
    TextEditingController targetCtrl,
    bool numeric, {
    String hintStr = "",
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: targetCtrl,
            keyboardType: numeric ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: hintStr,
              hintStyle: const TextStyle(color: Color(0xFF334155)),
              fillColor: const Color(0xFF020617),
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncidentLoggerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "LOG FIELD INCIDENT / COMPLAINT",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incidentReportController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  "Report route anomalies, public alignment issues, damaged bins etc...",
              hintStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
              ),
              fillColor: const Color(0xFF020617),
              filled: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E293B)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Optional camera portal opened. 📸"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(
                  color: const Color(0xFF334155),
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.add_a_photo_outlined,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Upload Complaint Photo (Optional)",
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF43F5E),
                side: const BorderSide(color: Color(0xFF1E293B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                if (_incidentReportController.text.trim().isEmpty) return;
                _incidentReportController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Incident log with metadata flagged for supervisor review 🚨",
                    ),
                  ),
                );
              },
              child: const Text(
                "Report Incident to Terminal Control",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackEvaluationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "APP PERFORMANCE FEEDBACK",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final int starScore = index + 1;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _workerRating = starScore;
                  });
                },
                icon: Icon(
                  starScore <= _workerRating
                      ? Icons.star_rate_rounded
                      : Icons.star_border_rounded,
                  color: starScore <= _workerRating
                      ? const Color(0xFFFBBF24)
                      : const Color(0xFF475569),
                  size: 28,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _workerRating > 0
                ? "Rating: $_workerRating out of 5 stars!"
                : "Tap stars to evaluate system utility.",
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_workerRating == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please select a star rating first!"),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "✓ Performance metric score $_workerRating logged securely! 🌟",
                    ),
                  ),
                );
                setState(() {
                  _workerRating = 0;
                });
              },
              child: const Text(
                "Submit Feedback Metrics",
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBarWidget() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 0.8)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: const Color(0xFF64748B),
        selectedFontSize: 9,
        unselectedFontSize: 9,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.airport_shuttle_rounded),
            label: 'Route',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_rounded, color: Color(0xFFFBBF24)),
            label: 'Apply Leave',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.power_settings_new_rounded),
            label: 'Logout',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            setState(() {
              _showCollectionUpdate = true;
            });
          }
          if (index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Expense logs brought to focus!")),
            );
          }
          if (index == 2) {
            _showApplyLeaveModal();
          }
          if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => EcoBinLoginPage(
                  userDashboardScreen: EcoBinHomePage(),
                  workerDashboardScreen: CollectionWorkerPage(),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class AppCustomAlertDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget>? actions;

  const AppCustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF1E293B)),
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }
}
