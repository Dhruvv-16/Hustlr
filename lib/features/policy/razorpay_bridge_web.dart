/// Web stub — `razorpay_flutter` is not implemented for web (no platform channel).
void initializeRazorpay({
  required void Function(String paymentId) onPaymentSuccess,
  required void Function(String message) onPaymentError,
  required void Function(String walletName) onExternalWallet,
}) {}

void openRazorpay(Map<String, dynamic> options) {}

void disposeRazorpay() {}
