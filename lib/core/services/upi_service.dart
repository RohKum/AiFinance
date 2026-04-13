import 'package:url_launcher/url_launcher.dart';

class UPIService {
  /// Generates a UPI payment URI and launches it.
  /// Standard: upi://pay?pa=address&pn=name&am=amount&cu=INR&tn=message
  static Future<void> initiatePayment({
    required String payeeVPA,
    required String payeeName,
    required double amount,
    String? transactionNote,
  }) async {
    final String transactionId =
        'AIFIN${DateTime.now().millisecondsSinceEpoch}';

    final String uriString =
        'upi://pay?pa=$payeeVPA'
        '&pn=${Uri.encodeComponent(payeeName)}'
        '&am=${amount.toStringAsFixed(2)}'
        '&tr=$transactionId'
        '&mc=0000'
        '&cu=INR'
        '${transactionNote != null ? '&tn=${Uri.encodeComponent(transactionNote)}' : ''}';

    final Uri uri = Uri.parse(uriString.trim());

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        throw 'No UPI app found to handle this payment request.';
      }
    } catch (e) {
      throw 'Could not launch UPI apps. Please ensure you have GPay, PhonePe, or any UPI app installed.';
    }
  }
}
