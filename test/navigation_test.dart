import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akalt/providers/video_provider.dart';
import 'package:akalt/providers/auth_provider.dart';
import 'package:akalt/providers/restaurant_provider.dart';
import 'package:akalt/screens/main_layout.dart';
import 'package:akalt/screens/home/home_feed_screen.dart';
import 'package:akalt/screens/explore/explore_screen.dart';
import 'package:akalt/screens/search/search_screen.dart';
import 'package:akalt/screens/profile/profile_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('MainLayout navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeVideosProvider.overrideWith((ref) => Stream.value([])),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDetailsProvider.overrideWith((ref) => Stream.value(null)),
          allRestaurantsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MainLayout()),
      ),
    );

    await tester.pump();

    // Verify that HomeFeedScreen is initially displayed
    expect(find.byType(HomeFeedScreen), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);

    // Tap on the Explore icon
    await tester.tap(find.byIcon(Icons.map_rounded));
    await tester.pumpAndSettle();

    // Verify that ExploreScreen is displayed
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(HomeFeedScreen), findsNothing);

    // Tap on the Search icon
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Verify that SearchScreen is displayed
    expect(find.byType(SearchScreen), findsOneWidget);

    // Tap on the Profile icon
    await tester.tap(find.byIcon(Icons.person_rounded));
    await tester.pumpAndSettle();

    // Verify that ProfileScreen is displayed
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _createMockImageHttpClient(context);
  }
}

// Returns a mock HTTP client that responds with a blank image to all requests.
HttpClient _createMockImageHttpClient(SecurityContext? _) {
  final MockHttpClient client = MockHttpClient();
  return client;
}

class MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }
}

class MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => kTransparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

const List<int> kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
