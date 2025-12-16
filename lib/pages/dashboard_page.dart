// lib/pages/dashboard_page.dart (FINAL FIX TERAKHIR: No Overflow + Pending Pasti Muncul + UI Aman Semua Ukuran)
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../api/api_service.dart';

class DashboardPage extends StatefulWidget {
  final UserModel user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  String _currentLocation = 'Memuat lokasi...';
  String _currentTime = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _totalUsers = 0;
  int _todayPresensi = 0;
  int _waitingApproval = 0;
  int _presentToday = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _getCurrentLocation();
    _updateTime();
    _loadStats();
    Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
  }

  void _updateTimeLoop() {
    if (mounted) {
      _updateTime();
      Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _currentLocation = 'GPS dimatikan');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _currentLocation = 'Izin ditolak');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() => _currentLocation = 'Gagal baca lokasi');
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _statsLoading = true);
    try {
      if (widget.user.role == 'admin' || widget.user.role == 'superadmin') {
        final allPresensi = await ApiService.getAllPresensi();
        final users = await ApiService.getUsers();
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final todayData = allPresensi.where((p) {
          final created = (p['created_at'] ?? '').toString();
          return created.length >= 10 && created.substring(0, 10) == today;
        }).toList();

        // FIX PASTI: Cek 'Pending' (case sensitive) dan fallback jika null
        final waiting = allPresensi.where((p) {
          final status = p['status']?.toString() ?? '';
          return status == 'Waiting';
        }).toList();

        setState(() {
          _totalUsers = users.length;
          _todayPresensi = todayData.length;
          _waitingApproval = waiting.length;
          _presentToday = todayData
              .where((p) => p['status']?.toString() == 'Disetujui')
              .length;
        });
      }
    } catch (e) {
      debugPrint('Error load stats: $e');
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1200;
    final isAdmin =
        widget.user.role == 'admin' || widget.user.role == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar (sudah aman)
          Container(
            width: 280,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  child: const Text(
                    'Skaduta',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _sidebarItem(
                        icon: Icons.home_rounded,
                        label: 'Dashboard',
                        isSelected: true,
                        onTap: () {},
                      ),
                      _sidebarItem(
                        icon: Icons.history_rounded,
                        label: 'Riwayat Presensi',
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/history',
                          arguments: widget.user,
                        ),
                      ),
                      if (isAdmin)
                        _sidebarItem(
                          icon: Icons.list_alt_rounded,
                          label: 'Kelola User',
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin-user-list'),
                        ),
                      if (isAdmin)
                        _sidebarItem(
                          icon: Icons.verified_user_rounded,
                          label: 'Konfirmasi Absensi',
                          onTap: () =>
                              Navigator.pushNamed(context, '/admin-presensi'),
                        ),
                      if (isAdmin)
                        _sidebarItem(
                          icon: Icons.table_chart_rounded,
                          label: 'Rekap Absensi',
                          onTap: () => Navigator.pushNamed(context, '/rekap'),
                        ),
                      if (widget.user.role == 'superadmin')
                        _sidebarItem(
                          icon: Icons.supervisor_account_rounded,
                          label: 'User Management',
                          onTap: () =>
                              Navigator.pushNamed(context, '/user-management'),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.namaLengkap,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              widget.user.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat datang kembali, ${widget.user.namaLengkap} 👋',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'EEEE, dd MMMM yyyy',
                              ).format(DateTime.now()),
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentTime,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF3B82F6),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF3B82F6),
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _currentLocation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: _getCurrentLocation,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      PopupMenuButton(
                        icon: const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFF3B82F6),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            onTap: () async {
                              await ApiService.logout();
                              if (mounted)
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (r) => false,
                                );
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.logout_rounded, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isAdmin) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Statistik Hari Ini',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _loadStats,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reload Data'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _statsLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 5,
                                    color: Color(0xFF3B82F6),
                                  ),
                                )
                              : GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: isWide ? 4 : 2,
                                  childAspectRatio:
                                      1.45, // Naikkan sedikit biar aman dari overflow
                                  crossAxisSpacing: 32,
                                  mainAxisSpacing: 32,
                                  children: [
                                    _premiumStatCard(
                                      'Total User',
                                      _totalUsers.toString(),
                                      Icons.people_rounded,
                                      const Color(0xFF3B82F6),
                                    ),
                                    _premiumStatCard(
                                      'Presensi Hari Ini',
                                      _todayPresensi.toString(),
                                      Icons.how_to_reg_rounded,
                                      const Color(0xFF10B981),
                                    ),
                                    _premiumStatCard(
                                      'Menunggu Approval',
                                      _waitingApproval.toString(),
                                      Icons.pending_actions_rounded,
                                      const Color(0xFFF59E0B),
                                    ),
                                    _premiumStatCard(
                                      'Hadir Disetujui',
                                      _presentToday.toString(),
                                      Icons.check_circle_rounded,
                                      const Color(0xFF10B981),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 60),
                        ],
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 32),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 3 : 2,
                                childAspectRatio: isWide
                                    ? 1.55
                                    : 1.45, // Naikkan lagi biar tidak overflow
                                crossAxisSpacing: 40,
                                mainAxisSpacing: 40,
                              ),
                          itemCount: _getCards().length,
                          itemBuilder: (_, i) =>
                              _premiumActionCard(_getCards()[i]),
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 3),
                ),
                child: Icon(icon, size: 38, color: color),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumActionCard(Map<String, dynamic> card) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: card['onTap'],
        child: Container(
          padding: const EdgeInsets.all(28), // Kurangi padding sedikit
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: card['color'].withOpacity(0.4),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: card['color'].withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      card['color'].withOpacity(0.25),
                      card['color'].withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: card['color'].withOpacity(0.6),
                    width: 4,
                  ),
                ),
                child: Icon(card['icon'], size: 52, color: card['color']),
              ),
              const SizedBox(height: 16),
              Text(
                card['title'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  card['subtitle'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: card['color'].withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 30,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getCards() {
    List<Map<String, dynamic>> cards = [];
    final isAdmin =
        widget.user.role == 'admin' || widget.user.role == 'superadmin';

    if (!isAdmin) {
      cards.addAll([
        {
          'icon': Icons.login_rounded,
          'title': 'Absen Masuk Biasa',
          'subtitle': 'Absen masuk harian otomatis disetujui',
          'onTap': () => _navigateToPresensi('Masuk'),
          'color': const Color(0xFF10B981),
        },
        {
          'icon': Icons.logout_rounded,
          'title': 'Absen Pulang Biasa',
          'subtitle': 'Absen pulang harian otomatis disetujui',
          'onTap': () => _navigateToPresensi('Pulang'),
          'color': const Color(0xFFF59E0B),
        },
        {
          'icon': Icons.fast_forward_rounded,
          'title': 'Pulang Cepat',
          'subtitle': 'Pulang lebih awal (otomatis disetujui)',
          'onTap': () => _navigateToPresensi('Pulang Cepat'),
          'color': const Color(0xFF3B82F6),
        },
        {
          'icon': Icons.sick_rounded,
          'title': 'Izin Tidak Masuk',
          'subtitle': 'Ajukan izin, perlu persetujuan admin',
          'onTap': () => _navigateToPresensi('Izin'),
          'color': const Color(0xFFEF4444),
        },
        {
          'icon': Icons.assignment_rounded,
          'title': 'Penugasan Khusus',
          'subtitle': 'Ajukan penugasan luar, perlu approval',
          'onTap': _showPenugasanSheet,
          'color': const Color(0xFF8B5CF6),
        },
        {
          'icon': Icons.history_rounded,
          'title': 'Riwayat Presensi',
          'subtitle': 'Lihat semua riwayat absen pribadi',
          'onTap': () =>
              Navigator.pushNamed(context, '/history', arguments: widget.user),
          'color': const Color(0xFF6366F1),
        },
      ]);
    } else {
      cards.addAll([
        {
          'icon': Icons.verified_user_rounded,
          'title': 'Konfirmasi Presensi',
          'subtitle': 'Setujui atau tolak pengajuan presensi',
          'onTap': () => Navigator.pushNamed(context, '/admin-presensi'),
          'color': const Color(0xFF10B981),
        },
        {
          'icon': Icons.list_alt_rounded,
          'title': 'Kelola User',
          'subtitle': 'Lihat detail & histori per user',
          'onTap': () => Navigator.pushNamed(context, '/admin-user-list'),
          'color': const Color(0xFF3B82F6),
        },
        {
          'icon': Icons.table_chart_rounded,
          'title': 'Rekap Bulanan',
          'subtitle': 'Export Excel & analisis absensi',
          'onTap': () => Navigator.pushNamed(context, '/rekap'),
          'color': const Color(0xFF6366F1),
        },
        {
          'icon': Icons.history_rounded,
          'title': 'Riwayat Global',
          'subtitle': 'Lihat semua presensi semua user',
          'onTap': () =>
              Navigator.pushNamed(context, '/history', arguments: widget.user),
          'color': const Color(0xFFF59E0B),
        },
        if (widget.user.role == 'superadmin')
          {
            'icon': Icons.supervisor_account_rounded,
            'title': 'User Management',
            'subtitle': 'Kelola akun admin & user',
            'onTap': () => Navigator.pushNamed(context, '/user-management'),
            'color': const Color(0xFF8B5CF6),
          },
      ]);
    }
    return cards;
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: isSelected
            ? const Color(0xFF3B82F6).withOpacity(0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[400],
                  size: 30,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPresensi(String jenis) {
    Navigator.pushNamed(
      context,
      '/presensi',
      arguments: {'user': widget.user, 'jenis': jenis},
    );
  }

  void _showPenugasanSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Pilih Jenis Penugasan',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _penugasanOption(
              'Absen Masuk Penugasan',
              Icons.login_rounded,
              const Color(0xFF10B981),
              () => _navigateToPresensi('Penugasan_Masuk'),
            ),
            _penugasanOption(
              'Absen Pulang Penugasan',
              Icons.logout_rounded,
              const Color(0xFFF59E0B),
              () => _navigateToPresensi('Penugasan_Pulang'),
            ),
            _penugasanOption(
              'Penugasan Full Day',
              Icons.assignment_turned_in_rounded,
              const Color(0xFF8B5CF6),
              () => _navigateToPresensi('Penugasan_Full'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _penugasanOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: color),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: color, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
