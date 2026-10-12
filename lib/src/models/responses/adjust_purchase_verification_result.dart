/// The result of a purchase verification request sent to Adjust.
///
/// Returned by [Adjust.verifyAppStorePurchase],
/// [Adjust.verifyAndTrackAppStorePurchase], [Adjust.verifyPlayStorePurchase],
/// and [Adjust.verifyAndTrackPlayStorePurchase].
///
/// Inspect [verificationStatus] and [code] to determine whether the purchase
/// was verified successfully.
class AdjustPurchaseVerificationResult {
  /// A numeric status code for the verification result.
  ///
  /// Common values:
  /// - `200` – The purchase was verified successfully.
  /// - `206` – The purchase was not verified (no determination).
  /// - `400` – The request contained invalid data.
  /// - `500` – An internal server error occurred.
  final num code;

  /// A human-readable message describing the verification result.
  final String message;

  /// A string token describing the overall verification status.
  ///
  /// Common values are `'PASS'`, `'FAIL'`, and `'NOT_VERIFIED'`.
  final String verificationStatus;

  /// Creates an [AdjustPurchaseVerificationResult] with the given [code],
  /// [message], and [verificationStatus].
  AdjustPurchaseVerificationResult(this.code, this.message, this.verificationStatus);

  /// Creates an [AdjustPurchaseVerificationResult] from a raw map received
  /// from the native SDK.
  factory AdjustPurchaseVerificationResult.fromMap(dynamic map) {
    try {
      final int parsedCode = int.tryParse(map['code']?.toString() ?? '') ?? -1;

      return AdjustPurchaseVerificationResult(
          parsedCode,
          map['message'] ?? '',
          map['verificationStatus'] ?? '');
    } catch (e) {
      throw Exception(
          '[AdjustFlutter]: Failed to create AdjustPurchaseVerificationResult object from given map object. Details: ' +
              e.toString());
    }
  }

  /// This result as a map, keyed like the map received from the native SDK.
  Map<String, String?> get toMap {
    Map<String, String?> verificationInfoMap = <String, String?>{};

    verificationInfoMap['code'] = code.toString();
    verificationInfoMap['message'] = message;
    verificationInfoMap['verificationStatus'] = verificationStatus;

    return verificationInfoMap;
  }
}
