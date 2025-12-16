// pages/register_page.dart
// VERSI FINAL – ENHANCED: Simple Elegant UI with subtle gradients, neumorphic elements, smooth transitions for premium feel (FIXED: Dropdown overflow with isDense & Flexible wrapping)

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

  final String _role = 'user';
  bool _isKaryawan = false;
  bool _isLoading = false;
  bool _obscure = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

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
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameC.dispose();
    _namaC.dispose();
    _nipNisnC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.register(
        username: _usernameC.text.trim(),
        namaLengkap: _namaC.text.trim(),
        nipNisn: _isKaryawan ? '' : _nipNisnC.text.trim(),
        password: _passwordC.text.trim(),
        role: _role,
        isKaryawan: _isKaryawan,
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi berhasil! Silakan login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                // borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
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
        SnackBar(
          content: Text(
            msg,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Daftar Akun Baru',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF3B82F6),
                const Color(0xFF3B82F6).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF3B82F6).withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Header Logo
                      Hero(
                        tag: 'register_logo',
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Skaduta Presensi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Buat akun untuk mulai presensi',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Username
                                _buildInputField(
                                  controller: _usernameC,
                                  label: 'Username',
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.text,
                                  validator: (v) => v?.trim().isEmpty == true
                                      ? 'Username wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Nama Lengkap
                                _buildInputField(
                                  controller: _namaC,
                                  label: 'Nama Lengkap',
                                  icon: Icons.account_circle_outlined,
                                  keyboardType: TextInputType.text,
                                  validator: (v) => v?.trim().isEmpty == true
                                      ? 'Nama wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Checkbox Karyawan
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    value: _isKaryawan,
                                    onChanged: (val) => setState(
                                      () => _isKaryawan = val ?? false,
                                    ),
                                    title: const Text(
                                      'Saya Karyawan',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'NIP/NIK tidak wajib diisi',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    activeColor: const Color(0xFF3B82F6),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // NIP/NIK (conditional)
                                if (!_isKaryawan)
                                  _buildInputField(
                                    controller: _nipNisnC,
                                    label: 'NIP / NIK',
                                    icon: Icons.credit_card_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v?.trim().isEmpty == true
                                        ? 'NIP/NIK wajib diisi'
                                        : null,
                                  ),
                                if (!_isKaryawan) const SizedBox(height: 20),

                                // Password
                                _buildInputField(
                                  controller: _passwordC,
                                  label: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscure,
                                  validator: (v) {
                                    if (v?.isEmpty == true) {
                                      return 'Password wajib diisi';
                                    }
                                    if (v!.length < 4) {
                                      return 'Minimal 4 karakter';
                                    }
                                    return null;
                                  },
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Role Dropdown (FIXED: Added isDense & Flexible for overflow prevention)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  // child: DropdownButtonHideUnderline(
                                  //   child: DropdownButtonFormField<String>(
                                  //     value: _role,
                                  //     isDense: true, // FIXED: Prevents overflow
                                  //     decoration: InputDecoration(
                                  //       labelText: 'Role',
                                  //       labelStyle: const TextStyle(
                                  //         fontSize: 18,
                                  //         color: Color(0xFF6B7280),
                                  //       ),
                                  //       prefixIcon: const Icon(
                                  //         Icons.shield_outlined,
                                  //         color: Color(0xFF3B82F6),
                                  //       ),
                                  //       border: InputBorder.none,
                                  //       contentPadding:
                                  //           const EdgeInsets.symmetric(
                                  //             vertical: 16,
                                  //           ),
                                  //     ),
                                  //     style: const TextStyle(
                                  //       fontSize: 18,
                                  //       color: Colors.black87,
                                  //     ),
                                  //     // dropdownColor: Colors.white,
                                  //     // // items: const [
                                  //     // //   DropdownMenuItem(
                                  //     // //     value: 'user',
                                  //     // //     child: Text('User (Karyawan / Guru)'),
                                  //     // //   ),
                                  //     // //   DropdownMenuItem(
                                  //     // //     value: 'admin',
                                  //     // //     child: Text('Admin'),
                                  //     // //   ),
                                  //     // //   DropdownMenuItem(
                                  //     // //     value: 'superadmin',
                                  //     // //     child: Text('Super Admin'),
                                  //     // //   ),
                                  //     // // ],
                                  //     // onChanged: (val) =>
                                  //     //     setState(() => _role = val!),
                                  //   ),
                                  // ),
                                ),
                                const SizedBox(height: 32),

                                // Register Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 60,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                      shadowColor: const Color(
                                        0xFF3B82F6,
                                      ).withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            'DAFTAR SEKARANG',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Login Link
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Sudah punya akun? '),
                                        TextSpan(
                                          text: 'Login di sini',
                                          style: TextStyle(
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
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Tips Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6).withOpacity(0.1),
                              Colors.white.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 24,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tips Registrasi:\n• Gunakan username unik\n• Password minimal 4 karakter',
                              style: TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 14,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
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
      ),
    );
  }

  // Helper for Input Fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
          prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        style: const TextStyle(fontSize: 18),
        validator: validator,
      ),
    );
  }
}
