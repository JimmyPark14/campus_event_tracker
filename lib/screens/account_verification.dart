import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() => _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen> {
  String _verificationMethod = 'email'; // 'email' or 'phone'
  
  // Phone State
  final TextEditingController _codeController = TextEditingController();
  Timer? _phoneTimer;
  int _phoneSecondsLeft = 60;
  bool _phoneCanResend = false;
  bool _phoneIsVerifying = false;
  String _phoneStatusMessage = '';
  bool _phoneCodeSent = false;

  // Email State
  bool _emailSent = false;
  bool _emailIsChecking = false;
  String _emailStatusMessage = '';

  @override
  void dispose() {
    _phoneTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  // --- Phone Methods ---
  void _startPhoneTimer() {
    setState(() {
      _phoneSecondsLeft = 60;
      _phoneCanResend = false;
    });
    
    _phoneTimer?.cancel();
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phoneSecondsLeft > 0) {
        setState(() {
          _phoneSecondsLeft--;
        });
      } else {
        setState(() {
          _phoneCanResend = true;
          _phoneStatusMessage = 'You can now resend the code.';
        });
        timer.cancel();
      }
    });
  }

  Future<void> _sendPhoneCode() async {
    final authProvider = context.read<AuthProvider>();
    final phone = authProvider.userProfile?.phone;

    if (phone == null || phone.isEmpty) {
      setState(() {
        _phoneStatusMessage = 'No phone number found in profile. Please use email.';
        _phoneCanResend = false;
      });
      return;
    }

    setState(() {
      _phoneStatusMessage = 'Sending code to $phone...';
      _phoneCodeSent = true;
    });

    await authProvider.sendPhoneVerification(
      phone,
      onCodeSent: (verId) {
        if (mounted) {
          setState(() {
            _phoneStatusMessage = 'Code sent! Please enter it below.';
          });
          _startPhoneTimer();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _phoneStatusMessage = 'Error sending code: $error';
            _phoneCanResend = true;
          });
        }
      },
    );
  }

  Future<void> _verifyPhoneCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit code')));
      return;
    }

    setState(() {
      _phoneIsVerifying = true;
      _phoneStatusMessage = 'Verifying...';
    });

    final authProvider = context.read<AuthProvider>();
    try {
      await authProvider.confirmSmsCode(code);
      if (mounted) {
        if (authProvider.userProfile?.role == 'organizer') {
          context.go('/organizer/dashboard');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phoneIsVerifying = false;
          _phoneStatusMessage = 'Verification failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code. Please try again.')));
      }
    }
  }

  // --- Email Methods ---
  Future<void> _sendEmailVerification() async {
    final authProvider = context.read<AuthProvider>();
    setState(() {
      _emailStatusMessage = 'Sending email...';
    });
    try {
      await authProvider.sendEmailVerification();
      if (mounted) {
        setState(() {
          _emailSent = true;
          _emailStatusMessage = 'Verification email sent! Please check your inbox and spam folder.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailStatusMessage = 'Error sending email: $e';
        });
      }
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() {
      _emailIsChecking = true;
      _emailStatusMessage = 'Checking...';
    });
    
    final authProvider = context.read<AuthProvider>();
    try {
      bool isVerified = await authProvider.checkEmailVerified();
      if (mounted) {
        if (isVerified) {
          if (authProvider.userProfile?.role == 'organizer') {
            context.go('/organizer/dashboard');
          } else {
            context.go('/home');
          }
        } else {
          setState(() {
            _emailIsChecking = false;
            _emailStatusMessage = 'Email is not verified yet. Please check your inbox.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailIsChecking = false;
          _emailStatusMessage = 'Error checking status: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Account Verification'),
        automaticallyImplyLeading: false, 
        actions: [
          TextButton(
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.security, size: 64, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Verify Your Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please choose a verification method to secure your account.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Method Selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'email', label: Text('Email'), icon: Icon(Icons.email)),
                  ButtonSegment(value: 'phone', label: Text('Phone (SMS)'), icon: Icon(Icons.phone)),
                ],
                selected: {_verificationMethod},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _verificationMethod = newSelection.first;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Dynamic Content based on selection
              if (_verificationMethod == 'email') _buildEmailSection(),
              if (_verificationMethod == 'phone') _buildPhoneSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_emailStatusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              _emailStatusMessage,
              style: TextStyle(
                color: _emailStatusMessage.contains('Error') || _emailStatusMessage.contains('not verified') ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        if (!_emailSent)
          ElevatedButton.icon(
            onPressed: context.read<AuthProvider>().isLoading ? null : _sendEmailVerification,
            icon: const Icon(Icons.send),
            label: const Text('Send Verification Email'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _emailIsChecking ? null : _checkEmailVerified,
                icon: _emailIsChecking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
                label: Text(_emailIsChecking ? 'Checking...' : 'I have clicked the link'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _sendEmailVerification,
                child: const Text('Resend Email'),
              )
            ],
          ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_phoneCodeSent)
          ElevatedButton.icon(
            onPressed: _sendPhoneCode,
            icon: const Icon(Icons.sms),
            label: const Text('Send SMS Code'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_phoneStatusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _phoneStatusMessage,
                    style: TextStyle(
                      color: _phoneStatusMessage.contains('Error') || _phoneStatusMessage.contains('failed') ? Colors.red : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _phoneIsVerifying ? null : _verifyPhoneCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _phoneIsVerifying 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _phoneCanResend && !_phoneIsVerifying ? _sendPhoneCode : null,
                child: Text(
                  _phoneCanResend ? 'Resend Code' : 'Resend Code in ${_phoneSecondsLeft}s',
                  style: TextStyle(color: _phoneCanResend ? Theme.of(context).colorScheme.primary : Colors.grey),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
