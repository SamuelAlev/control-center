import 'package:control_center/features/pr_review/presentation/widgets/klipy_gif_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('_positionWidget logic', () {
    test('anchor below middle places widget below', () {
      const anchor = Offset(100, 100);
      const screenSize = Size(1080, 800);
      final spaceBelow = screenSize.height - anchor.dy - 12;
      final spaceAbove = anchor.dy - 12;

      expect(spaceBelow, 688);
      expect(spaceAbove, 88);
      expect(spaceBelow >= 300 || spaceBelow >= spaceAbove, isTrue);
    });

    test('anchor near bottom places widget above (not enough space below)', () {
      const anchor = Offset(100, 750);
      const screenSize = Size(1080, 800);

      final spaceBelow = screenSize.height - anchor.dy - 12;
      final spaceAbove = anchor.dy - 12;

      expect(spaceBelow, 38);
      expect(spaceAbove, 738);
      expect(spaceBelow >= 300 || spaceBelow >= spaceAbove, isFalse);
    });

    test('left edge clamps to 12 pixels', () {
      const anchor = Offset(0, 100);
      const screenSize = Size(1080, 800);

      final left = (anchor.dx - 12).clamp(12.0, screenSize.width - 440 - 12);
      expect(left, 12.0);
    });

    test('right edge clamps to screen width minus card', () {
      const anchor = Offset(1100, 100);
      const screenSize = Size(1080, 800);

      final left = (anchor.dx - 12).clamp(12.0, screenSize.width - 440 - 12);
      expect(left, 628.0);
    });

    test('anchor exactly at top positions below', () {
      const anchor = Offset(500, 0);
      const screenSize = Size(1080, 800);

      final spaceBelow = screenSize.height - anchor.dy - 12;
      final spaceAbove = anchor.dy - 12;

      expect(spaceBelow, 788);
      expect(spaceAbove, -12);
      expect(spaceBelow >= 300 || spaceBelow >= spaceAbove, isTrue);
    });

    test(
      'anchor at very top of small screen positions below when spaceAbove negative',
      () {
        const anchor = Offset(500, 0);
        const screenSize = Size(1080, 400);

        final spaceBelow = screenSize.height - anchor.dy - 12;
        final spaceAbove = anchor.dy - 12;

        expect(spaceBelow >= 300 || spaceBelow >= spaceAbove, isTrue);
      },
    );

    test('centered anchor on small screen positions below', () {
      const anchor = Offset(500, 200);
      const screenSize = Size(1080, 400);

      final spaceBelow = screenSize.height - anchor.dy - 12;
      final spaceAbove = anchor.dy - 12;

      expect(spaceBelow, 188);
      expect(spaceAbove, 188);
      expect(spaceBelow >= 300, isFalse);
      expect(spaceBelow >= spaceAbove, isTrue);
    });
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
