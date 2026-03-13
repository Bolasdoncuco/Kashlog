import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/biometric_service.dart';
import '../utils/constants.dart';
import '../widgets/neumorphic_container.dart';
import 'home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PinScreen extends StatefulWidget {
  final bool isSettingPin;
  const PinScreen({super.key, this.isSettingPin = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (!widget.isSettingPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkBiometrics();
      });
    }
  }

  Future<void> _checkBiometrics() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isBiometricEnabled) {
      // Small delay to ensure the UI is ready and visible
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      final authenticated = await BiometricService.authenticate();
      if (authenticated) {
        _onAuthenticated();
      }
    }
  }

  void _onAuthenticated() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _handleKeyPress(String value) {
    setState(() {
      _errorMessage = '';
      if (value == 'back') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < 4) _pin += value;
      }

      if (_pin.length == 4) {
        _processPin();
      }
    });
  }

  void _processPin() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (widget.isSettingPin) {
      if (!_isConfirming) {
        _confirmPin = _pin;
        _pin = '';
        _isConfirming = true;
      } else {
        if (_pin == _confirmPin) {
          await userProvider.setAppPin(_pin);
          await userProvider.setAppLockEnabled(true);
          
          // Auto-enable biometrics if available and enrolled
          final canBio = await BiometricService.canAuthenticate();
          final enrolled = await BiometricService.hasEnrolledBiometrics();
          
          if (canBio && enrolled) {
            await userProvider.setBiometricEnabled(true);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Huella digital activada automáticamente')),
              );
            }
          } else if (canBio && !enrolled) {
             if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN configurado. Por favor registra una huella en los ajustes de tu teléfono para usar biometría.')),
              );
            }
          }
          
          if (mounted) Navigator.of(context).pop(true);
        } else {
          _pin = '';
          _errorMessage = 'Los PIN no coinciden';
        }
      }
    } else {
      if (_pin == userProvider.appPin) {
        _onAuthenticated();
      } else {
        _pin = '';
        _errorMessage = 'PIN incorrecto';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Icon(Icons.lock_outline_rounded, size: 64, color: primaryColor)
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              widget.isSettingPin
                  ? (_isConfirming ? 'Confirma tu PIN' : 'Crea tu PIN de seguridad')
                  : 'Ingresa tu PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            if (widget.isSettingPin)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Este PIN será tu respaldo si la huella falla',
                  style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
                ),
              ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.lightAlert, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? primaryColor : primaryColor.withOpacity(0.2),
                    boxShadow: isFilled
                        ? [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 10)]
                        : [],
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildKeypad(primaryColor, textColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(Color primaryColor, Color textColor) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Column(
      children: [
        for (var row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) => _buildKey(key, textColor)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Manual biometric button if enabled
            if (!widget.isSettingPin && userProvider.isBiometricEnabled)
              _buildKey('bio', textColor, icon: Icons.fingerprint_rounded)
            else
              const SizedBox(width: 80, height: 80),
            _buildKey('0', textColor),
            _buildKey('back', textColor, icon: Icons.backspace_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, Color textColor, {IconData? icon}) {
    return GestureDetector(
      onTap: () {
        if (value == 'bio') {
          _checkBiometrics();
        } else {
          _handleKeyPress(value);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        width: 80,
        height: 80,
        child: NeumorphicContainer(
          borderRadius: 40,
          padding: EdgeInsets.zero,
          child: Center(
            child: icon != null
                ? Icon(icon, color: textColor)
                : Text(
                    value,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
          ),
        ),
      ),
    );
  }
}
