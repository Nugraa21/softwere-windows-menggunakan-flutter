// lib/pages/dashboard_page.dart (VERSI FINAL - MODAL LIST LEBIH MENARIK + HAPUS TOMBOL APPROVE/REJECT, GANTI STATUS TEXT SAJA)

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
  int _absenMasukBiasa = 0;
  int _absenMasukPenugasan = 0;
  int _pulangBiasa = 0;
  int _pulangPenugasan = 0;
  int _penugasanFull = 0;
  int _izin = 0;
  int _pendingAll = 0;
  int _ditolakAll = 0;

  List<dynamic> _allPresensiToday = [];
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutExpo),
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

        _allPresensiToday = todayData;

        final masukBiasa = todayData
            .where((p) => p['jenis'] == 'Masuk')
            .toList();
        final masukPenugasan = todayData
            .where((p) => p['jenis'] == 'Penugasan_Masuk')
            .toList();
        final pulangBiasa = todayData
            .where((p) => p['jenis'] == 'Pulang')
            .toList();
        final pulangPenugasan = todayData
            .where((p) => p['jenis'] == 'Penugasan_Pulang')
            .toList();
        final penugasanFull = todayData
            .where((p) => p['jenis'] == 'Penugasan_Full')
            .toList();
        final izinAll = todayData
            .where((p) => p['jenis'] == 'Izin' || p['jenis'] == 'Pulang Cepat')
            .toList();
        final pendingAll = todayData
            .where((p) => p['status'] == 'Waiting')
            .toList();
        final ditolakAll = todayData
            .where((p) => p['status'] == 'Ditolak')
            .toList();

        setState(() {
          _totalUsers = users.length;
          _absenMasukBiasa = masukBiasa.length;
          _absenMasukPenugasan = masukPenugasan.length;
          _pulangBiasa = pulangBiasa.length;
          _pulangPenugasan = pulangPenugasan.length;
          _penugasanFull = penugasanFull.length;
          _izin = izinAll.length;
          _pendingAll = pendingAll.length;
          _ditolakAll = ditolakAll.length;
        });
      }
    } catch (e) {
      debugPrint('Error load stats: $e');
    } finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  void _showUserList(String title, List<dynamic> presensiList) {
    if (presensiList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak ada data untuk "$title"'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            // Handle + Title
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${presensiList.length} presensi',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // List Presensi
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: presensiList.length,
                itemBuilder: (_, i) {
                  final p = presensiList[i];

                  final nama = p['nama_lengkap'] ?? 'Unknown';
                  final username = p['username'] ?? '-';
                  final jenis = p['jenis'] ?? '-';
                  final status = p['status'] ?? 'Waiting';
                  final waktu = p['created_at']?.toString() ?? '';
                  final waktuFormatted = waktu.length >= 19
                      ? waktu.substring(11, 19)
                      : waktu;

                  Color statusColor;
                  String statusText;

                  if (status == 'Disetujui') {
                    statusColor = Colors.green;
                    statusText = 'Disetujui';
                  } else if (status == 'Ditolak') {
                    statusColor = Colors.red;
                    statusText = 'Ditolak';
                  } else {
                    statusColor = Colors.orange;
                    statusText = 'Belum Disetujui';
                  }

                  final statusBg = statusColor.withOpacity(0.1);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: statusColor.withOpacity(0.15),
                            child: Text(
                              nama[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Username: $username',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  'Jenis: $jenis',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Waktu: $waktuFormatted',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Icon status saja (tanpa tombol approve/reject)
                          Icon(
                            status == 'Disetujui'
                                ? Icons.check_circle_rounded
                                : status == 'Ditolak'
                                ? Icons.cancel_rounded
                                : Icons.pending_rounded,
                            color: statusColor,
                            size: 42,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1200;
    final isAdmin =
        widget.user.role == 'admin' || widget.user.role == 'superadmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                  child: Text(
                    'Skaduta',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Expanded(
                //   child: ListView(
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     children: [
                //       _sidebarItem(
                //         Icons.home_rounded,
                //         'Dashboard',
                //         true,
                //         () {},
                //       ),
                //       _sidebarItem(
                //         Icons.history_rounded,
                //         'Riwayat Presensi',
                //         false,
                //         () => Navigator.pushNamed(
                //           context,
                //           '/history',
                //           arguments: widget.user,
                //         ),
                //       ),
                //       if (isAdmin)
                //         _sidebarItem(
                //           Icons.list_alt_rounded,
                //           'Kelola User',
                //           false,
                //           () =>
                //               Navigator.pushNamed(context, '/admin-user-list'),
                //         ),
                //       if (isAdmin)
                //         _sidebarItem(
                //           Icons.verified_user_rounded,
                //           'Konfirmasi Absensi',
                //           false,
                //           () => Navigator.pushNamed(context, '/admin-presensi'),
                //         ),
                //       if (isAdmin)
                //         _sidebarItem(
                //           Icons.table_chart_rounded,
                //           'Rekap Absensi',
                //           false,
                //           () => Navigator.pushNamed(context, '/rekap'),
                //         ),
                //       if (widget.user.role == 'superadmin')
                //         _sidebarItem(
                //           Icons.supervisor_account_rounded,
                //           'User Management',
                //           false,
                //           () =>
                //               Navigator.pushNamed(context, '/user-management'),
                //         ),
                //     ],
                //   ),
                // ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _sidebarItem(
                        Icons.home_rounded,
                        'Dashboard',
                        true,
                        () {},
                      ),
                      _sidebarItem(
                        Icons.history_rounded,
                        'Riwayat Presensi',
                        false,
                        () => Navigator.pushNamed(
                          context,
                          '/history',
                          arguments: widget.user,
                        ),
                      ),
                      if (isAdmin)
                        _sidebarItem(
                          Icons.list_alt_rounded,
                          'Kelola User',
                          false,
                          () =>
                              Navigator.pushNamed(context, '/admin-user-list'),
                        ),
                      if (isAdmin)
                        _sidebarItem(
                          Icons.verified_user_rounded,
                          'Konfirmasi Absensi',
                          false,
                          () => Navigator.pushNamed(context, '/admin-presensi'),
                        ),
                      if (isAdmin)
                        _sidebarItem(
                          Icons.today_rounded,
                          'Rekap Hari Ini',
                          false,
                          () => Navigator.pushNamed(context, '/rekap-hari-ini'),
                        ),
                      if (isAdmin)
                        _sidebarItem(
                          Icons.table_chart_rounded,
                          'Rekap Bulanan',
                          false,
                          () => Navigator.pushNamed(context, '/rekap'),
                        ),
                      if (widget.user.role == 'superadmin')
                        _sidebarItem(
                          Icons.supervisor_account_rounded,
                          'User Management',
                          false,
                          () =>
                              Navigator.pushNamed(context, '/user-management'),
                        ),
                    ],
                  ),
                ),
                Divider(color: Colors.white10, height: 1),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.user.namaLengkap,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.user.role.toUpperCase(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(48, 40, 48, 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: Offset(0, 10),
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
                                'Selamat datang, ${widget.user.namaLengkap} 👋',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                ).format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentTime,
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w300,
                                  color: Color(0xFF3B82F6),
                                  letterSpacing: 3,
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
                            color: Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Color(0xFF3B82F6).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF3B82F6),
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _currentLocation,
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: Icon(Icons.refresh),
                                onPressed: _getCurrentLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        PopupMenuButton(
                          icon: CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF3B82F6),
                            child: Icon(Icons.person, color: Colors.white),
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
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
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
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAdmin) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Statistik Hari Ini',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _loadStats,
                                  icon: Icon(Icons.refresh),
                                  label: Text('Refresh'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3B82F6),
                                    padding: EdgeInsets.symmetric(
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
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF3B82F6),
                                    ),
                                  )
                                : GridView.count(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    crossAxisCount: isWide ? 4 : 2,
                                    childAspectRatio: 1.6,
                                    crossAxisSpacing: 24,
                                    mainAxisSpacing: 24,
                                    children: [
                                      _glassStatCard(
                                        'Total Users',
                                        _totalUsers.toString(),
                                        Icons.people_rounded,
                                        Color(0xFF3B82F6),
                                      ),
                                      _glassStatCard(
                                        'Masuk Biasa',
                                        _absenMasukBiasa.toString(),
                                        Icons.login_rounded,
                                        Color(0xFF10B981),
                                        onTap: () => _showUserList(
                                          'Absen Masuk Biasa',
                                          _allPresensiToday
                                              .where(
                                                (p) => p['jenis'] == 'Masuk',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Masuk Penugasan',
                                        _absenMasukPenugasan.toString(),
                                        Icons.assignment_ind_rounded,
                                        Color(0xFF8B5CF6),
                                        onTap: () => _showUserList(
                                          'Absen Masuk Penugasan',
                                          _allPresensiToday
                                              .where(
                                                (p) =>
                                                    p['jenis'] ==
                                                    'Penugasan_Masuk',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Pulang Biasa',
                                        _pulangBiasa.toString(),
                                        Icons.logout_rounded,
                                        Color(0xFFF59E0B),
                                        onTap: () => _showUserList(
                                          'Pulang Biasa',
                                          _allPresensiToday
                                              .where(
                                                (p) => p['jenis'] == 'Pulang',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Pulang Penugasan',
                                        _pulangPenugasan.toString(),
                                        Icons.assignment_return_rounded,
                                        Color(0xFF6366F1),
                                        onTap: () => _showUserList(
                                          'Pulang Penugasan',
                                          _allPresensiToday
                                              .where(
                                                (p) =>
                                                    p['jenis'] ==
                                                    'Penugasan_Pulang',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Penugasan Full',
                                        _penugasanFull.toString(),
                                        Icons.assignment_turned_in_rounded,
                                        Color(0xFF8B5CF6),
                                        onTap: () => _showUserList(
                                          'Penugasan Full Day',
                                          _allPresensiToday
                                              .where(
                                                (p) =>
                                                    p['jenis'] ==
                                                    'Penugasan_Full',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Izin / Tidak Hadir',
                                        _izin.toString(),
                                        Icons.sick_rounded,
                                        Color(0xFFEF4444),
                                        onTap: () => _showUserList(
                                          'Izin / Tidak Hadir',
                                          _allPresensiToday
                                              .where(
                                                (p) =>
                                                    p['jenis'] == 'Izin' ||
                                                    p['jenis'] ==
                                                        'Pulang Cepat',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Menunggu Approval',
                                        _pendingAll.toString(),
                                        Icons.pending_actions_rounded,
                                        Color(0xFFF59E0B),
                                        onTap: () => _showUserList(
                                          'Menunggu Approval',
                                          _allPresensiToday
                                              .where(
                                                (p) => p['status'] == 'Waiting',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                      _glassStatCard(
                                        'Ditolak Hari Ini',
                                        _ditolakAll.toString(),
                                        Icons.cancel_rounded,
                                        Color(0xFFEF4444),
                                        onTap: () => _showUserList(
                                          'Ditolak Hari Ini',
                                          _allPresensiToday
                                              .where(
                                                (p) => p['status'] == 'Ditolak',
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                            const SizedBox(height: 60),
                          ],

                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 32),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWide ? 3 : 2,
                                  childAspectRatio: 1.4,
                                  crossAxisSpacing: 32,
                                  mainAxisSpacing: 32,
                                ),
                            itemCount: _getCards().length,
                            itemBuilder: (_, i) =>
                                _modernActionCard(_getCards()[i]),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
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

  // Glassmorphism Stat Card
  Widget _glassStatCard(
    String title,
    String value,
    IconData icon,
    Color accent, {
    VoidCallback? onTap,
  }) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 32, color: accent),
                  ),
                  Spacer(),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Action Card
  Widget _modernActionCard(Map<String, dynamic> card) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: card['onTap'],
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: Offset(0, 15),
              ),
            ],
            border: Border.all(color: card['color'].withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card['color'].withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(card['icon'], size: 48, color: card['color']),
              ),
              SizedBox(height: 24),
              Text(
                card['title'],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 12),
              Text(
                card['subtitle'],
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: card['color'],
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Sidebar Item
  Widget _sidebarItem(
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: isSelected
            ? Color(0xFF3B82F6).withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[400],
                  size: 28,
                ),
                SizedBox(width: 18),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontSize: 17,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
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
