import 'package:adjust_ia_sdk_flutter/adjust_ia_sdk_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdjustLinkData.parse', () {
    test('reads path and custom parameters from a branded link', () {
      final data = AdjustLinkData.parse(
        'https://ihreapotheken.go.link/terminbuchung?adj_t=abc123&apothekeId=2163&adj_label=appointment_booking',
      )!;

      expect(data.path, 'terminbuchung');
      expect(data.parameters, {'apothekeId': '2163'});
      expect(data.label, 'appointment_booking');
      expect(data.linkToken, 'abc123');
    });

    test('unwraps a resolved short link that carries the destination in adj_link', () {
      final data = AdjustLinkData.parse(
        'https://brandname.go.link/?adj_t=def456&adj_link=https%3A%2F%2Fexample.com%2Fsummer-clothes%3Fpromo%3Dbeach',
      )!;

      expect(data.destinationUri.toString(), 'https://example.com/summer-clothes?promo=beach');
      expect(data.path, 'summer-clothes');
      expect(data.parameters, {'promo': 'beach'});
      expect(data.linkToken, 'def456');
    });

    test('treats the host of a custom scheme link as the first path segment', () {
      final data = AdjustLinkData.parse('example://summer-clothes?promo=beach&adj_t=def456')!;

      expect(data.pathSegments, ['summer-clothes']);
      expect(data.parameters, {'promo': 'beach'});
      expect(data.linkToken, 'def456');
    });

    test('reads custom scheme links with an empty host and nested paths', () {
      expect(AdjustLinkData.parse('example:///terminbuchung?apothekeId=1')!.path, 'terminbuchung');
      expect(AdjustLinkData.parse('example://apotheke/terminbuchung')!.pathSegments, ['apotheke', 'terminbuchung']);
    });

    test('unwraps a platform-specific destination in adj_deep_link', () {
      final data = AdjustLinkData.parse(
        'https://brandname.go.link/?adj_t=def456&adj_deep_link=example%3A%2F%2Fandroid-specific-path%3Fparam%3Dvalue',
      )!;

      expect(data.path, 'android-specific-path');
      expect(data.parameters, {'param': 'value'});
    });

    test('prefers adj_deep_link over adj_link when both are present', () {
      final data = AdjustLinkData.parse(
        'https://brandname.go.link/?adj_link=https%3A%2F%2Fexample.com%2Fweb&adj_deep_link=example%3A%2F%2Fapp',
      )!;

      expect(data.path, 'app');
    });

    test('unwraps deep_link and reads long-form parameters on Adjust long links', () {
      final data = AdjustLinkData.parse(
        'https://app.adjust.com/abc123?campaign=qr&label=appointment_booking'
        '&deep_link=iaapp%3A%2F%2Fterminbuchung%3FapothekeId%3D2163'
        '&redirect=https%3A%2F%2Fihreapotheken.de%2Fapotheke%2F2163',
      )!;

      expect(data.path, 'terminbuchung');
      expect(data.parameters, {'apothekeId': '2163'});
      expect(data.label, 'appointment_booking');
      expect(data.campaign, 'qr');
    });

    test('treats EU data residency long links as Adjust links', () {
      final data = AdjustLinkData.parse(
        'https://app.eu.adjust.com/abc123?adgroup=2163&deep_link=https%3A%2F%2Fihreapotheken.de%2Fapothekewahlen%3FapothekeId%3D2163',
      )!;

      expect(data.path, 'apothekewahlen');
      expect(data.parameters, {'apothekeId': '2163'});
      expect(data.adgroup, '2163');
    });

    test('keeps long-form names as custom parameters outside Adjust domains', () {
      final data = AdjustLinkData.parse('https://ihreapotheken.de/apothekewahlen?apothekeId=2163&label=x&campaign=y')!;

      expect(data.path, 'apothekewahlen');
      expect(data.parameters, {'apothekeId': '2163', 'label': 'x', 'campaign': 'y'});
      expect(data.label, isNull);
      expect(data.campaign, isNull);
    });

    test('decodes parameter values', () {
      final data = AdjustLinkData.parse('example://apotheke?name=Apotheke%20am%20Markt&city=K%C3%B6ln')!;

      expect(data.parameters, {'name': 'Apotheke am Markt', 'city': 'Köln'});
    });

    test('lets destination parameters override the wrapping link', () {
      final data = AdjustLinkData.parse(
        'https://brandname.go.link/?source=outer&adj_link=https%3A%2F%2Fexample.com%2Fpage%3Fsource%3Dinner',
      )!;

      expect(data.parameters, {'source': 'inner'});
    });

    test('ignores a wrapped value that is not an absolute URL', () {
      final data = AdjustLinkData.parse('https://brandname.go.link/page?adj_link=not-a-url')!;

      expect(data.path, 'page');
      expect(data.destinationUri, data.originalUri);
    });

    test('returns null for missing, empty or relative links', () {
      expect(AdjustLinkData.parse(null), isNull);
      expect(AdjustLinkData.parse(''), isNull);
      expect(AdjustLinkData.parse('   '), isNull);
      expect(AdjustLinkData.parse('/terminbuchung?apothekeId=1'), isNull);
    });

    test('does not throw on malformed percent-encoding', () {
      final data = AdjustLinkData.parse('example://page?broken=%E0%A4%A');

      expect(data, isNotNull);
      expect(data!.path, 'page');
    });
  });
}
