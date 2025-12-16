// lib/pages/history_page.dart (FINAL: UI konsisten dengan admin pages lain + admin lihat global history)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/user_model.dart';

class HistoryPage extends StatefulWidget {
  final UserModel user;
  const HistoryPage({super.key, required this.user});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  List<dynamic> _allPresensi = [];
  List<dynamic> _waitingPresensi = [];

  bool get _isAdmin =>
      widget.user.role == 'admin' || widget.user.role == 'superadmin';

  @override
  void initState() {
    super.initState();
    if (_isAdmin) {
      _tabController = TabController(length: 2, vsync: this);
    }
    _loadData();
  }

  @override
  void dispose() {
    if (_isAdmin) _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      List<dynamic> data;
      if (_isAdmin) {
        data = await ApiService.getAllPresensi();
      } else {
        data = await ApiService.getUserHistory(widget.user.id);
      }

      data.sort(
        (a, b) => DateTime.parse(
          b['created_at'] ?? '',
        ).compareTo(DateTime.parse(a['created_at'] ?? '')),
      );

      if (_isAdmin) {
        final waiting = data
            .where((item) => (item['status'] ?? 'Waiting') == 'Waiting')
            .toList();
        setState(() {
          _allPresensi = data;
          _waitingPresensi = waiting;
        });
      } else {
        setState(() => _allPresensi = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal load data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showFullPhoto(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(40),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 6,
              child: Center(
                child: Image.network(
                  url,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 36,
                  color: Colors.white,
                ),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullDokumen(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: const Color(0xFFF59E0B),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dokumen Pendukung',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.insert_drive_file_rounded,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Dokumen tidak dapat ditampilkan',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_browser),
                            label: const Text('Buka di Browser'),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getJenisIcon(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return Icons.login_rounded;
      case 'Pulang':
      case 'Penugasan_Pulang':
        return Icons.logout_rounded;
      case 'Izin':
        return Icons.sick_rounded;
      case 'Pulang Cepat':
        return Icons.fast_forward_rounded;
      case 'Penugasan_Full':
        return Icons.assignment_turned_in_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  Color _getJenisColor(String jenis) {
    switch (jenis) {
      case 'Masuk':
      case 'Penugasan_Masuk':
        return const Color(0xFF10B981);
      case 'Pulang':
      case 'Penugasan_Pulang':
        return const Color(0xFFF59E0B);
      case 'Izin':
        return const Color(0xFFEF4444);
      case 'Pulang Cepat':
        return const Color(0xFF3B82F6);
      case 'Penugasan_Full':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Disetujui':
        return const Color(0xFF10B981);
      case 'Ditolak':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  Widget _buildPresensiCard(Map<String, dynamic> item) {
    final fotoUrl = item['selfie']?.toString().isNotEmpty == true
        ? '${ApiService.baseUrl}/selfie/${item['selfie']}'
        : null;
    final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
        ? '${ApiService.baseUrl}/dokumen/${item['dokumen']}'
        : null;
    final jenisColor = _getJenisColor(item['jenis'] ?? '');
    final status = item['status'] ?? 'Waiting';
    final statusColor = _getStatusColor(status);
    final created = DateTime.parse(
      item['created_at'] ?? DateTime.now().toIso8601String(),
    );
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(created);

    return Card(
      elevation: 12,
      shadowColor: jenisColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      margin: const EdgeInsets.only(bottom: 28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      jenisColor.withOpacity(0.2),
                      jenisColor.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: jenisColor.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _getJenisIcon(item['jenis'] ?? ''),
                  size: 48,
                  color: jenisColor,
                ),
              ),
              const SizedBox(width: 40),
              if (fotoUrl != null)
                GestureDetector(
                  onTap: () => _showFullPhoto(fotoUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      fotoUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (fotoUrl != null) const SizedBox(width: 40),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['nama_lengkap'] ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item['jenis'] ?? '-',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waktu: $formattedDate',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keterangan: ${item['keterangan'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    if (item['informasi']?.toString().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Info Penugasan: ${item['informasi']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.2),
                          statusColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: statusColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'Disetujui'
                              ? Icons.check_circle_rounded
                              : status == 'Ditolak'
                              ? Icons.cancel_rounded
                              : Icons.pending_rounded,
                          color: statusColor,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (dokumenUrl != null) ...[
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () => _showFullDokumen(dokumenUrl),
                      icon: const Icon(Icons.attachment_rounded),
                      label: const Text('Lihat Dokumen'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // User biasa: tampilan modern seperti sebelumnya
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Riwayat Presensi Saya'),
          backgroundColor: const Color(0xFF3B82F6),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _allPresensi.isEmpty
            ? const Center(child: Text('Belum ada riwayat'))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _allPresensi.length,
                itemBuilder: (_, i) => _buildPresensiCard(_allPresensi[i]),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadData,
          child: const Icon(Icons.refresh),
        ),
      );
    }

    // Admin / Superadmin: UI sama seperti halaman admin lain
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar kiri
          Container(
            width: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Presensi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Global',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.pending_actions_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Menunggu Persetujuan',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        selected: _tabController.index == 0,
                        selectedTileColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onTap: () => _tabController.animateTo(0),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.history_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Riwayat Lengkap',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        selected: _tabController.index == 1,
                        selectedTileColor: Colors.white.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onTap: () => _tabController.animateTo(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Konten utama
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
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
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Text(
                        _tabController.index == 0
                            ? 'Menunggu Persetujuan'
                            : 'Riwayat Presensi Lengkap',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Tab Menunggu
                            _waitingPresensi.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.pending_actions_rounded,
                                          size: 140,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 40),
                                        Text(
                                          'Tidak ada yang menunggu persetujuan',
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      40,
                                      32,
                                      40,
                                      60,
                                    ),
                                    itemCount: _waitingPresensi.length,
                                    itemBuilder: (_, i) =>
                                        _buildPresensiCard(_waitingPresensi[i]),
                                  ),

                            // Tab Riwayat Lengkap
                            _allPresensi.isEmpty
                                ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.history_toggle_off_rounded,
                                          size: 140,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 40),
                                        Text(
                                          'Belum ada riwayat presensi',
                                          style: TextStyle(
                                            fontSize: 28,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                      40,
                                      32,
                                      40,
                                      60,
                                    ),
                                    itemCount: _allPresensi.length,
                                    itemBuilder: (_, i) =>
                                        _buildPresensiCard(_allPresensi[i]),
                                  ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
