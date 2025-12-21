// lib/pages/admin_presensi_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';

class AdminPresensiPage extends StatefulWidget {
  const AdminPresensiPage({super.key});

  @override
  State<AdminPresensiPage> createState() => _AdminPresensiPageState();
}

class _AdminPresensiPageState extends State<AdminPresensiPage> {
  bool _loading = false;
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  String _filterStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPresensi();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPresensi() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getAllPresensi();
      setState(() {
        _items = data ?? [];
        _items.sort((a, b) {
          // Sort berdasarkan created_at jika ada, fallback ke id
          String dateA = a['created_at'] ?? a['id'].toString();
          String dateB = b['created_at'] ?? b['id'].toString();
          return dateB.compareTo(dateA);
        });
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal ambil data presensi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    var temp = _items;

    // Filter status
    if (_filterStatus != 'All') {
      temp = temp
          .where((item) => (item['status'] ?? 'Waiting') == _filterStatus)
          .toList();
    }

    // Filter search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      temp = temp.where((item) {
        final nama = (item['nama_lengkap'] ?? '').toLowerCase();
        final jenis = (item['jenis'] ?? '').toLowerCase();
        final keterangan = (item['keterangan'] ?? '').toLowerCase();
        return nama.contains(query) ||
            jenis.contains(query) ||
            keterangan.contains(query);
      }).toList();
    }

    setState(() {
      _filteredItems = temp;
    });
  }

  Future<void> _deleteAbsensi(String id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hapus Absensi?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Yakin ingin menghapus absensi atas nama:\n\n$nama\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    final res = await ApiService.deleteAbsensi(
      id,
    ); // <-- Sesuai nama method baru
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ??
              (res['status'] == true
                  ? 'Absensi berhasil dihapus'
                  : 'Gagal menghapus absensi'),
        ),
        backgroundColor: res['status'] == true
            ? Colors.green
            : Colors.redAccent,
      ),
    );

    if (res['status'] == true) {
      _loadPresensi();
    } else {
      setState(() => _loading = false);
    }
  }

  IconData _getJenisIconData(String jenis) {
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
      case 'Penugasan':
      case 'Penugasan_Full':
        return Icons.assignment_rounded;
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
      case 'Penugasan':
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

  Future<void> _updateStatus(String id, String newStatus) async {
    final res = await ApiService.updatePresensiStatus(
      id: id,
      status: newStatus,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] ??
              (res['status'] == true
                  ? 'Status berhasil diupdate'
                  : 'Gagal update'),
        ),
        backgroundColor: res['status'] == true
            ? Colors.green
            : Colors.redAccent,
      ),
    );
    if (res['status'] == true) _loadPresensi();
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

  Future<void> _launchInBrowser(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka dokumen')),
        );
      }
    }
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
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.open_in_browser,
                            color: Colors.white,
                          ),
                          onPressed: () => _launchInBrowser(url),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
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
                            onPressed: () => _launchInBrowser(url),
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

  @override
  Widget build(BuildContext context) {
    int countAll = _items.length;
    int countWaiting = _items
        .where((e) => (e['status'] ?? 'Waiting') == 'Waiting')
        .length;
    int countApproved = _items
        .where((e) => (e['status'] ?? 'Waiting') == 'Disetujui')
        .length;
    int countRejected = _items
        .where((e) => (e['status'] ?? 'Waiting') == 'Ditolak')
        .length;

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
                        ),
                        child: const Icon(
                          Icons.how_to_reg_rounded,
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
                              'Persetujuan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Presensi Karyawan',
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        '${_filteredItems.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Total Presensi',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
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
                // HEADER DENGAN SEARCH + FILTER
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 32, 40, 20),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 36,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                padding: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            const Text(
                              'Persetujuan Presensi',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _loadPresensi,
                              icon: const Icon(Icons.refresh_rounded, size: 26),
                              label: const Text(
                                'Refresh',
                                style: TextStyle(fontSize: 18),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 8,
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari nama, jenis, atau keterangan...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Filter Segmented
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SegmentedButton<String>(
                              style: ButtonStyle(
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                textStyle: WidgetStateProperty.all(
                                  const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                iconSize: WidgetStateProperty.all(26),
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? const Color(0xFF3B82F6)
                                          : Colors.transparent,
                                    ),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith(
                                      (states) =>
                                          states.contains(WidgetState.selected)
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                              ),
                              selected: {_filterStatus},
                              onSelectionChanged: (newSelection) {
                                setState(() {
                                  _filterStatus = newSelection.first;
                                  _applyFilters();
                                });
                              },
                              segments: [
                                ButtonSegment<String>(
                                  value: 'All',
                                  icon: const Icon(Icons.list_alt_rounded),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Semua'),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _filterStatus == 'All'
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$countAll',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _filterStatus == 'All'
                                                ? Colors.white
                                                : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ButtonSegment<String>(
                                  value: 'Waiting',
                                  icon: const Icon(Icons.pending_rounded),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Flexible(child: Text('Menunggu')),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _filterStatus == 'Waiting'
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$countWaiting',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _filterStatus == 'Waiting'
                                                ? Colors.white
                                                : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ButtonSegment<String>(
                                  value: 'Disetujui',
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Flexible(child: Text('Disetujui')),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _filterStatus == 'Disetujui'
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$countApproved',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _filterStatus == 'Disetujui'
                                                ? Colors.white
                                                : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ButtonSegment<String>(
                                  value: 'Ditolak',
                                  icon: const Icon(Icons.cancel_rounded),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Ditolak'),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _filterStatus == 'Ditolak'
                                              ? Colors.white.withOpacity(0.3)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$countRejected',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _filterStatus == 'Ditolak'
                                                ? Colors.white
                                                : const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // List Absensi
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                      : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pending_actions_rounded,
                                size: 140,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 40),
                              Text(
                                _searchController.text.isEmpty &&
                                        _filterStatus == 'All'
                                    ? 'Tidak ada data absensi'
                                    : 'Tidak ditemukan absensi yang sesuai',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Coba ubah pencarian atau filter',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(40, 32, 40, 60),
                          itemCount: _filteredItems.length,
                          itemBuilder: (_, i) {
                            final item = _filteredItems[i];
                            final status = item['status'] ?? 'Waiting';
                            final statusColor = _getStatusColor(status);
                            final jenisColor = _getJenisColor(
                              item['jenis'] ?? '',
                            );
                            final created =
                                item['created_at'] ?? item['id'].toString();
                            final formattedDate = item['created_at'] != null
                                ? DateFormat(
                                    'dd MMMM yyyy, HH:mm',
                                  ).format(DateTime.parse(item['created_at']))
                                : 'ID: ${item['id']}';
                            final fotoUrl =
                                item['selfie']?.toString().isNotEmpty == true
                                ? '${ApiService.baseUrl}/selfie/${item['selfie']}'
                                : null;
                            final dokumenUrl =
                                item['dokumen']?.toString().isNotEmpty == true
                                ? '${ApiService.baseUrl}/dokumen/${item['dokumen']}'
                                : null;

                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(bottom: 28),
                                child: Card(
                                  elevation: 12,
                                  shadowColor: jenisColor.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(28),
                                    hoverColor: jenisColor.withOpacity(0.08),
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
                                                color: jenisColor.withOpacity(
                                                  0.5,
                                                ),
                                                width: 3,
                                              ),
                                            ),
                                            child: Icon(
                                              _getJenisIconData(
                                                item['jenis'] ?? '',
                                              ),
                                              size: 48,
                                              color: jenisColor,
                                            ),
                                          ),
                                          const SizedBox(width: 40),
                                          if (fotoUrl != null)
                                            GestureDetector(
                                              onTap: () =>
                                                  _showFullPhoto(fotoUrl),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                child: Image.network(
                                                  fotoUrl,
                                                  width: 140,
                                                  height: 140,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          if (fotoUrl != null)
                                            const SizedBox(width: 40),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Keterangan: ${item['keterangan'] ?? '-'}',
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                if (item['informasi']
                                                        ?.toString()
                                                        .isNotEmpty ==
                                                    true) ...[
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF3B82F6,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Info Penugasan: ${item['informasi']}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Color(
                                                          0xFF1E40AF,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      statusColor.withOpacity(
                                                        0.2,
                                                      ),
                                                      statusColor.withOpacity(
                                                        0.1,
                                                      ),
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  border: Border.all(
                                                    color: statusColor
                                                        .withOpacity(0.5),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      status == 'Disetujui'
                                                          ? Icons
                                                                .check_circle_rounded
                                                          : status == 'Ditolak'
                                                          ? Icons.cancel_rounded
                                                          : Icons
                                                                .pending_rounded,
                                                      color: statusColor,
                                                      size: 28,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      status,
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (dokumenUrl != null) ...[
                                                const SizedBox(height: 20),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      _showFullDokumen(
                                                        dokumenUrl,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.attachment_rounded,
                                                  ),
                                                  label: const Text(
                                                    'Lihat Dokumen',
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor:
                                                        const Color(0xFFF59E0B),
                                                    side: const BorderSide(
                                                      color: Color(0xFFF59E0B),
                                                      width: 2,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 20,
                                                          vertical: 14,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                              if (status == 'Waiting') ...[
                                                const SizedBox(height: 32),
                                                Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _updateStatus(
                                                            item['id']
                                                                .toString(),
                                                            'Disetujui',
                                                          ),
                                                      icon: const Icon(
                                                        Icons.thumb_up,
                                                        size: 22,
                                                      ),
                                                      label: const Text(
                                                        'Setujui',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF10B981,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 32,
                                                              vertical: 18,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    ElevatedButton.icon(
                                                      onPressed: () =>
                                                          _updateStatus(
                                                            item['id']
                                                                .toString(),
                                                            'Ditolak',
                                                          ),
                                                      icon: const Icon(
                                                        Icons.thumb_down,
                                                        size: 22,
                                                      ),
                                                      label: const Text(
                                                        'Tolak',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFFEF4444,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 32,
                                                              vertical: 18,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                30,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 20),
                                              OutlinedButton.icon(
                                                onPressed: () => _deleteAbsensi(
                                                  item['id'].toString(),
                                                  item['nama_lengkap'] ??
                                                      'Karyawan',
                                                ),
                                                icon: const Icon(
                                                  Icons.delete_rounded,
                                                  color: Colors.red,
                                                ),
                                                label: const Text(
                                                  'Hapus Absensi',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: Colors.red,
                                                    width: 2,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 14,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
