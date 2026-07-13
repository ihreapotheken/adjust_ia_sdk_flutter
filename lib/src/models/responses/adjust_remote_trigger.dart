/// A remote trigger received from the Adjust backend.
///
/// Delivered to [AdjustConfig.remoteTriggerCallback] whenever the backend
/// sends a remote trigger as part of a response. One callback is fired per
/// trigger, in the order received.
class AdjustRemoteTrigger {
  /// The label identifying the type of remote trigger.
  final String label;

  /// The trigger payload, encoded as a JSON string.
  final String payloadJson;

  /// Creates an [AdjustRemoteTrigger] with the provided fields.
  AdjustRemoteTrigger({
    required this.label,
    required this.payloadJson,
  });

  /// Creates an [AdjustRemoteTrigger] from a raw map received from the native
  /// SDK.
  factory AdjustRemoteTrigger.fromMap(dynamic map) {
    try {
      final String? label = map['label'];
      final dynamic payloadJson = map['payloadJson'];

      return AdjustRemoteTrigger(
        label: label ?? '',
        payloadJson: payloadJson is String && payloadJson.isNotEmpty ? payloadJson : '{}',
      );
    } catch (e) {
      throw Exception(
          '[AdjustFlutter]: Failed to create AdjustRemoteTrigger object from given map object. Details: ' +
              e.toString());
    }
  }
}
