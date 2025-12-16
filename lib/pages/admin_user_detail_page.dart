// lib/pages/admin_user_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_service.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  List<dynamic> _history = [];
  List<dynamic> _waitingPresensi = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final historyData = await ApiService.getUserHistory(widget.userId);
      if (mounted) {
        setState(() {
          _history = historyData ?? [];
          _history.sort(
            (a, b) =>
                DateTime.parse(
                  b['created_at'] ?? DateTime.now().toIso8601String(),
                ).compareTo(
                  DateTime.parse(
                    a['created_at'] ?? DateTime.now().toIso8601String(),
                  ),
                ),
          );
        });
      }

      final allPresensi = await ApiService.getAllPresensi();
      final waiting = allPresensi
          .where(
            (p) =>
                p['user_id'].toString() == widget.userId &&
                (p['status'] ?? '').toString() == 'Waiting',
          )
          .toList();

      if (mounted) setState(() => _waitingPresensi = waiting);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final res = await ApiService.updatePresensiStatus(id: id, status: status);
      if (!mounted) return;

      final message = res['message'] ?? 'Status diperbarui';
      final isSuccess = res['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        ),
      );

      if (isSuccess) _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showFullPhoto(String? url) {
    if (url == null || url.isEmpty) return;
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
                      : const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    size: 120,
                    color: Colors.grey,
                  ),
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

  void _showFullDokumen(String? url) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.description_rounded,
                      size: 32,
                      color: Color(0xFFF59E0B),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Dokumen Pendukung',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text(
                            'Gagal memuat dokumen',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Tutup', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.grey[800],
                  ),
                ),
              ],
            ),
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
        return const Color(0xFF6B7280);
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

  Widget _buildPresensiCard(
    Map<String, dynamic> item, {
    bool showActions = false,
  }) {
    final baseUrl = ApiService.baseUrl;
    final fotoUrl = item['selfie']?.toString().isNotEmpty == true
        ? '$baseUrl/selfie/${item['selfie']}'
        : null;
    final dokumenUrl = item['dokumen']?.toString().isNotEmpty == true
        ? '$baseUrl/dokumen/${item['dokumen']}'
        : null;

    final jenisColor = _getJenisColor(item['jenis'] ?? '');
    final status = item['status'] ?? 'Waiting';
    final statusColor = _getStatusColor(status);

    final created = DateTime.parse(
      item['created_at'] ?? DateTime.now().toIso8601String(),
    );
    final formattedDate = DateFormat('dd MMMM yyyy, HH:mm').format(created);

    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [Colors.white, jenisColor.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon besar
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
                    color: jenisColor.withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _getJenisIcon(item['jenis'] ?? ''),
                  size: 48,
                  color: jenisColor,
                ),
              ),
              const SizedBox(width: 32),

              // Foto selfie
              if (fotoUrl != null)
                GestureDetector(
                  onTap: () => _showFullPhoto(fotoUrl),
                  child: Hero(
                    tag: 'photo_${fotoUrl.hashCode}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        fotoUrl,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              if (fotoUrl != null) const SizedBox(width: 32),

              // Informasi utama
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['jenis'] ?? 'Tidak ada jenis',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waktu: $formattedDate',
                      style: const TextStyle(fontSize: 18, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Keterangan: ${item['keterangan'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item['informasi']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'Informasi: ${item['informasi']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Kolom kanan: Status, Dokumen, Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
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
                      icon: const Icon(Icons.attach_file_rounded, size: 20),
                      label: const Text(
                        'Lihat Dokumen',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],

                  if (showActions) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(item['id'].toString(), 'Disetujui'),
                          icon: const Icon(Icons.thumb_up, size: 22),
                          label: const Text(
                            'Setujui',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 6,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _updateStatus(item['id'].toString(), 'Ditolak'),
                          icon: const Icon(Icons.thumb_down, size: 22),
                          label: const Text(
                            'Tolak',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 6,
                          ),
                        ),
                      ],
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          // Sidebar Kiri
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
                // Header Sidebar
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 60, 32, 40),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'Detail Presensi',
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

                const Divider(color: Colors.white12, height: 1),

                // Menu Tab
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.history_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Riwayat Presensi',
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
                          Icons.pending_actions_rounded,
                          size: 28,
                          color: Colors.white70,
                        ),
                        title: const Text(
                          'Menunggu Persetujuan',
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

          // Konten Utama
          Expanded(
            child: Column(
              children: [
                // Header Atas dengan Tombol Back & Refresh
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Tombol Back
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 32),
                        tooltip: 'Kembali',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        _tabController.index == 0
                            ? 'Riwayat Presensi'
                            : 'Presensi Menunggu Persetujuan',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (_loading)
                        const CircularProgressIndicator(strokeWidth: 3),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh_rounded, size: 24),
                        label: const Text(
                          'Refresh',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body Content
                Expanded(
                  child:
                      _loading && (_history.isEmpty && _waitingPresensi.isEmpty)
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 4),
                        )
                      : TabBarView(
                          controller: _tabController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Tab Riwayat
                            _history.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.history_toggle_off_rounded,
                                          size: 100,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          'Belum ada riwayat presensi',
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(
                                      top: 24,
                                      bottom: 40,
                                    ),
                                    itemCount: _history.length,
                                    itemBuilder: (_, i) => _buildPresensiCard(
                                      _history[i] as Map<String, dynamic>,
                                    ),
                                  ),

                            // Tab Waiting
                            _waitingPresensi.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.pending_actions_rounded,
                                          size: 100,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          'Tidak ada presensi menunggu persetujuan',
                                          style: TextStyle(
                                            fontSize: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.only(
                                      top: 24,
                                      bottom: 40,
                                    ),
                                    itemCount: _waitingPresensi.length,
                                    itemBuilder: (_, i) => _buildPresensiCard(
                                      _waitingPresensi[i]
                                          as Map<String, dynamic>,
                                      showActions: true,
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
    );
  }
}
