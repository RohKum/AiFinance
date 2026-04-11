import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aifin/core/constants/app_constants.dart';
import 'package:aifin/routes/route_names.dart';
import 'package:aifin/core/providers/user_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        
        await ref.read(userProvider.notifier).login(email, password);
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RouteNames.dashboard);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.expenseRed),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(userProvider.notifier).loginWithGoogle();
      
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RouteNames.dashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In aborted or failed.', style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.expenseRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 60),
              // App Logo / Header
              const Icon(Icons.auto_awesome, size: 70, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'AiFin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                'Your AI Financial Assistant',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              // Animated Premium Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Login to manage your finances safely.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 15),
                          ),
                          const SizedBox(height: 40),
                          
                          // Secure Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGradientStart),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryGradientStart, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Email is required';
                              if (!value.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Secure Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(color: Colors.grey[600]),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGradientStart),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                                },
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryGradientStart, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Password is required';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primaryGradientStart, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Loading-Aware Gradient Submit Button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGradientStart.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? () {} : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading 
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          // OR Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Google Login Button
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _loginWithGoogle,
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/768px-Google_%22G%22_logo.svg.png',
                              height: 24,
                            ),
                            label: const Text('Sign in with Google', style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          // Dynamic Route Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Don\'t have an account?', style: TextStyle(color: Colors.grey[600])),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, RouteNames.signup),
                                child: const Text('Sign Up', style: TextStyle(color: AppColors.primaryGradientEnd, fontWeight: FontWeight.bold)),
                              ),
                            ],
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
}
