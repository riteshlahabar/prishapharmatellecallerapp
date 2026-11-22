import 'package:url_launcher/url_launcher.dart';

/// Hands a number to the phone's dialler.
///
/// Opens the dialler rather than placing the call: no telephony permission,
/// and the telecaller still sees the number before it rings. Returns false
/// if nothing on the device can handle it — a tablet with no SIM, say — so
/// the caller can say so instead of silently doing nothing.
class Dialer {
  const Dialer();

  Future<bool> call(String? number) async {
    final digits = (number ?? '').replaceAll(RegExp(r'[^0-9+]'), '');

    if (digits.isEmpty) return false;

    return launchUrl(
      Uri(scheme: 'tel', path: digits),
      mode: LaunchMode.externalApplication,
    );
  }
}
