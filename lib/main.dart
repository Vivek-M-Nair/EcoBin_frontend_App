import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'login_page.dart';

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
      home: const EcoBinSplashScreen(
        nextScreen: EcoBinLoginPage(dashboardScreen: EcoBinHomePage()),
      ),
    );
  }
}

class EcoBinHomePage extends StatefulWidget {
  const EcoBinHomePage({super.key});

  @override
  State<EcoBinHomePage> createState() => _EcoBinHomePageState();
}

class _EcoBinHomePageState extends State<EcoBinHomePage> {
  int _ecoPoints = 850;
  bool _isDateAssigned = true;
  bool _isPaymentDone = false;
  int _selectedRating = 0;
  bool _isMissionJoined = false;

  String _userName = "Alex Mercer";
  // String _userRole = "MEMBER";

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  // ignore: unused_element
  void _toggleDashboardState() {
    setState(() {
      _isDateAssigned = !_isDateAssigned;
    });
    _showSnackBar(
      _isDateAssigned
          ? "Switched Dashboard View to 'Date Assigned' state"
          : "Switched Dashboard View to 'Date Pending' state",
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Interactive State Controller
            // _buildStateController(),

            // App Header Row
            _buildHeader(),

            // Glowing Partition Separator
            _buildGlowingDivider(),

            // Scrollable Content Area
            // Scrollable Content Area
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
                    // Dynamic Status Panel
                    _buildDynamicStatusPanel(),
                    const SizedBox(height: 24),

                    // Core Operations Section
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
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isPaymentDone ? 'Paid' : '\$12 Due',
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
                      iconColor: const Color(0xFF06B6D4), // Cyan 500
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
                      iconColor: const Color(0xFFF59E0B), // Amber 500
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
                      iconColor: const Color(0xFFF43F5E), // Rose 500
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
                      iconColor: const Color(0xFFA855F7), // Purple 500
                      title: 'Point redeem',
                      subtitle: 'Trade green points for real rewards',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.2),
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

                    // News & Missions Section
                    _buildMissionSection(),
                    const SizedBox(height: 32),

                    // Review & Feedback Form
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

  // --- WIDGET BUILDERS ---

  // Widget _buildStateController() {
  //   return Container(
  //     margin: const EdgeInsets.all(12),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFF0F172A),
  //       border: Border.all(color: const Color(0xFF334155)),
  //       borderRadius: BorderRadius.circular(16),
  //     ),
  // child: Row(
  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //   children: [
  // Column(
  //   crossAxisAlignment: CrossAxisAlignment.start,
  //   children: [
  //     Text(
  //       'INTERACTIVE CONTROLS',
  //       style: TextStyle(
  //         fontSize: 10,
  //         fontWeight: FontWeight.bold,
  //         color: const Color(0xFF10B981),
  //       ),
  //     ),
  //     const Text(
  //       'Force App Dashboard State',
  //       style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
  //     ),
  //   ],
  // ),
  //       ElevatedButton.icon(
  //         onPressed: _toggleDashboardState,
  //         icon: Icon(
  //           _isDateAssigned ? Icons.calendar_today : Icons.hourglass_empty,
  //           size: 14,
  //         ),
  //         label: Text(_isDateAssigned ? "Date Assigned" : "Pending Slot"),
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: _isDateAssigned
  //               ? const Color(0xFF10B981)
  //               : const Color(0xFF334155),
  //           foregroundColor: _isDateAssigned
  //               ? const Color(0xFF020617)
  //               : Colors.white,
  //           textStyle: const TextStyle(
  //             fontSize: 12,
  //             fontWeight: FontWeight.bold,
  //           ),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //         ),
  //       ),
  //     ],
  //   ),
  //   );
  // }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Container(
              //   width: 36,
              //   height: 36,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFF10B981),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: const Icon(
              //     Icons.group_add_outlined,
              //     color: Color.fromARGB(255, 20, 27, 62),
              //     size: 20,
              //   ),
              // ),
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
                  color: const Color(0xFF334155).withValues(alpha: 0.8),
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(
                      0xFF10B981,
                    ).withValues(alpha: 0.2),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //   // _userRole,
                      //   style: const TextStyle(
                      //     fontSize: 8,
                      //     color: Color(0xFF94A3B8),
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingDivider({double height = 1.2}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft ambient glow behind the line
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF10B981).withValues(alpha: 0.15),
                const Color(0xFF10B981).withValues(alpha: 0.0),
              ],
              radius: 5.0,
            ),
          ),
        ),
        // Sharp line that spans fully from side to side
        Container(
          height: height,
          width: double.infinity,
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
        // Premium central icon badge
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(
              0xFF020617,
            ), // Slate 950 (scaffold background color)
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
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
                    color: Colors.black.withValues(alpha: 0.2),
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
            const Text(
              '18 JUN, 2026',
              style: TextStyle(
                fontSize: 28,
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
                  text: const TextSpan(
                    text: 'Assigned Agent: ',
                    style: TextStyle(fontSize: 12, color: Color(0xE6F0FDF4)),
                    children: [
                      TextSpan(
                        text: 'Dave R.',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // TextButton(
                //   onPressed: () => _showActionModal(
                //     'Schedule Details & Map',
                //     _buildScheduleModalContent(),
                //   ),
                //   style: TextButton.styleFrom(
                //     padding: EdgeInsets.zero,
                //     minimumSize: Size.zero,
                //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //   ),
                //   child: const Text(
                //     'Track Route →',
                //     style: TextStyle(
                //       fontSize: 12,
                //       color: Colors.white,
                //       decoration: TextDecoration.underline,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
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
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
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
                    color: Colors.black.withValues(alpha: 0.3),
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
                color: iconColor.withValues(alpha: 0.1),
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
                  color: const Color(0xFF020617).withValues(alpha: 0.4),
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
                  onPressed: () {
                    if (_selectedRating == 0) {
                      _showSnackBar("Please select a star rating first!");
                      return;
                    }
                    _showSnackBar("Thank you for your valuable feedback! 💚");
                    setState(() {
                      _selectedRating = 0;
                    });
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
          if (index == 1) {
            _showActionModal(
              'Collection Payment Settle',
              _buildPaymentModalContent(),
            );
          }
          if (index == 2) {
            _showActionModal('Request Collection', _buildRequestModalContent());
          }
          if (index == 3) {
            _showActionModal(
              'Submit Complaint / Report',
              _buildComplaintModalContent(),
            );
          }
          if (index == 4) {
            _showActionModal('Redeem Rewards', _buildRedeemModalContent());
          }
        },
      ),
    );
  }

  // --- MODAL SYSTEM AND CONTENTS ---

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
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
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
                    _isPaymentDone ? '\$0.00' : '\$12.00',
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
              _buildModalRowItem('Base Municipal Waste Fee', '\$10.00'),
              const SizedBox(height: 8),
              _buildModalRowItem('E-Waste Surcharge', '\$2.00'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isPaymentDone = true;
                    });
                    setModalState(() {});
                    Navigator.pop(context);
                    _showSnackBar(
                      "💳 Payment processed successfully! Thank you.",
                    );
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
                    'Authorize Payment (\$12.00)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
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
    // --- MOCK BACKEND DATA (Simulating Spring Boot Responses) ---
    // Change these variables to test both logic flows:
    final DateTime today = DateTime.now();

    // Example 1: Last collection was 18 days ago (Normal fee window)
    final DateTime lastCollectedDate = today.subtract(const Duration(days: 18));

    // Example 2 (Uncomment to test double fee): Last collection was 5 days ago
    // final DateTime lastCollectedDate = today.subtract(const Duration(days: 5));

    final int daysSinceLastCollection = today
        .difference(lastCollectedDate)
        .inDays;

    // Set baseline prices
    const double normalAmount = 10.00;
    final double calculatedAmount = daysSinceLastCollection > 15
        ? normalAmount
        : (normalAmount * 2);

    // Formatting date strings neatly
    final String formattedLastDate =
        "${lastCollectedDate.day} ${_getMonthName(lastCollectedDate.month)}, ${lastCollectedDate.year}";

    // Setup logic for next collection milestone
    final String nextCollectionText = _isDateAssigned
        ? "18 Jun, 2026"
        : "will be assigned within 24 hours";

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TIME LOG MILESTONES PANEL ---
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

            // --- DYNAMIC FEE NOTICE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: calculatedAmount > normalAmount
                    ? const Color(0xFFF43F5E).withOpacity(
                        0.1,
                      ) // Warning pink for rush payment
                    : const Color(
                        0xFF10B981,
                      ).withOpacity(0.1), // Green for standard payment
                border: Border.all(
                  color: calculatedAmount > normalAmount
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
                          calculatedAmount > normalAmount
                              ? '🚨 RUSH REQUEST FEE APPLYING'
                              : '🌿 STANDARD CLEANUP FEE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: calculatedAmount > normalAmount
                                ? const Color(0xFFFDA4AF)
                                : const Color(0xFF6EE7B7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          calculatedAmount > normalAmount
                              ? 'Requested within 15 days of your last collection.'
                              : 'Standard collection interval maintained.',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${calculatedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // --- REASON INPUT FIELD ---
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

            // --- SUBMIT ACTION BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Closes the current modal sheet completely
                  Navigator.pop(context);

                  // Immediately invokes your pre-built payment modal sheet view
                  _showActionModal(
                    'Collection Payment Settle',
                    _buildPaymentModalContent(),
                  );
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
        );
      },
    );
  }

  // Quick helper extension method inside the file to parse standard integer months into string blocks
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
    // --- MOCK BACKEND DATA (Simulating Spring Boot JSON Array Response) ---
    final List<Map<String, String>> collectionHistory = [
      {'date': '24 May, 2026', 'agent': 'Dave R.', 'status': 'Paid'},
      {'date': '10 May, 2026', 'agent': 'Marcus K.', 'status': 'Paid'},
      {'date': '26 Apr, 2026', 'agent': 'Dave R.', 'status': 'Paid'},
      {'date': '12 Apr, 2026', 'agent': 'Suresh Kumar', 'status': 'Paid'},
      {'date': '29 Mar, 2026', 'agent': 'Marcus K.', 'status': 'Paid'},
      {'date': '15 Mar, 2026', 'agent': 'Dave R.', 'status': 'Paid'},
    ];

    // Read current system states
    final String nextDateText = _isDateAssigned
        ? "18 JUN, 2026"
        : "Pending Assignment";
    final String agentText = _isDateAssigned ? "Dave R." : "Not Assigned Yet";
    final String paymentStatusText = _isPaymentDone ? "Paid" : "Pending";
    final Color paymentColor = _isPaymentDone
        ? const Color(0xFF10B981)
        : const Color(0xFFFBBF24);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- UPCOMING SCHEDULE CARD ---
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

        // --- HISTORICAL LOGS SECTION ---
        const Text(
          'LAST 6 COLLECTIONS HISTORY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),

        // Scrollable ListView container mapping history items dynamically
        Container(
          constraints: const BoxConstraints(
            maxHeight: 280,
          ), // Correct Flutter syntax
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: collectionHistory.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Color(0xFF1E293B), height: 1),
            itemBuilder: (context, index) {
              final historyItem = collectionHistory[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          historyItem['date']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Agent: ${historyItem['agent']}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      historyItem['status']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF10B981,
                        ), // Standardized green since history logs are paid invoices
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

  // Quick helper structure to clean up duplicated meta-rows
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
          child: DropdownButton<String>(
            value: 'Missed Collection / Late truck',
            dropdownColor: const Color(0xFF1E293B),
            isExpanded: true,
            underline: const SizedBox(),
            items:
                <String>[
                      'Missed Collection / Late truck',
                      'Incorrect Bill Charged',
                      'Broken / Missing EcoBin container',
                      'Spillage or messy collection',
                    ]
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (_) {},
          ),
        ),
        const SizedBox(height: 16),
        TextField(
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
            border: Border.all(
              color: const Color(0xFF1E293B),
              style: BorderStyle.solid,
            ),
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
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(
                "📋 Complaint filed. Incident ticket #INC-803 logged.",
              );
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
  }

  Widget _buildRedeemModalContent() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          children: [
            _buildRedeemItem(
              '🌲',
              'Sponsor 1 Forest Tree',
              'Planted in dry ecological zones',
              100,
              () => _handleRedeem(100, 'Sponsor 1 Forest Tree', setModalState),
            ),
            const SizedBox(height: 8),
            _buildRedeemItem(
              '☕',
              'Reusable Ceramic Mug',
              'Collect at local green outlets',
              250,
              () => _handleRedeem(250, 'Reusable Ceramic Mug', setModalState),
            ),
            const SizedBox(height: 8),
            _buildRedeemItem(
              '🎫',
              '\$10 Waste Fee Waiver',
              'Deducted automatically from bills',
              500,
              () => _handleRedeem(500, '\$10 Waste Fee Waiver', setModalState),
            ),
          ],
        );
      },
    );
  }

  void _handleRedeem(int cost, String rewardName, StateSetter setModalState) {
    if (_ecoPoints >= cost) {
      setState(() {
        _ecoPoints -= cost;
      });
      setModalState(() {});
      Navigator.pop(context);
      _showSnackBar("Successfully redeemed: $rewardName! 🎉");
    } else {
      _showSnackBar("⚠️ Insufficient EcoPoints for this reward.");
    }
  }

  // --- HELPER CONSTRUCTORS ---

  Widget _buildModalRowItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.4),
        ),
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

  Widget _buildGridSelectButton(String text, bool isSelected) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildTimelineTile(String datetime, String desc, bool isUpcoming) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xFF10B981)
                    : const Color(0xFF475569),
                shape: BoxShape.circle,
                boxShadow: isUpcoming
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            Container(width: 1, height: 45, color: const Color(0xFF334155)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                datetime,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isUpcoming
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 10,
                  color: isUpcoming
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
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
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.5),
        ),
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
            'Are you sure you want to permanently delete your account? This action is irreversible and all your EcoPoints data will be lost.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _userName = "Guest User";
                  _ecoPoints = 0;
                });
                Navigator.of(context).pop();
                Navigator.of(this.context).pop();
                _showSnackBar("⚠️ Account permanently deleted.");
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

  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(
      text: _userName,
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: const Text(
            'Edit Profile Name',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new name',
              hintStyle: const TextStyle(color: Color(0xFF475569)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF10B981)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _userName = controller.text.trim();
                  });
                  Navigator.pop(context);
                  _showSnackBar("Profile updated: $_userName 🌿");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF020617),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save',
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
            border: Border.all(
              color: const Color(0xFF334155).withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(
                  0xFF10B981,
                ).withValues(alpha: 0.15),
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
                    const SizedBox(height: 4),
                    // Text(
                    // _userRole,
                    // style: const TextStyle(
                    //   fontSize: 10,
                    //   color: Color(0xFF10B981),
                    //   fontWeight: FontWeight.bold,
                    //   letterSpacing: 1,
                    // ),
                    // ),
                    const SizedBox(height: 2),
                    const Text(
                      'alex.mercer@ecobin.com',
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
          icon: Icons.edit,
          iconColor: const Color(0xFF10B981),
          title: 'Update Profile Name (Demo)',
          subtitle: 'Change display name and update avatar initials',
          onTap: () {
            Navigator.pop(context);
            _showEditNameDialog();
          },
        ),
        const SizedBox(height: 10),
        _buildProfileOptionItem(
          icon: Icons.logout,
          iconColor: const Color(0xFFF59E0B),
          title: 'Sign Out / Logout',
          subtitle: 'Disconnect your account from this device',
          onTap: () {
            Navigator.pop(context);
            _showSnackBar("👋 Logged out successfully (Demo mode).");
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
                color: iconColor.withValues(alpha: 0.1),
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
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
