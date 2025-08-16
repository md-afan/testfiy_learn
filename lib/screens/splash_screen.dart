import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _logoOpacity = 0.0;
  double _textOffset = 40.0;

  late final AnimationController _bgAnimationController;

  /// ✅ Fix: Use untyped subscription to avoid assignment error
  late StreamSubscription _connectivitySubscription;

  bool hasConnection = true;
  bool _navigated = false;

  ImageProvider getLogoImage() {
    return const AssetImage(
      kIsWeb
          ? "assets/images/testify_learn.gif"
          : "assets/images/testify_learn.webp",
    );
  }

  @override
  void initState() {
    super.initState();

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _logoOpacity = 1.0;
          _textOffset = 0.0;
        });
      }
    });

    _checkInitialConnectivity();
    _listenToConnectivityChanges();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (!mounted) return;

    if (result != ConnectivityResult.none) {
      setState(() => hasConnection = true);
      _navigateToHome();
    } else {
      setState(() => hasConnection = false);
      _showNoConnectionSnack();
    }
  }

  void _listenToConnectivityChanges() {
    /// ✅ Works even if stream gives single or list
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((dynamic result) {
      if (!mounted || _navigated) return;

      if (result is ConnectivityResult) {
        if (result != ConnectivityResult.none) {
          setState(() => hasConnection = true);
          _navigateToHome();
        } else {
          setState(() => hasConnection = false);
          _showNoConnectionSnack();
        }
      } else if (result is List<ConnectivityResult>) {
        final first =
            result.isNotEmpty ? result.first : ConnectivityResult.none;
        if (first != ConnectivityResult.none) {
          setState(() => hasConnection = true);
          _navigateToHome();
        } else {
          setState(() => hasConnection = false);
          _showNoConnectionSnack();
        }
      }
    });
  }

  void _showNoConnectionSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No Internet Connection. Please check your connection.'),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToHome() {
    if (_navigated) return;
    _navigated = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final colorAnimation1 = ColorTween(
      begin: scheme.primary.withOpacity(0.6),
      end: scheme.secondary.withOpacity(0.6),
    ).animate(_bgAnimationController);

    final colorAnimation2 = ColorTween(
      begin: scheme.surface.withOpacity(0.6),
      end: scheme.background.withOpacity(0.6),
    ).animate(_bgAnimationController);

    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorAnimation1.value ?? scheme.primary,
                  colorAnimation2.value ?? scheme.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedOpacity(
                    opacity: _logoOpacity,
                    duration: const Duration(seconds: 2),
                    child: Hero(
                      tag: 'app-logo',
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image(
                            image: getLogoImage(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    transform: Matrix4.translationValues(0, _textOffset, 0),
                    curve: Curves.easeOut,
                    child: Text(
                      "Testify Learn",
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(color: Colors.white),
                  if (!hasConnection)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: ElevatedButton.icon(
                        onPressed: _checkInitialConnectivity,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
