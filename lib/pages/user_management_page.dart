// lib/pages/user_management_page.dart - DIPERBAIKI ERROR null safety di nipNisn
import 'package:flutter/material.dart';
import 'dart:async';
import '../api/api_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  final TextEditingController _searchC = TextEditingController();
  Timer? _debounce;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _loadUsers();
    _searchC.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.removeListener(_onSearchChanged);
    _searchC.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getUsers();
      final filtered = (data as List).where((u) {
        final role = (u['role']?.toString().toLowerCase() ?? '');
        return role == 'user' || role == 'admin' || role == 'superadmin';
      }).toList();

      setState(() {
        _users = filtered;
        _filteredUsers = filtered
          ..sort(
            (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
              (b['nama_lengkap'] ?? '').toString(),
            ),
          );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat user: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterUsers() {
    final query = _searchC.text.toLowerCase().trim();
    setState(() {
      _filteredUsers =
          query.isEmpty
                ? List.from(_users)
                : _users.where((u) {
                    final nama = (u['nama_lengkap'] ?? '')
                        .toString()
                        .toLowerCase();
                    final username = (u['username'] ?? '')
                        .toString()
                        .toLowerCase();
                    final nip = (u['nip_nisn']?.toString() ?? '').toLowerCase();
                    return nama.contains(query) ||
                        username.contains(query) ||
                        nip.contains(query);
                  }).toList()
            ..sort(
              (a, b) => (a['nama_lengkap'] ?? '').toString().compareTo(
                (b['nama_lengkap'] ?? '').toString(),
              ),
            );
    });
  }

  // ================== RESET DEVICE ID ==================
  Future<void> _resetDevice(String userId, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.phonelink_erase_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text(
              'Reset Device ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Yakin reset device untuk "$nama"?\nUser harus login ulang di HP baru.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.resetDeviceId(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Device ID berhasil direset'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  // ================== TAMBAH USER BARU ==================
  Future<void> _addUser() async {
    final usernameC = TextEditingController();
    final namaC = TextEditingController();
    final nipC = TextEditingController();
    final passC = TextEditingController();
    String selectedRole = 'user';
    String selectedStatus = 'Karyawan';
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.person_add_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
              SizedBox(width: 16),
              Text(
                'Tambah User Baru',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameC,
                    decoration: InputDecoration(
                      labelText: 'Username *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: namaC,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap *',
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // === FIELD NIP/NISN HANYA MUNCUL JIKA STATUS = GURU ===
                  if (selectedStatus == 'Guru')
                    TextField(
                      controller: nipC,
                      decoration: InputDecoration(
                        labelText: 'NIP/NISN * (wajib untuk Guru)',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  if (selectedStatus == 'Guru') const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      prefixIcon: const Icon(Icons.shield_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'superadmin',
                        child: Text('Super Admin'),
                      ),
                    ],
                    onChanged: (val) =>
                        setStateDialog(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Status
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status Pegawai',
                      prefixIcon: const Icon(Icons.work_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Karyawan',
                        child: Text('Karyawan'),
                      ),
                      DropdownMenuItem(value: 'Guru', child: Text('Guru')),
                      DropdownMenuItem(
                        value: 'Staff Lain',
                        child: Text('Staff Lain'),
                      ),
                    ],
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedStatus = val!;
                        // Reset NIP kalau status bukan Guru
                        if (selectedStatus != 'Guru') {
                          nipC.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passC,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validasi field wajib
                      if (usernameC.text.trim().isEmpty ||
                          namaC.text.trim().isEmpty ||
                          passC.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Field bertanda * wajib diisi'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                        return;
                      }

                      // Khusus Guru: NIP wajib diisi
                      if (selectedStatus == 'Guru' &&
                          nipC.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('NIP/NISN wajib diisi untuk Guru'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                        return;
                      }

                      setStateDialog(() => isLoading = true);

                      try {
                        final res = await ApiService.register(
                          username: usernameC.text.trim(),
                          namaLengkap: namaC.text.trim(),
                          password: passC.text,
                          nipNisn: selectedStatus == 'Guru'
                              ? nipC.text.trim()
                              : '', // Kalau bukan Guru, kirim string kosong
                          role: selectedRole,
                          status: selectedStatus,
                        );

                        if (res['status'] == true ||
                            res['status'] == 'success') {
                          Navigator.pop(ctx);
                          _loadUsers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User berhasil ditambahkan'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message'] ?? 'Gagal tambah user',
                              ),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Color(0xFFEF4444),
                          ),
                        );
                      } finally {
                        if (mounted) setStateDialog(() => isLoading = false);
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Tambah User'),
            ),
          ],
        ),
      ),
    );
  }

  // ================== EDIT USER ==================
  Future<void> _editUser(Map<String, dynamic> user) async {
    final usernameC = TextEditingController(text: user['username']);
    final namaC = TextEditingController(text: user['nama_lengkap'] ?? '');
    final nipC = TextEditingController(text: user['nip_nisn'] ?? '');
    final passC = TextEditingController();
    String? selectedRole = (user['role'] ?? 'user').toString().toLowerCase();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Color(0xFF3B82F6), size: 32),
            SizedBox(width: 16),
            Text(
              'Edit User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameC,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: namaC,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nipC,
                  decoration: InputDecoration(
                    labelText: 'NIP/NISN (opsional)',
                    prefixIcon: const Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: const Icon(Icons.shield),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('Super Admin'),
                    ),
                  ],
                  onChanged: (val) => selectedRole = val,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passC,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password Baru (kosongkan jika tidak ganti)',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final res = await ApiService.updateUser(
                  id: user['id'].toString(),
                  username: usernameC.text.trim(),
                  namaLengkap: namaC.text.trim(),
                  nipNisn: nipC.text.trim(),
                  role: selectedRole,
                  password: passC.text.isEmpty ? null : passC.text.trim(),
                );

                if (res['status'] == true || res['status'] == 'success') {
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User berhasil diperbarui'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(res['message'] ?? 'Gagal update'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Color(0xFFEF4444),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ================== HAPUS USER ==================
  // ================== HAPUS USER ==================
  Future<void> _deleteUser(String id, String role, String nama) async {
    // Ambil role user yang sedang login
    final currentUser = await ApiService.getCurrentUser();
    final currentRole = currentUser?['role'] ?? 'user';

    // Hanya superadmin yang boleh menghapus
    if (currentRole != 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya superadmin yang boleh menghapus user'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Superadmin tidak boleh hapus superadmin lain
    if ((role ?? '').toString().toLowerCase() == 'superadmin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak boleh menghapus akun superadmin'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 12),
            Text('Hapus User', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus user "$nama"?\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.deleteUser(id);

      if (res['status'] == true || res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'User berhasil dihapus'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadUsers(); // Refresh daftar user
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Gagal menghapus user'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFFEF4444);
      case 'admin':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF10B981);
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'SUPER ADMIN';
      case 'admin':
        return 'ADMIN';
      default:
        return 'USER';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(28, 60, 28, 40),
                  child: Text(
                    'Kelola User',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        '${_filteredUsers.length}',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Total Akun',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: ElevatedButton.icon(
                    onPressed: _addUser,
                    icon: const Icon(Icons.person_add_rounded, size: 28),
                    label: const Text(
                      'Tambah User Baru',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
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
                          icon: const Icon(Icons.arrow_back_rounded, size: 32),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: EdgeInsets.all(16),
                          ),
                        ),
                        const SizedBox(width: 32),
                        const Text(
                          'Manajemen User & Admin',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _searchC,
                            decoration: InputDecoration(
                              hintText: 'Cari nama, username, NIP/NISN...',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 28,
                              ),
                              suffixIcon: _searchC.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: _searchC.clear,
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 18,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 32),
                        ElevatedButton.icon(
                          onPressed: _loadUsers,
                          icon: const Icon(Icons.refresh_rounded, size: 24),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
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

                  // List User
                  Expanded(
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF3B82F6),
                            ),
                          )
                        : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _searchC.text.isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.people_outline_rounded,
                                  size: 120,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  _searchC.text.isNotEmpty
                                      ? 'Tidak ditemukan user'
                                      : 'Belum ada user terdaftar',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(40, 32, 40, 60),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (ctx, i) {
                              final u = _filteredUsers[i];
                              final role = (u['role'] ?? 'user')
                                  .toString()
                                  .toLowerCase();
                              final roleColor = _getRoleColor(role);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roleColor.withOpacity(0.12),
                                      blurRadius: 25,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: roleColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              roleColor,
                                              roleColor.withOpacity(0.7),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            (u['username'] ?? '?')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 40),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u['nama_lengkap'] ?? 'Tanpa Nama',
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            if (u['username'] != null)
                                              Text(
                                                'Username: ${u['username']}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            if (u['nip_nisn']
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                              Text(
                                                'NIP/NISN: ${u['nip_nisn']}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                ),
                                              ),
                                            const SizedBox(height: 20),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 32,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: roleColor.withOpacity(
                                                  0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                border: Border.all(
                                                  color: roleColor.withOpacity(
                                                    0.6,
                                                  ),
                                                  width: 3,
                                                ),
                                              ),
                                              child: Text(
                                                _getRoleLabel(role),
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () => _editUser(u),
                                            icon: const Icon(
                                              Icons.edit_rounded,
                                              size: 32,
                                            ),
                                            color: const Color(0xFF3B82F6),
                                            tooltip: 'Edit',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.blue[50],
                                              padding: const EdgeInsets.all(16),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          IconButton(
                                            onPressed: () => _deleteUser(
                                              u['id'].toString(),
                                              role,
                                              u['nama_lengkap'] ??
                                                  u['username'] ??
                                                  'User',
                                            ),
                                            icon: const Icon(
                                              Icons.delete_rounded,
                                              size: 32,
                                            ),
                                            color: Colors.red,
                                            tooltip: 'Hapus',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red[50],
                                              padding: const EdgeInsets.all(16),
                                            ),
                                          ),
                                          if (role == 'user')
                                            const SizedBox(width: 12),
                                          if (role == 'user')
                                            IconButton(
                                              onPressed: () => _resetDevice(
                                                u['id'].toString(),
                                                u['nama_lengkap'] ??
                                                    u['username'],
                                              ),
                                              icon: const Icon(
                                                Icons.phonelink_erase_rounded,
                                                size: 32,
                                              ),
                                              color: Colors.orange,
                                              tooltip: 'Reset Device ID',
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange[50],
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                              ),
                                            ),
                                        ],
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
          ),
        ],
      ),
    );
  }
}
