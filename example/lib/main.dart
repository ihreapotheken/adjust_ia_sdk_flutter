import 'package:adjust_ia_sdk_flutter/adjust_ia_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AdjustExampleApp());
}

class AdjustExampleApp extends StatelessWidget {
  const AdjustExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adjust Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const String _eventTokenSimple = 'g3mfiw';
  static const String _eventTokenRevenue = 'a4fd35';
  static const String _eventTokenCallback = '34vgg9';
  static const String _eventTokenPartner = 'w788qs';
  
  static const String _appToken = '2fm9gkqubvpc';
  static const AdjustEnvironment _environment = AdjustEnvironment.sandbox;
  static const AdjustLogLevel _logLevel = AdjustLogLevel.verbose;
  
  static const Color _adjustNavy = Color(0xFF1B2951);
  static const Color _adjustNavyLight = Color(0xFF2A3A5C);
  
  String _toggleButtonText = 'Toggle SDK';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAdjustSdk();
    _updateToggleButtonText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeAdjustSdk() async {
    setState(() => _isLoading = true);
    
    try {
      final config = AdjustConfig(_appToken, _environment);
      config.logLevel = _logLevel;

      config.attributionCallback = _handleAttributionCallback;
      
      config.sessionSuccessCallback = _handleSessionSuccess;
      config.sessionFailureCallback = _handleSessionFailure;
      
      config.eventSuccessCallback = _handleEventSuccess;
      config.eventFailureCallback = _handleEventFailure;
      
      config.deferredDeeplinkCallback = _handleDeferredDeeplink;
      
      config.skanUpdatedCallback = _handleSkanUpdate;

      _setupGlobalParameters();

      Adjust.initSdk(config);
      
      debugPrint('[AdjustExample]: SDK initialized successfully');
    } catch (e) {
      debugPrint('[AdjustExample]: Failed to initialize SDK: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupGlobalParameters() {
    Adjust.addGlobalCallbackParameter('scp_foo_1', 'scp_bar');
    Adjust.addGlobalCallbackParameter('scp_foo_2', 'scp_value');
    Adjust.addGlobalPartnerParameter('spp_foo_1', 'spp_bar');
    Adjust.addGlobalPartnerParameter('spp_foo_2', 'spp_value');
    
    // demonstrate parameter removal
    Adjust.removeGlobalCallbackParameter('scp_foo_1');
    Adjust.removeGlobalPartnerParameter('spp_foo_1');
    
    // clear all parameters (for demonstration)
    Adjust.removeGlobalCallbackParameters();
    Adjust.removeGlobalPartnerParameters();
  }

  void _handleAttributionCallback(AdjustAttribution attribution) {
    debugPrint('[AdjustExample]: Attribution changed!');
    
    final attributionData = <String, String?>{
      'Tracker token': attribution.trackerToken,
      'Tracker name': attribution.trackerName,
      'Campaign': attribution.campaign,
      'Network': attribution.network,
      'Creative': attribution.creative,
      'Adgroup': attribution.adgroup,
      'Click label': attribution.clickLabel,
      'Cost type': attribution.costType,
      'Cost amount': attribution.costAmount?.toString(),
      'Cost currency': attribution.costCurrency,
      'FB install referrer': attribution.fbInstallReferrer,
    };

    attributionData.forEach((key, value) {
      if (value != null) {
        debugPrint('[AdjustExample]: $key: $value');
      }
    });

    if (attribution.jsonResponse != null) {
      debugPrint('[AdjustExample]: JSON response: ${attribution.jsonResponse}');
    }
  }

  void _handleSessionSuccess(AdjustSessionSuccess sessionSuccess) {
    debugPrint('[AdjustExample]: Session tracking success!');
    _logSessionData('Success', sessionSuccess.message, sessionSuccess.timestamp, 
                   sessionSuccess.adid, sessionSuccess.jsonResponse);
  }

  void _handleSessionFailure(AdjustSessionFailure sessionFailure) {
    debugPrint('[AdjustExample]: Session tracking failure!');
    _logSessionData('Failure', sessionFailure.message, sessionFailure.timestamp, 
                   sessionFailure.adid, sessionFailure.jsonResponse);
    
    if (sessionFailure.willRetry != null) {
      debugPrint('[AdjustExample]: Will retry: ${sessionFailure.willRetry}');
    }
  }

  void _logSessionData(String type, String? message, String? timestamp, 
                      String? adid, String? jsonResponse) {
    if (message != null) debugPrint('[AdjustExample]: Message: $message');
    if (timestamp != null) debugPrint('[AdjustExample]: Timestamp: $timestamp');
    if (adid != null) debugPrint('[AdjustExample]: Adid: $adid');
    if (jsonResponse != null) debugPrint('[AdjustExample]: JSON response: $jsonResponse');
  }

  void _handleEventSuccess(AdjustEventSuccess eventSuccess) {
    debugPrint('[AdjustExample]: Event tracking success!');
    _logEventData('Success', eventSuccess.eventToken, eventSuccess.message, 
                 eventSuccess.timestamp, eventSuccess.adid, eventSuccess.callbackId, 
                 eventSuccess.jsonResponse, null);
  }

  void _handleEventFailure(AdjustEventFailure eventFailure) {
    debugPrint('[AdjustExample]: Event tracking failure!');
    _logEventData('Failure', eventFailure.eventToken, eventFailure.message, 
                 eventFailure.timestamp, eventFailure.adid, eventFailure.callbackId, 
                 eventFailure.jsonResponse, eventFailure.willRetry);
  }

  void _logEventData(String type, String? eventToken, String? message, 
                    String? timestamp, String? adid, String? callbackId, 
                    String? jsonResponse, bool? willRetry) {
    if (eventToken != null) debugPrint('[AdjustExample]: Event token: $eventToken');
    if (message != null) debugPrint('[AdjustExample]: Message: $message');
    if (timestamp != null) debugPrint('[AdjustExample]: Timestamp: $timestamp');
    if (adid != null) debugPrint('[AdjustExample]: Adid: $adid');
    if (callbackId != null) debugPrint('[AdjustExample]: Callback ID: $callbackId');
    if (willRetry != null) debugPrint('[AdjustExample]: Will retry: $willRetry');
    if (jsonResponse != null) debugPrint('[AdjustExample]: JSON response: $jsonResponse');
  }

  void _handleDeferredDeeplink(String? uri) {
    debugPrint('[AdjustExample]: Received deferred deeplink: $uri');
  }

  void _handleSkanUpdate(Map<String, String> skanData) {
    debugPrint('[AdjustExample]: Received SKAN update information!');
    
    final skanFields = {
      'conversion_value': 'Conversion value',
      'coarse_value': 'Coarse value',
      'lock_window': 'Lock window',
      'error': 'Error',
    };

    skanFields.forEach((key, description) {
      if (skanData[key] != null) {
        debugPrint('[AdjustExample]: $description: ${skanData[key]}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adjust Example',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: _adjustNavy,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_adjustNavy, _adjustNavyLight],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 32),
                
                if (_isLoading)
                  _buildLoadingSection()
                else
                  _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.analytics_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Adjust SDK Demo',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Explore the full functionality of the Adjust SDK\nwith this example application',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Column(
      children: [
        const CircularProgressIndicator(
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          'Initializing Adjust SDK...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Event Tracking'),
        const SizedBox(height: 16),
        _buildActionButton('Track Simple Event', Icons.touch_app, _trackSimpleEvent),
        const SizedBox(height: 12),
        _buildActionButton('Track Revenue Event', Icons.monetization_on, _trackRevenueEvent),
        const SizedBox(height: 12),
        _buildActionButton('Track Callback Event', Icons.call_made, _trackCallbackEvent),
        const SizedBox(height: 12),
        _buildActionButton('Track Partner Event', Icons.handshake, _trackPartnerEvent),
        
        const SizedBox(height: 32),
        
        _buildSectionHeader('Device Information'),
        const SizedBox(height: 16),
        _buildActionButton('Get Google AdId', Icons.android, _getGoogleAdId),
        const SizedBox(height: 12),
        _buildActionButton('Get Adjust Identifier', Icons.alternate_email, _getAdjustIdentifier),
        const SizedBox(height: 12),
        _buildActionButton('Get IDFA', Icons.phone_iphone, _getIdfa),
        const SizedBox(height: 12),
        _buildActionButton('Get Attribution', Icons.analytics, _getAttribution),
        
        const SizedBox(height: 32),
        
        _buildSectionHeader('SDK Control'),
        const SizedBox(height: 16),
        _buildActionButton(_toggleButtonText, Icons.power_settings_new, _toggleSdkState),
        const SizedBox(height: 12),
        _buildActionButton('Is Enabled?', Icons.help_outline, _checkIfSdkEnabled),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _adjustNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  void _updateToggleButtonText() {
    try {
      Adjust.isEnabled().then((isEnabled) {
        if (mounted) {
          setState(() {
            _toggleButtonText = isEnabled ? 'Disable SDK' : 'Enable SDK';
          });
        }
      });
    } on PlatformException {
      // keep default text if method not found
    }
  }

  void _toggleSdkState() {
    try {
      Adjust.isEnabled().then((isEnabled) {
        if (isEnabled) {
          Adjust.disable();
          debugPrint('[AdjustExample]: SDK disabled');
          _showDialog('SDK State', 'Adjust SDK has been disabled');
        } else {
          Adjust.enable();
          debugPrint('[AdjustExample]: SDK enabled');
          _showDialog('SDK State', 'Adjust SDK has been enabled');
        }
        _updateToggleButtonText();
      });
    } on PlatformException {
      _showDialog('Toggle SDK', 'No such method found in plugin: isEnabled');
    }
  }

  void _checkIfSdkEnabled() {
    try {
      Adjust.isEnabled().then((isEnabled) {
        _showDialog('SDK Enabled?', 'Adjust is enabled = $isEnabled');
      });
    } on PlatformException {
      _showDialog('SDK Enabled?', 'No such method found in plugin: isEnabled');
    }
  }

  void _trackSimpleEvent() {
    final event = AdjustEvent(_eventTokenSimple);
    Adjust.trackEvent(event);
    debugPrint('[AdjustExample]: Simple event tracked');
  }

  void _trackRevenueEvent() {
    final event = AdjustEvent(_eventTokenRevenue);
    event.setRevenue(100.0, 'EUR');
    event.transactionId = 'DummyTransactionId';
    Adjust.trackEvent(event);
    debugPrint('[AdjustExample]: Revenue event tracked (€100.00)');
  }

  void _trackCallbackEvent() {
    final event = AdjustEvent(_eventTokenCallback);
    event.addCallbackParameter('key1', 'value1');
    event.addCallbackParameter('key2', 'value2');
    Adjust.trackEvent(event);
    debugPrint('[AdjustExample]: Callback event tracked with parameters');
  }

  void _trackPartnerEvent() {
    final event = AdjustEvent(_eventTokenPartner);
    event.addPartnerParameter('foo1', 'bar1');
    event.addPartnerParameter('foo2', 'bar2');
    Adjust.trackEvent(event);
    debugPrint('[AdjustExample]: Partner event tracked with parameters');
  }

  void _getGoogleAdId() {
    Adjust.getGoogleAdId().then((googleAdId) {
      _showDialog('Google Advertising ID', 'Received Google Advertising Id:\n$googleAdId');
    });
  }

  void _getAdjustIdentifier() {
    Adjust.getAdid().then((adid) {
      _showDialog('Adjust Identifier', 'Received Adjust identifier:\n$adid');
    });
  }

  void _getIdfa() {
    Adjust.getIdfa().then((idfa) {
      _showDialog('IDFA', 'Received IDFA:\n$idfa');
    });
  }

  void _getAttribution() {
    Adjust.getAttribution().then((attribution) {
      final attributionFields = {
        'Tracker token': attribution.trackerToken,
        'Tracker name': attribution.trackerName,
        'Campaign': attribution.campaign,
        'Network': attribution.network,
        'Creative': attribution.creative,
        'Adgroup': attribution.adgroup,
        'Click label': attribution.clickLabel,
        'Cost type': attribution.costType,
        'Cost amount': attribution.costAmount?.toString(),
        'Cost currency': attribution.costCurrency,
        'FB install referrer': attribution.fbInstallReferrer,
      };

      String attributionInfo = 'Attribution data:\n\n';
      attributionFields.forEach((key, value) {
        if (value != null) {
          attributionInfo += '$key: $value\n';
        }
      });

      if (attribution.jsonResponse != null) {
        attributionInfo += '\nJSON response: ${attribution.jsonResponse}';
      }
        
      _showDialog('Attribution', attributionInfo);
    });
  }

  void _showDialog(String title, String message) {
    debugPrint('[AdjustExample]: $title - $message');
    
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: _adjustNavy,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: _adjustNavy,
              ),
              child: const Text(
                'OK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}
