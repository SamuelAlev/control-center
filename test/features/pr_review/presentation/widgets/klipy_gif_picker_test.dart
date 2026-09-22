import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/pr_review/presentation/widgets/klipy_gif_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  group('GifResult', () {
    group('fromJson', () {
      test('parses full HD GIF with all fields', () {
        final json = <String, dynamic>{
          'id': 42,
          'file': {
            'hd': {
              'gif': {
                'url': 'https://example.com/full.gif',
                'width': 480,
                'height': 360,
              },
            },
            'sm': {
              'gif': {
                'url': 'https://example.com/preview.gif',
                'width': 200,
                'height': 150,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.id, 42);
        expect(result.url, 'https://example.com/full.gif');
        expect(result.previewUrl, 'https://example.com/preview.gif');
        expect(result.width, 480);
        expect(result.height, 360);
      });

      test('falls back to sm gif when hd is missing', () {
        final json = <String, dynamic>{
          'id': 7,
          'file': {
            'sm': {
              'gif': {
                'url': 'https://example.com/small.gif',
                'width': 300,
                'height': 200,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.id, 7);
        expect(result.url, 'https://example.com/small.gif');
        expect(result.previewUrl, 'https://example.com/small.gif');
        expect(result.width, 300);
        expect(result.height, 200);
      });

      test('falls back to webp when gif is missing', () {
        final json = <String, dynamic>{
          'id': 3,
          'file': {
            'sm': {
              'webp': {
                'url': 'https://example.com/image.webp',
                'width': 400,
                'height': 300,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.id, 3);
        expect(result.url, 'https://example.com/image.webp');
        expect(result.previewUrl, 'https://example.com/image.webp');
        expect(result.width, 400);
        expect(result.height, 300);
      });

      test('uses jpg for preview when neither gif nor webp available', () {
        final json = <String, dynamic>{
          'id': 1,
          'file': {
            'hd': {
              'gif': {
                'url': 'https://example.com/hd.gif',
                'width': 500,
                'height': 400,
              },
            },
            'sm': {
              'jpg': {
                'url': 'https://example.com/thumb.jpg',
                'width': 100,
                'height': 80,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.url, 'https://example.com/hd.gif');
        expect(result.previewUrl, 'https://example.com/thumb.jpg');
      });

      test('preview falls back to HD gif when sm is null', () {
        final json = <String, dynamic>{
          'id': 10,
          'file': {
            'hd': {
              'gif': {
                'url': 'https://example.com/hd.gif',
                'width': 600,
                'height': 450,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.url, 'https://example.com/hd.gif');
        expect(result.previewUrl, 'https://example.com/hd.gif');
        expect(result.width, 600);
        expect(result.height, 450);
      });

      test('handles id as string', () {
        final json = <String, dynamic>{
          'id': '99',
          'file': {
            'sm': {
              'gif': {
                'url': 'https://example.com/gif.gif',
                'width': 200,
                'height': 200,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.id, 99);
      });

      test('handles invalid id string returning 0', () {
        final json = <String, dynamic>{
          'id': 'not-a-number',
          'file': {
            'sm': {
              'gif': {
                'url': 'https://example.com/gif.gif',
                'width': 200,
                'height': 200,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.id, 0);
      });

      test('handles missing file field', () {
        final json = <String, dynamic>{'id': 0};

        expect(() => GifResult.fromJson(json), throwsA(isA<TypeError>()));
      });

      test('handles empty file object', () {
        final json = <String, dynamic>{'id': 55, 'file': <String, dynamic>{}};

        final result = GifResult.fromJson(json);

        expect(result.id, 55);
        expect(result.url, '');
        expect(result.previewUrl, '');
        expect(result.width, 0);
        expect(result.height, 0);
      });

      test('handles null width/height gracefully', () {
        final json = <String, dynamic>{
          'id': 12,
          'file': {
            'hd': {
              'gif': {'url': 'https://example.com/gif.gif'},
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.width, 0);
        expect(result.height, 0);
      });

      test('handles fractional width/height by truncating', () {
        final json = <String, dynamic>{
          'id': 5,
          'file': {
            'hd': {
              'gif': {
                'url': 'https://example.com/gif.gif',
                'width': 480.7,
                'height': 360.2,
              },
            },
          },
        };

        final result = GifResult.fromJson(json);

        expect(result.width, 480);
        expect(result.height, 360);
      });

      test('all fields populated correctly', () {
        const result = GifResult(
          id: 1,
          url: 'https://example.com/gif.gif',
          previewUrl: 'https://example.com/thumb.gif',
          width: 480,
          height: 360,
        );

        expect(result.id, 1);
        expect(result.url, 'https://example.com/gif.gif');
        expect(result.previewUrl, 'https://example.com/thumb.gif');
        expect(result.width, 480);
        expect(result.height, 360);
      });
    });

    group('fromJson round-trip', () {
      test('stable JSON reprocessing yields same result', () {
        final originalJson = <String, dynamic>{
          'id': 42,
          'file': {
            'hd': {
              'gif': {
                'url': 'https://example.com/full.gif',
                'width': 480,
                'height': 360,
              },
            },
            'sm': {
              'gif': {
                'url': 'https://example.com/preview.gif',
                'width': 200,
                'height': 150,
              },
            },
          },
        };

        final first = GifResult.fromJson(originalJson);
        final second = GifResult.fromJson(originalJson);

        expect(first.id, second.id);
        expect(first.url, second.url);
        expect(first.previewUrl, second.previewUrl);
        expect(first.width, second.width);
        expect(first.height, second.height);
      });
    });
  });

  group('GifPickerPopover', () {
    Finder addGif() => find.byWidgetPredicate(
      (w) => w is CcIconButton && w.tooltip == 'Add GIF',
    );

    Future<void> pumpPicker(WidgetTester tester, {Alignment? alignment}) async {
      final host = FakeRpcHost()
        ..onCall = (op, args) {
          expect(op, anyOf('gif.trending', 'gif.search'));
          return {'gifs': <Map<String, dynamic>>[]};
        };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [rpcClientProvider.overrideWithValue(host.client())],
          child: testWrap(
            Align(
              alignment: alignment ?? Alignment.center,
              child: GifPickerPopover(onGifSelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('opens a panel on the trigger tap', (tester) async {
      await pumpPicker(tester);

      expect(find.byKey(const Key('gif-picker-panel')), findsNothing);

      await tester.tap(addGif());
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('gif-picker-panel')), findsOneWidget);
      expect(find.text('Search GIFs'), findsOneWidget);
    });

    testWidgets('anchors the panel to the trigger, not the overlay origin', (
      tester,
    ) async {
      await pumpPicker(tester, alignment: Alignment.bottomRight);

      await tester.tap(addGif());
      await tester.pump();
      await tester.pump();

      final trigger = tester.getRect(addGif());
      final panel = tester.getRect(find.byKey(const Key('gif-picker-panel')));
      final screen = tester.getSize(find.byType(Overlay).first);

      // The previous OverlayEntry used root-overlay coordinates computed
      // against a nested overlay, which parked a 440px panel at the top-left.
      expect(panel.left, greaterThan(200));
      expect(panel.top, greaterThan(40));
      expect(panel.right, lessThanOrEqualTo(screen.width - 4));
      expect(
        panel.top >= trigger.bottom - 8 || panel.bottom <= trigger.top + 8,
        isTrue,
        reason: 'panel should sit above or below the trigger, not over it',
      );
      expect(
        (panel.right - trigger.right).abs(),
        lessThan(32),
        reason: 'trailing toolbar popover should share the trigger\'s end edge',
      );
    });

    testWidgets(
      'search hint is fully visible without the overlay error underline',
      (tester) async {
        await pumpPicker(tester);

        await tester.tap(addGif());
        await tester.pump();
        await tester.pump();

        final titleStyle = DefaultTextStyle.of(
          tester.element(find.text('Search GIFs')),
        ).style;
        expect(titleStyle.decoration, TextDecoration.none);

        final hint = find.text('Search GIFs...');
        expect(hint, findsOneWidget);
        final hintRect = tester.getRect(hint);
        final fieldRect = tester.getRect(find.byType(CcTextField));
        expect(hintRect.top, greaterThanOrEqualTo(fieldRect.top - 0.5));
        expect(hintRect.bottom, lessThanOrEqualTo(fieldRect.bottom + 0.5));
      },
    );
  });

  group('GifResult - additional edge cases', () {
    test('sm webp fallback for url when hd and sm gif missing', () {
      final json = <String, dynamic>{
        'id': 20,
        'file': {
          'sm': {
            'webp': {
              'url': 'https://example.com/anim.webp',
              'width': 400,
              'height': 300,
            },
          },
        },
      };

      final result = GifResult.fromJson(json);

      expect(result.url, 'https://example.com/anim.webp');
      expect(result.previewUrl, 'https://example.com/anim.webp');
    });

    test('sm jpg preview fallback when no sm gif/webp', () {
      final json = <String, dynamic>{
        'id': 30,
        'file': {
          'hd': {
            'gif': {
              'url': 'https://example.com/hq.gif',
              'width': 640,
              'height': 480,
            },
          },
          'sm': {
            'jpg': {
              'url': 'https://example.com/preview.jpg',
              'width': 160,
              'height': 120,
            },
          },
        },
      };

      final result = GifResult.fromJson(json);

      expect(result.url, 'https://example.com/hq.gif');
      expect(result.previewUrl, 'https://example.com/preview.jpg');
      expect(result.width, 640);
      expect(result.height, 480);
    });

    test('preview falls back to hd gif url when sm is null', () {
      final json = <String, dynamic>{
        'id': 40,
        'file': {
          'hd': {
            'gif': {
              'url': 'https://example.com/hd_gif.gif',
              'width': 800,
              'height': 600,
            },
          },
        },
      };

      final result = GifResult.fromJson(json);

      expect(result.previewUrl, 'https://example.com/hd_gif.gif');
    });

    test('all sm fields null falls back gracefully', () {
      final json = <String, dynamic>{
        'id': 50,
        'file': {
          'hd': {
            'gif': {
              'url': 'https://example.com/gif.gif',
              'width': 100,
              'height': 100,
            },
          },
          'sm': <String, dynamic>{},
        },
      };

      final result = GifResult.fromJson(json);

      expect(result.url, 'https://example.com/gif.gif');
      expect(result.previewUrl, 'https://example.com/gif.gif');
    });
  });
}
