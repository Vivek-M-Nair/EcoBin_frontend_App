import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'splash_screen.dart';
import 'login_page.dart';
import 'payment_page.dart';
import 'collection_worker.dart';

void main() {
  runApp(const EcoBinApp());
}

class EcoBinApp extends StatelessWidget {
  const EcoBinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoBin - A Smart Waste Management System',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF020617), // Slate 950
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Emerald 500
          surface: Color(0xFF1E293B), // Slate 900
        ),
      ),
      home: EcoBinSplashScreen(
        nextScreen: EcoBinLoginPage(
          // Provide an empty structure fallback if initialized unauthenticated
          userDashboardScreen: const EcoBinHomePage(loginData: {}),
          workerDashboardScreen: const CollectionWorkerPage(),
        ),
      ),
    );
  }
}

class EcoBinHomePage extends StatefulWidget {
  // Added an injection parameter map to smoothly transfer authentication state variables
  final Map<String, dynamic> loginData;
  const EcoBinHomePage({super.key, this.loginData = const {}});

  @override
  State<EcoBinHomePage> createState() => _EcoBinHomePageState();
}

class _EcoBinHomePageState extends State<EcoBinHomePage> {
  // Core Operational States Linked to MongoDB Cloud
  int _ecoPoints = 850;
  bool _isLoading = true;
  bool _isDateAssigned = false;
  bool _isPaymentDone = false;
  int _selectedRating = 0;
  bool _isMissionJoined = false;

  String _userName = "User Account";
  String _currentUserId = "";
  String _nextCollectionDate = "Pending assignment";
  String _assignedAgentName = "Not yet assigned";
  double _amountDue = 0.00;
  List<String> _historicalDates = [];
  String _zoneLastCollectedDate = "";

