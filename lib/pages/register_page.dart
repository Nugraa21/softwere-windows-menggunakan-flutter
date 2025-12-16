// lib/pages/register_page.dart (VERSI DESKTOP / WINDOWS - LEBIH LEBAR & ELEGAN)

import 'package:flutter/material.dart';
import '../api/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _namaC = TextEditingController();
  final _nipNisnC = TextEditingController();
  final _passwordC = TextEditingController();

  String _selectedStatus = 'Karyawan';
  bool _isLoading = false;
  bool _obscure = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameC.dispose();
    _namaC.dispose();
    _nipNisnC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  bool get _isKaryawan => _selectedStatus == 'Karyawan';

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isKaryawan && _nipNisnC.text.trim().isEmpty) {
      _showSnack('NIP/NISN wajib diisi untuk Guru atau Staff Lain');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.register(
        username: _usernameC.text.trim(),
        namaLengkap: _namaC.text.trim(),
        nipNisn: _isKaryawan ? '' : _nipNisnC.text.trim(),
        password: _passwordC.text.trim(),
        role: 'user',
        status: _selectedStatus,
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      } else {
        _showSnack(res['message'] ?? 'Gagal mendaftar');
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 20,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              margin: const EdgeInsets.all(40),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(60, 48, 60, 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo & Title
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Skaduta Presensi',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _usernameC,
                            label: 'Username',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Username wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          _buildInputField(
                            controller: _namaC,
                            label: 'Nama Lengkap',
                            icon: Icons.account_circle_outlined,
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Dropdown Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Status Pegawai',
                                labelStyle: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                ),
                                prefixIcon: const Icon(
                                  Icons.work_outline_rounded,
                                  color: Color(0xFF3B82F6),
                                ),
                                border: InputBorder.none,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Karyawan',
                                  child: Text('Karyawan (NIP opsional)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Guru',
                                  child: Text('Guru (NIP wajib)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Staff Lain',
                                  child: Text('Staff Lain (NIP wajib)'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedStatus = val!),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (!_isKaryawan)
                            _buildInputField(
                              controller: _nipNisnC,
                              label: 'NIP / NISN (wajib)',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => v?.trim().isEmpty == true
                                  ? 'NIP/NISN wajib diisi'
                                  : null,
                            ),
                          if (!_isKaryawan) const SizedBox(height: 24),

                          _buildInputField(
                            controller: _passwordC,
                            label: 'Password',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscure,
                            validator: (v) {
                              if (v?.isEmpty == true)
                                return 'Password wajib diisi';
                              if (v!.length < 6) return 'Minimal 6 karakter';
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                elevation: 10,
                                shadowColor: const Color(
                                  0xFF3B82F6,
                                ).withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 4,
                                      ),
                                    )
                                  : const Text(
                                      'DAFTAR SEKARANG',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Color(0xFF6B7280),
                                ),
                                children: [
                                  const TextSpan(text: 'Sudah punya akun? '),
                                  TextSpan(
                                    text: 'Login di sini',
                                    style: const TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 18, color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6), size: 28),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2.5),
        ),
      ),
      style: const TextStyle(fontSize: 18),
      validator: validator,
    );
  }
}
