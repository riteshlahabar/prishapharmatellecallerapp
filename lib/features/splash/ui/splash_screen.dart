import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/app_theme.dart';
import '../../../core/constants.dart';
import '../../../core/state/providers.dart';

/// The first screen of the app: the Prisha logo on a pale brand wash while
/// the session is settled.
///
/// It is not decoration for its own sake. `main()` kicks off a profile
/// refresh before the first frame, and without this the app would show the
/// signed-in UI and then yank it away if the account turned out to be
/// disabled. Holding here for a beat lets that answer arrive, and the router
/// then sends the rep straight to the right place.
///
/// [splashDoneProvider] is what releases it; the router watches that flag, so
/// the hold is one piece of state rather than a timer per route.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Long enough to read the logo, short enough not to be in the way.
  static const Duration minimumHold = Duration(milliseconds: 1600);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(SplashScreen.minimumHold, () {
      if (mounted) ref.read(splashDoneProvider.notifier).done();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // The full wordmark, on white: the artwork is drawn for a
              // light background, and on a pale ground it reads as itself
              // rather than as a logo someone has tinted.
              Container(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A174A3F),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 236,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Telecaller',
                style: TextStyle(
                  color: AppTheme.tealDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your queue, your call-backs, in one place',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
              ),
              const Spacer(),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.teal,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
