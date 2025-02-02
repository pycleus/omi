import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:friend_private/backend/http/api/stripe_connect.dart';
import 'package:friend_private/gen/assets.gen.dart';
import 'package:friend_private/utils/alerts/app_snackbar.dart';
import 'package:friend_private/widgets/animated_loading_button.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeCOnnectSetup extends StatefulWidget {
  const StripeCOnnectSetup({super.key});

  @override
  State<StripeCOnnectSetup> createState() => _StripeCOnnectSetupState();
}

class _StripeCOnnectSetupState extends State<StripeCOnnectSetup> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Timer _pollTimer;
  bool _isOnboardingComplete = false;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startPolling() {
    setState(() {
      _isPolling = true;
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      var res = await isStripeOnboardingComplete();
      setState(() {
        _isOnboardingComplete = res;
      });

      if (_isOnboardingComplete) {
        timer.cancel();
      }
    });
  }

  void _onboardingComplete() {
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isPolling) {
      _pollTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    Assets.images.herologo.path,
                    width: 26,
                    color: Colors.black,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-18, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: Color(0xFF635BFF),
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      Assets.images.stripeLogo,
                      width: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (!_isPolling && !_isOnboardingComplete) ...[
              const Text(
                'Get paid for your app sales through Stripe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildFeatureRow(
                icon: Icons.payments_rounded,
                title: 'Monthly payouts',
                description: 'Receive monthly payments directly to your account when you reach \$10 in earnings',
              ),
              const SizedBox(height: 24),
              _buildFeatureRow(
                icon: Icons.shield_outlined,
                title: 'Secure and reliable',
                description: 'Stripe ensures safe and timely transfers of your app revenue',
              ),
              const Spacer(),
              Text(
                'By clicking on "Connect Now" you agree to the',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse('https://stripe.com/connect-account/legal'));
                },
                child: const Text(
                  'Stripe Connected Account Agreement',
                  style: TextStyle(
                    color: Color(0xFF635BFF),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AnimatedLoadingButton(
                text: "Connect Now",
                loaderColor: Colors.black,
                onPressed: () async {
                  var res = await getStripeAccountLink();
                  if (res != null) {
                    await launchUrl(Uri.parse(res['url']));
                    _startPolling();
                  } else {
                    AppSnackbar.showSnackbarError("Error connecting to Stripe! Please try again later.");
                  }
                },
                color: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ],
            if (_isPolling && !_isOnboardingComplete) ...[
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF635BFF),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF635BFF).withOpacity(0.5),
                          blurRadius: 20 * _pulseController.value,
                          spreadRadius: 10 * _pulseController.value,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sync,
                        color: Color(0xFF635BFF),
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              const Text(
                'Connecting your Stripe account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please complete the Stripe onboarding process in your browser. This page will automatically update once completed.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (!_isPolling && _isOnboardingComplete) ...[
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF635BFF).withOpacity(0.15),
                      Colors.purple.shade900.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF635BFF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF635BFF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF635BFF),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '🎉 Successfully Connected!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your Stripe account is now ready to receive payments. You can start earning from your app sales right away.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              AnimatedLoadingButton(
                text: "Done",
                onPressed: () async {
                  _onboardingComplete();
                },
                color: const Color(0xFF635BFF),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                width: MediaQuery.of(context).size.width * 0.8,
              ),
            ],
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF635BFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF635BFF),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