  // Text Controllers for Input fields
  final TextEditingController _complaintTextController =
      TextEditingController();
  final TextEditingController _feedbackTextController = TextEditingController();
  final TextEditingController _immediateRequestReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint("🤖 ECOBIN DEBUG: initState() has fired on the Home Page!");
    _parseInjectedLoginData();
    _fetchLiveCollectionDashboard();
  }

  /// Extracts initial runtime data returned from a successful Login network transaction
  /// Extracts initial runtime data returned from a successful Login network transaction
  void _parseInjectedLoginData() {
    if (widget.loginData.isNotEmpty &&
        widget.loginData['status'] == 'success') {
      setState(() {
        // 1. FIRST ASIGN THE CURRENT USER ID SO THE DASHBOARD CAN TALK TO MONGO
        _currentUserId = widget.loginData['houseId'] ?? widget.loginData['userId'] ?? "";

        // 2. MAP THE INCOMING PROFILE PROPERTIES TO DYNAMIC VARIABLES
        _userName = widget.loginData['userName'] ?? "User Account";
        _ecoPoints = widget.loginData['points'] ?? 0;
        _amountDue =
            (widget.loginData['pendingPayment'] as num?)?.toDouble() ?? 0.0;
        _nextCollectionDate =
            widget.loginData['wasteCollectionScheduleDate'] ??
            "Pending assignment";
        _assignedAgentName =
            widget.loginData['agentName'] ?? "Not yet assigned";

        _isDateAssigned =
            _nextCollectionDate != "Pending assignment" &&
            _nextCollectionDate.isNotEmpty;
        _isPaymentDone = _amountDue <= 0;
      });
    }
  }

  /// REST Handshake: Fetches live dashboard telemetry parameters from MongoDB Cluster
  Future<void> _fetchLiveCollectionDashboard() async {
    // If we don't have a valid house ID yet, bypass loading screen to avoid getting stuck
    if (_currentUserId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    debugPrint(
      "🚀 ECOBIN DEBUG: _fetchLiveCollectionDashboard() started executing!",
    );
    try {
      final url = Uri.parse(
        'http://10.181.174.87:8081/api/collection/schedule/view/$_currentUserId',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _nextCollectionDate =
                data['nextCollectionDate'] ?? "Pending assignment";
            _isDateAssigned =
                _nextCollectionDate != "Pending assignment" &&
                _nextCollectionDate.isNotEmpty;
            _assignedAgentName =
                data['assignedWorkerName'] ?? "Not yet assigned";
            _amountDue = (data['amountPending'] as num).toDouble();
            _isPaymentDone = data['paymentStatus'] == 'paid' || _amountDue <= 0;

            if (data['last10CollectedDates'] != null) {
              _historicalDates = List<String>.from(
                data['last10CollectedDates'],
              );
            }
            _zoneLastCollectedDate = data['zoneLastCollectedDate'] ?? "";
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e, stacktrace) {
      debugPrint("🚨 CRITICAL NETWORK REJECTION DETECTED:");
      debugPrint("Error Details: $e");
      debugPrint("Stacktrace: $stacktrace");
    }

    setState(() {
      _isLoading = false;
    });
    _showSnackBar(
      "⚠️ Running in offline backup mode. Check your server IP connection.",
    );
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    if (_currentUserId.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('http://10.181.174.87:8081/api/notifications/$_currentUserId'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    }
    return [];
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.181.174.87:8081/api/notifications/$id'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _showSnackBar("Notification deleted successfully");
      }
    } catch (e) {
      debugPrint("Error deleting notification: $e");
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                    }
                    final list = snapshot.data ?? [];
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFF1E293B)),
                          Expanded(
                            child: list.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No notifications found',
                                      style: TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: list.length,
                                    itemBuilder: (context, index) {
                                      final item = list[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF334155)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.info_outline, color: Color(0xFF10B981), size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'] ?? 'Notification',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['message'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    item['createdAt'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                              onPressed: () async {
                                                await _deleteNotification(item['id'] ?? '');
                                                setModalState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🌿 ', style: TextStyle(fontSize: 16)),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF020617),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isScheduleWithin4Days() {
    if (_nextCollectionDate == "Pending assignment" ||
        _nextCollectionDate.isEmpty ||
        _nextCollectionDate == "Not scheduled") {
      return false;
    }
    try {
      final parts = _nextCollectionDate.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final scheduledDate = DateTime(year, month, day);
        final today = DateTime.now();
        final scheduledDateOnly =
            DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        final differenceInDays = scheduledDateOnly.difference(todayOnly).inDays;
        return differenceInDays >= 0 && differenceInDays <= 4;
      }
    } catch (e) {
      debugPrint("Error parsing date: $e");
    }
    return false;
  }

  @override
  void dispose() {
    _complaintTextController.dispose();
    _feedbackTextController.dispose();
    _immediateRequestReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildGlowingDivider(),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDynamicStatusPanel(),
                    const SizedBox(height: 24),
                    const Text(
                      'CORE OPERATIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationCard(
                      icon: Icons.credit_card,
                      iconColor: const Color(0xFF10B981),
                      title: 'Collection Payment',
                      subtitle: 'Settle cleanups & view history',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isPaymentDone
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFF59E0B).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isPaymentDone
                              ? 'Paid'
                              : '₹${_amountDue.toStringAsFixed(2)} Due',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _isPaymentDone
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCD34D),
                          ),
                        ),
                      ),
                      onTap: () => _showActionModal(
                        'Collection Payment Settle',
                        _buildPaymentModalContent(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationCard(
                      icon: Icons.add_circle_outline,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Waste collection request',
                      subtitle: 'Book bulky, hazard, or e-waste pickup',
                      onTap: () => _showActionModal(
                        'Request Collection',
                        _buildRequestModalContent(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationCard(
                      icon: Icons.calendar_month,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Collection Detail_Schedule_View',
                      subtitle: 'Live routing, maps & route plans',
                      onTap: () => _showActionModal(
                        'Schedule Details & Map',
                        _buildScheduleModalContent(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: const Color(0xFFF43F5E),
                      title: 'Complaint_post',
                      subtitle: 'Report skipped bins, broken assets',
                      onTap: () => _showActionModal(
                        'Submit Complaint / Report',
                        _buildComplaintModalContent(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOperationCard(
                      icon: Icons.card_giftcard,
                      iconColor: const Color(0xFFA855F7),
                      title: 'Point redeem',
                      subtitle: 'Trade green points for real rewards',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_ecoPoints pts',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFD8B4FE),
                          ),
                        ),
                      ),
                      onTap: () => _showActionModal(
                        'Redeem Rewards',
                        _buildRedeemModalContent(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildMissionSection(),
                    const SizedBox(height: 32),
                    _buildFeedbackSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
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
                    'A SMART WASTE MANAGEMENT SYSTEM',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 236, 239, 243),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                onPressed: _showNotificationsModal,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _showActionModal(
                  'Account Options',
                  _buildProfileModalContent(),
                ),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(4).copyWith(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    border: Border.all(
                      color: const Color(0xFF334155).withOpacity(0.8),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                        child: Text(
                          _getInitials(_userName),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingDivider({double height = 1.2}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.15),
                const Color(0xFF10B981).withOpacity(0.0),
              ],
              radius: 5.0,
            ),
          ),
        ),
        Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFF10B981).withOpacity(0.35),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.15),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Text('🌿', style: TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  Widget _buildDynamicStatusPanel() {
    if (_isDateAssigned) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF047857), Color(0xFF115E59)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6EE7B7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'CONFIRMED PICKUP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🌱 $_ecoPoints pts',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Next Schedule',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFA7F3D0),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _nextCollectionDate.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                Icon(Icons.access_time, size: 14, color: Color(0xFFA7F3D0)),
                SizedBox(width: 4),
                Text(
                  '10:00 AM - 12:30 PM',
                  style: TextStyle(fontSize: 12, color: Color(0xE6F0FDF4)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12, height: 3),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Assigned Agent: ',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xE6F0FDF4),
                    ),
                    children: [
                      TextSpan(
                        text: _assignedAgentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                    ),
                  ),
                  child: const Text(
                    '⏳ ROUTE CALCULATING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🏆 $_ecoPoints pts',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Awaiting Scheduler',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pending next slot assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Text('🕒 ', style: TextStyle(fontSize: 12)),
                Text(
                  'Your last cleanup was ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                Text(
                  '4 days ago',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Text('⚡ ', style: TextStyle(fontSize: 12)),
                Text(
                  'Next date scheduled in: ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                Text(
                  '~24 hours',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Need immediate pickup?',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                ElevatedButton(
                  onPressed: () => _showActionModal(
                    'Request Collection',
                    _buildRequestModalContent(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Instant Request',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildOperationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.arrow_forward,
                size: 14,
                color: Color(0xFF475569),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'NEWS & ECO-MISSIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF94A3B8),
              ),
            ),
            Text(
              'View All',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border.all(color: const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF042F2E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'LATEST MISSION',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF020617),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The Community Forest Initiative',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Contribute 15kg of dry paper or plastics this month to fund tree planting.',
                      style: TextStyle(fontSize: 10, color: Color(0xFFD1D5DB)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF020617).withOpacity(0.4),
                  border: Border.all(color: const Color(0xFF1E293B)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Global Progress',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '82% Achieved',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: const LinearProgressIndicator(
                              value: 0.82,
                              minHeight: 6,
                              backgroundColor: Color(0xFF1E293B),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isMissionJoined
                          ? null
                          : () {
                              setState(() {
                                _isMissionJoined = true;
                                _ecoPoints += 150;
                              });
                              _showSnackBar(
                                "Joined Mission! +150 EcoPoints Bonus Added! 🌟",
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMissionJoined
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF10B981),
                        foregroundColor: _isMissionJoined
                            ? const Color(0xFF10B981)
                            : const Color(0xFF020617),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: Text(
                        _isMissionJoined ? 'Joined ✓' : 'Join',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REVIEW & FEEDBACK',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                'How is our clean up agent doing?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE2E8F0),
                ),
              ),
              const Text(
                'Your input directly calibrates municipal services.',
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      int starValue = index + 1;
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedRating = starValue;
                          });
                        },
                        icon: Icon(
                          starValue <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          color: starValue <= _selectedRating
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF334155),
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _selectedRating > 0
                        ? '$_selectedRating Stars Selected'
                        : 'Rate Us',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackTextController,
                maxLines: 3,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Comment on driver behaviour, timing, spills etc...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  fillColor: const Color(0xFF020617),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedRating == 0) {
                      _showSnackBar("Please select a star rating first!");
                      return;
                    }
                    _showSnackBar("Syncing feedback parameters... 🚀");
                    try {
                      final url = Uri.parse(
                        'http://10.181.174.87:8081/api/feedback/submit',
                      );
                      final response = await http.post(
                        url,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({
                          'feedbackDescription': _feedbackTextController.text
                              .trim(),
                          'rating': _selectedRating,
                        }),
                      );
                      if (response.statusCode == 200) {
                        _showSnackBar(
                          "Thank you for your valuable feedback! 💚",
                        );
                        setState(() {
                          _selectedRating = 0;
                        });
                        _feedbackTextController.clear();
                      }
                    } catch (e) {
                      _showSnackBar(
                        "❌ Handshake timeout: Failed to commit evaluation metric.",
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF334155),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF475569)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Send Feedback Report ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('🚀', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
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
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Payments',
          ),
          BottomNavigationBarItem(
            icon: Transform.translate(
              offset: const Offset(0, -4),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFF020617)),
              ),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.gpp_maybe_outlined),
            label: 'Complaints',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Redeem',
          ),
        ],
        onTap: (index) {
          if (index == 1)
            _showActionModal(
              'Collection Payment Settle',
              _buildPaymentModalContent(),
            );
          if (index == 2)
            _showActionModal('Request Collection', _buildRequestModalContent());
          if (index == 3)
            _showActionModal(
              'Submit Complaint / Report',
              _buildComplaintModalContent(),
            );
          if (index == 4)
            _showActionModal('Redeem Rewards', _buildRedeemModalContent());
        },
      ),
    );
  }

  void _showActionModal(String title, Widget content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 8),
              content,
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentModalContent() {
    final double baseFee = _amountDue - 2.0 > 0 ? _amountDue - 2.0 : 10.0;
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACCOUNT BALANCE STATUS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPaymentDone
                        ? '₹0.00'
                        : '₹${_amountDue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Invoice Period: Jun 1 - Jun 15, 2026',
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_isPaymentDone) ...[
              _buildModalRowItem(
                'Base Municipal Waste Fee',
                '₹${baseFee.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _buildModalRowItem('E-Waste Surcharge', '₹2.00'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentPage(amountToPay: _amountDue),
                      ),
                    );
                    if (result == true) {
                      Navigator.pop(context); // Close the bottom sheet now
                      _showSnackBar("Processing payment settlement... 💳");
                      try {
                        final response = await http.post(
                          Uri.parse('http://10.181.174.87:8081/api/payment/pay'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'userId': _currentUserId,
                            'amountPaid': _amountDue,
                          }),
                        );
                        if (response.statusCode == 200) {
                          setState(() {
                            _isPaymentDone = true;
                            _ecoPoints += 50;
                          });
                          _showSnackBar(
                            "💳 Payment recorded! Balance successfully settled.",
                          );
                        } else {
                          _showSnackBar("❌ Payment verification rejected by backend.");
                        }
                      } catch (e) {
                        _showSnackBar("❌ Network connection failed. Try again.");
                      }
                      _fetchLiveCollectionDashboard();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Authorize Payment (₹${_amountDue.toStringAsFixed(2)})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              const Text('🎉', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              const Text(
                'Account Fully Settled',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const Text(
                'No outstanding balances found. Auto-debit is active.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ],
        );
      },
    );
  }



  Widget _buildRequestModalContent() {
    final DateTime today = DateTime.now();
    int daysSinceLastCollection = 999;
    DateTime? lastCollectedDate;

    // Prefer the zone's last collection date to align with backend calculations
    String referenceDateStr = "";
    if (_zoneLastCollectedDate.isNotEmpty && _zoneLastCollectedDate != "Never") {
      referenceDateStr = _zoneLastCollectedDate;
    } else if (_historicalDates.isNotEmpty) {
      referenceDateStr = _historicalDates[0];
    }

    if (referenceDateStr.isNotEmpty) {
      try {
        final parts = referenceDateStr.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          lastCollectedDate = DateTime(year, month, day);
          final todayOnly = DateTime(today.year, today.month, today.day);
          daysSinceLastCollection = todayOnly.difference(lastCollectedDate).inDays;
        }
      } catch (e) {
        debugPrint("Error parsing reference date: $e");
      }
    }

    final double calculatedAmount = daysSinceLastCollection < 15 ? 100.0 : 50.0;
    final String formattedLastDate = lastCollectedDate != null
        ? "${lastCollectedDate.day} ${_getMonthName(lastCollectedDate.month)}, ${lastCollectedDate.year}"
        : "Never collected";
    final String nextCollectionText = _isDateAssigned
        ? _nextCollectionDate
        : "will be assigned within 24 hours";
    final bool isWithin4Days = _isScheduleWithin4Days();

    final bool cond1 = daysSinceLastCollection > 2;
    final bool cond2 = isWithin4Days;
    final bool canRequest = cond1 && !cond2;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(color: const Color(0xFF1E293B)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🕒 ', style: TextStyle(fontSize: 12)),
                      const Text(
                        'Last waste collected: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Text(
                        formattedLastDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📅 ', style: TextStyle(fontSize: 12)),
                      const Text(
                        'Next collection: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          nextCollectionText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isDateAssigned
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFBBF24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: daysSinceLastCollection < 15
                    ? const Color(0xFFF43F5E).withOpacity(0.1)
                    : const Color(0xFF10B981).withOpacity(0.1),
                border: Border.all(
                  color: daysSinceLastCollection < 15
                      ? const Color(0xFFF43F5E).withOpacity(0.3)
                      : const Color(0xFF10B981).withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          daysSinceLastCollection < 15
                              ? '🚨 RUSH REQUEST FEE APPLYING'
                              : '🌿 STANDARD CLEANUP FEE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: daysSinceLastCollection < 15
                                ? const Color(0xFFFDA4AF)
                                : const Color(0xFF6EE7B7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          daysSinceLastCollection < 15
                              ? 'Requested within 15 days of your last collection (₹100).'
                              : 'Standard collection interval maintained (₹50).',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${calculatedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'REASON FOR REQUEST (OPTIONAL)',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _immediateRequestReasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., Spring cleaning, party waste, moving out...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                fillColor: const Color(0xFF020617),
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (!canRequest) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFFF43F5E).withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFFDA4AF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        !cond1
                            ? 'Immediate request is unavailable because the last collection in your zone was within the last 2 days (actual: $daysSinceLastCollection days ago).'
                            : 'Immediate request is unavailable because your next collection is already scheduled within the next 4 days ($nextCollectionText).',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFDA4AF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final String reasonStr = _immediateRequestReasonController.text.trim();
                    final bool? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PaymentPage(amountToPay: calculatedAmount),
                      ),
                    );
                    if (result == true) {
                      Navigator.pop(context); // Close the bottom sheet now
                      _showSnackBar("Filing immediate collection request... ⏳");
                      try {
                        final url = Uri.parse(
                          'http://10.181.174.87:8081/api/collection/immediate-request',
                        );
                        final response = await http.post(
                          url,
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            'userId': _currentUserId,
                            'reason': reasonStr.isNotEmpty ? reasonStr : 'Instant user requested collection',
                          }),
                        );
                        if (response.statusCode == 200) {
                          try {
                            final Map<String, dynamic> resBody = jsonDecode(response.body);
                            if (resBody['status'] == 'success') {
                              _showSnackBar(
                                "🚀 Request committed! Cluster database synchronized successfully.",
                              );
                              _immediateRequestReasonController.clear();
                              _fetchLiveCollectionDashboard();
                            } else {
                              final String errorMsg = resBody['message'] ?? "Request rejected by server controller.";
                              _showSnackBar("❌ $errorMsg");
                            }
                          } catch (e) {
                            _showSnackBar("🚀 Request committed! Cluster database synchronized successfully.");
                            _immediateRequestReasonController.clear();
                            _fetchLiveCollectionDashboard();
                          }
                        } else {
                          try {
                            final Map<String, dynamic> resBody = jsonDecode(response.body);
                            final String errorMsg = resBody['message'] ?? "Request rejected by server controller.";
                            _showSnackBar("❌ $errorMsg");
                          } catch (_) {
                            _showSnackBar("❌ Request rejected by server controller.");
                          }
                        }
                      } catch (e) {
                        _showSnackBar(
                          "⚠ Network error during request processing.",
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF020617),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getMonthName(int monthIndex) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[monthIndex - 1];
  }

  Widget _buildScheduleModalContent() {
    final String nextDateText = _isDateAssigned
        ? _nextCollectionDate
        : "Pending Assignment";
    final String agentText = _isDateAssigned
        ? _assignedAgentName
        : "Not Assigned Yet";
    final String paymentStatusText = _isPaymentDone ? "Paid" : "Pending";
    final Color paymentColor = _isPaymentDone
        ? const Color(0xFF10B981)
        : const Color(0xFFFBBF24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF020617),
            border: Border.all(color: const Color(0xFF1E293B)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT SCHEDULE MONITOR',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _isDateAssigned
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildScheduleRow('📅 Next Date:', nextDateText, isBold: true),
              const SizedBox(height: 8),
              _buildScheduleRow('⚡ Assigned Agent:', agentText),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💳 Payment Status:',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: paymentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: paymentColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      paymentStatusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: paymentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'COLLECTIONS HISTORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          child: _historicalDates.isEmpty
              ? const Center(
                  child: Text(
                    "No historical records found.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _historicalDates.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Color(0xFF1E293B), height: 1),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _historicalDates[index],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Agent: $_assignedAgentName',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintModalContent() {
    String selectedComplaintType = 'Missed Collection / Late truck';
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ISSUE TYPE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedComplaintType,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  items: <String>[
                    'Missed Collection / Late truck',
                    'Incorrect Bill Charged',
                    'Broken / Missing EcoBin container',
                    'Spillage or messy collection',
                  ].map((String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  )).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedComplaintType = val ?? 'Missed Collection / Late truck';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _complaintTextController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Describe what went wrong, time of event...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
                fillColor: const Color(0xFF020617),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                border: Border.all(color: const Color(0xFF1E293B)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: const [
                  Text('📸', style: TextStyle(fontSize: 20)),
                  SizedBox(height: 4),
                  Text(
                    'Upload Damage Photo / Proof',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  Text(
                    'Tap to browse files',
                    style: TextStyle(fontSize: 8, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_complaintTextController.text.trim().isEmpty) {
                    _showSnackBar("Please enter a description for your complaint.");
                    return;
                  }
                  Navigator.pop(context);
                  _showSnackBar("Submitting incident ticket... ⏳");
                  try {
                    final url = Uri.parse(
                      'http://10.181.174.87:8081/api/complaint/submit',
                    );
                    final response = await http.post(
                      url,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'userId': _currentUserId,
                        'complaintDescription': '[$selectedComplaintType] ${_complaintTextController.text.trim()}',
                        'image': '',
                      }),
                    );
                    if (response.statusCode == 200) {
                      final Map<String, dynamic> resData = jsonDecode(
                        response.body,
                      );
                      _showSnackBar(
                        "📋 Ticket logged successfully! ID: ${resData['complaintId'] ?? 'Registered'}",
                      );
                      _complaintTextController.clear();
                    } else {
                      _showSnackBar("❌ Submission rejected by server controller.");
                    }
                  } catch (e) {
                    _showSnackBar(
                      "❌ Connection Dropped: Check if backend server is online.",
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF43F5E),
                  foregroundColor: const Color(0xFF020617),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Submit Report Incident',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRedeemModalContent() {
    return Column(
      children: [
        _buildRedeemItem(
          '🌲',
          'Sponsor 1 Forest Tree',
          'Planted in dry ecological zones',
          100,
          () => _handleRedeem(100, 'Sponsor 1 Forest Tree'),
        ),
        const SizedBox(height: 8),
        _buildRedeemItem(
          '☕',
          'Reusable Ceramic Mug',
          'Collect at local green outlets',
          250,
          () => _handleRedeem(250, 'Reusable Ceramic Mug'),
        ),
        const SizedBox(height: 8),
        _buildRedeemItem(
          '🎫',
          '\$10 Waste Fee Waiver',
          'Deducted automatically from bills',
          500,
          () => _handleRedeem(500, '\$10 Waste Fee Waiver'),
        ),
      ],
    );
  }

  void _handleRedeem(int cost, String rewardName) async {
    if (_ecoPoints < cost) {
      _showSnackBar("⚠️ Insufficient EcoPoints for this reward.");
      return;
    }
    Navigator.pop(context);
    _showSnackBar("Processing token voucher conversion... 🌲");

    String redeemTypeParam = "cup";
    if (rewardName.contains("Tree")) redeemTypeParam = "sponsor_tree";
    if (rewardName.contains("Waiver")) redeemTypeParam = "payment_reduction";

    try {
      final url = Uri.parse('http://10.181.174.87:8081/api/payment/redeem');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUserId,
          'redeemType': redeemTypeParam,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          _ecoPoints -= cost;
        });
        _showSnackBar("Successfully redeemed: $rewardName! 🎉");
        _fetchLiveCollectionDashboard();
      } else {
        _showSnackBar("❌ Redemption process rejected by server module rules.");
      }
    } catch (e) {
      _showSnackBar(
        "❌ Infrastructure Error: Server fallback timeout exception.",
      );
    }
  }

  void _showDeleteAccountConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
              SizedBox(width: 10),
              Text(
                'Delete Account?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action is irreversible.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                _showSnackBar("Processing structural data removal... ⏳");
                try {
                  final url = Uri.parse(
                    'http://10.181.174.87:8081/api/account/user/$_currentUserId',
                  );
                  final response = await http.delete(url);
                  if (response.statusCode == 200) {
                    setState(() {
                      _userName = "Guest User";
                      _ecoPoints = 0;
                    });
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                    _showSnackBar(
                      "⚠️ Account data permanently removed from server cluster.",
                    );
                  } else {
                    _showSnackBar(
                      "❌ Database rejection error code: ${response.statusCode}",
                    );
                  }
                } catch (e) {
                  _showSnackBar(
                    "❌ Network Handshake dropped: Check Spring Boot execution.",
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete Account',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildProfileModalContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                child: Text(
                  _getInitials(_userName),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'user.profile@ecobin.com',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'ACCOUNT OPERATIONS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        _buildProfileOptionItem(
          icon: Icons.logout,
          iconColor: const Color(0xFFF59E0B),
          title: 'Sign Out / Logout',
          subtitle: 'Disconnect your account from this device',
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const EcoBinLoginPage(
                  userDashboardScreen: EcoBinHomePage(),
                  workerDashboardScreen: CollectionWorkerPage(),
                ),
              ),
            );
            _showSnackBar("👋 Logged out successfully.");
          },
        ),
        const SizedBox(height: 10),
        _buildProfileOptionItem(
          icon: Icons.delete_forever,
          iconColor: const Color(0xFFF43F5E),
          title: 'Delete Account',
          subtitle: 'Permanently remove your account and data',
          onTap: () {
            _showDeleteAccountConfirmationDialog();
          },
        ),
      ],
    );
  }

  Widget _buildProfileOptionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border.all(color: const Color(0xFF1E293B)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: Color(0xFF475569),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemItem(
    String emoji,
    String title,
    String subtitle,
    int points,
    VoidCallback onRedeem,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onRedeem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA855F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              '$points pts',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRowItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(color: const Color(0xFF334155).withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
