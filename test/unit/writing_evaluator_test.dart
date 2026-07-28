import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning/features/writing/models/stroke.dart';
import 'package:japanese_learning/features/writing/models/stroke_point.dart';
import 'package:japanese_learning/features/writing/models/stroke_template.dart';
import 'package:japanese_learning/features/writing/services/writing_evaluator.dart';

const Size _canvas = Size(300, 300);
const Rect _expectedBox = Rect.fromLTRB(30, 30, 270, 270);

Stroke _strokeAcross(Offset from, Offset to) => _stroke(<Offset>[from, to]);

Stroke _stroke(List<Offset> points) {
  final DateTime now = DateTime(2026, 1, 1);
  return Stroke(
    points: <StrokePoint>[
      for (final Offset p in points) StrokePoint(position: p, timestamp: now),
    ],
  );
}

/// A straight reference stroke in normalized 0–1 space.
StrokeTemplate _template(Offset from, Offset to, {int samples = 16}) {
  return StrokeTemplate(
    points: <Offset>[
      for (int i = 0; i < samples; i++)
        Offset.lerp(from, to, i / (samples - 1))!,
    ],
  );
}

/// Maps reference templates onto the canvas — i.e. a flawless trace.
List<Stroke> _perfectTrace(List<StrokeTemplate> reference) => <Stroke>[
  for (final StrokeTemplate t in reference) _stroke(t.scaledTo(_canvas)),
];

double _score(
  List<Stroke> strokes,
  List<StrokeTemplate>? reference, {
  int? expectedStrokeCount,
}) {
  const WritingEvaluator evaluator = WritingEvaluator();
  return evaluator
      .evaluate(
        strokes: strokes,
        expectedStrokeCount: expectedStrokeCount ?? reference?.length ?? 0,
        expectedBoundingBox: _expectedBox,
        canvasSize: _canvas,
        isDrawingCompleted: strokes.isNotEmpty,
        referenceStrokes: reference,
      )
      .accuracy;
}

/// A plain cross — two strokes, unambiguous geometry.
List<StrokeTemplate> get _cross => <StrokeTemplate>[
  _template(const Offset(0.1, 0.5), const Offset(0.9, 0.5)),
  _template(const Offset(0.5, 0.1), const Offset(0.5, 0.9)),
];

Map<String, List<StrokeTemplate>> _loadRealStrokeData() {
  final Map<String, dynamic> raw =
      jsonDecode(File('assets/data/stroke_data.json').readAsStringSync())
          as Map<String, dynamic>;
  final Map<String, dynamic> characters =
      raw['characters'] as Map<String, dynamic>;
  return <String, List<StrokeTemplate>>{
    for (final MapEntry<String, dynamic> e in characters.entries)
      e.key: <StrokeTemplate>[
        for (final dynamic s in e.value as List<dynamic>)
          StrokeTemplate.fromJson(s as List<dynamic>),
      ],
  };
}

void main() {
  group('WritingEvaluator', () {
    const WritingEvaluator evaluator = WritingEvaluator();

    test('empty, incomplete drawing scores at (or near) zero', () {
      final result = evaluator.evaluate(
        strokes: const <Stroke>[],
        expectedStrokeCount: 3,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        canvasSize: const Size(200, 200),
        isDrawingCompleted: false,
      );

      expect(result.accuracy, 0);
      expect(result.strokeCountCorrect, isFalse);
      expect(result.completed, isFalse);
      expect(result.feedbackMessage, contains('Keep practicing'));
    });

    test('accuracy is always clamped between 0 and 1', () {
      final result = evaluator.evaluate(
        strokes: <Stroke>[
          _strokeAcross(const Offset(-500, -500), const Offset(500, 500)),
        ],
        expectedStrokeCount: 1,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 10, 10),
        canvasSize: const Size(100, 100),
        isDrawingCompleted: true,
      );

      expect(result.accuracy, inInclusiveRange(0, 1));
    });

    test('wrong stroke count is reflected in feedback', () {
      final result = evaluator.evaluate(
        strokes: <Stroke>[
          _strokeAcross(const Offset(0, 0), const Offset(50, 50)),
        ],
        expectedStrokeCount: 5,
        expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
        canvasSize: const Size(100, 100),
        isDrawingCompleted: true,
      );

      expect(result.strokeCountCorrect, isFalse);
      expect(result.feedbackMessage, contains('matching the stroke count'));
    });

    group('shape matching (BUG-006)', () {
      test('a faithful trace scores excellently', () {
        expect(_score(_perfectTrace(_cross), _cross), greaterThan(0.9));
      });

      test('random scribbles score very low even with the right count', () {
        final math.Random rng = math.Random(11);
        final List<Stroke> scribble = <Stroke>[
          for (int s = 0; s < 2; s++)
            _stroke(<Offset>[
              for (int i = 0; i < 14; i++)
                Offset(
                  30 + rng.nextDouble() * 240,
                  30 + rng.nextDouble() * 240,
                ),
            ]),
        ];
        expect(_score(scribble, _cross), lessThan(0.2));
      });

      test(
        'a single diagonal line does not pass for a two-stroke character',
        () {
          final double score = _score(<Stroke>[
            _strokeAcross(const Offset(30, 30), const Offset(270, 270)),
          ], _cross);
          expect(score, lessThan(0.3));
        },
      );

      test('two dots in opposite corners score near zero', () {
        final double score = _score(<Stroke>[
          _stroke(const <Offset>[Offset(30, 30), Offset(33, 33)]),
          _stroke(const <Offset>[Offset(267, 267), Offset(270, 270)]),
        ], _cross);
        expect(score, lessThan(0.2));
      });

      test('missing strokes are penalised', () {
        final List<Stroke> half = _perfectTrace(_cross).take(1).toList();
        final double score = _score(half, _cross);
        expect(score, lessThan(0.5));
        expect(score, lessThan(_score(_perfectTrace(_cross), _cross)));
      });

      test('extra strokes are penalised', () {
        final List<Stroke> withExtra = <Stroke>[
          ..._perfectTrace(_cross),
          _stroke(const <Offset>[Offset(40, 250), Offset(260, 60)]),
        ];
        expect(
          _score(withExtra, _cross),
          lessThan(_score(_perfectTrace(_cross), _cross)),
        );
      });

      test('correct shapes in the wrong order lose marks but keep credit', () {
        final double inOrder = _score(_perfectTrace(_cross), _cross);
        final double outOfOrder = _score(
          _perfectTrace(_cross).reversed.toList(),
          _cross,
        );

        expect(outOfOrder, lessThan(inOrder));
        // Right shapes, wrong sequence still beats an unrelated scribble.
        expect(outOfOrder, greaterThan(0.3));
      });

      test('a stroke drawn backwards is flagged and costs marks', () {
        final List<Stroke> reversedFirst = <Stroke>[
          _stroke(_cross[0].scaledTo(_canvas).reversed.toList()),
          _stroke(_cross[1].scaledTo(_canvas)),
        ];
        final result = evaluator.evaluate(
          strokes: reversedFirst,
          expectedStrokeCount: 2,
          expectedBoundingBox: _expectedBox,
          canvasSize: _canvas,
          isDrawingCompleted: true,
          referenceStrokes: _cross,
        );

        expect(result.feedbackMessage, contains('wrong direction'));
        expect(
          result.accuracy,
          lessThan(_score(_perfectTrace(_cross), _cross)),
        );
      });

      test('writing every stroke backwards costs far more than one slip', () {
        final List<Stroke> allReversed = <Stroke>[
          for (final StrokeTemplate t in _cross)
            _stroke(t.scaledTo(_canvas).reversed.toList()),
        ];
        final List<Stroke> oneReversed = <Stroke>[
          _stroke(_cross[0].scaledTo(_canvas).reversed.toList()),
          _stroke(_cross[1].scaledTo(_canvas)),
        ];

        final double all = _score(allReversed, _cross);
        final double one = _score(oneReversed, _cross);
        final double none = _score(_perfectTrace(_cross), _cross);

        expect(all, lessThan(one));
        expect(one, lessThan(none));
        // Shapes are flawless, so this is purely a technique penalty — but it
        // must be a real one, not the old flat 15% ceiling.
        expect(all, lessThan(0.6));
      });

      test('repeated wrong directions cannot reach the top band', () {
        final List<Stroke> allReversed = <Stroke>[
          for (final StrokeTemplate t in _cross)
            _stroke(t.scaledTo(_canvas).reversed.toList()),
        ];
        expect(_score(allReversed, _cross), lessThan(0.75));
      });

      test(
        'a symmetric stroke drawn correctly is not flagged as backwards',
        () {
          // A single centred horizontal line: forward and reversed readings are
          // close, so a marginless comparison would flip on noise.
          final List<StrokeTemplate> dash = <StrokeTemplate>[
            _template(const Offset(0.2, 0.5), const Offset(0.8, 0.5)),
          ];
          final result = evaluator.evaluate(
            strokes: _perfectTrace(dash),
            expectedStrokeCount: 1,
            expectedBoundingBox: _expectedBox,
            canvasSize: _canvas,
            isDrawingCompleted: true,
            referenceStrokes: dash,
          );

          expect(result.feedbackMessage, isNot(contains('wrong direction')));
          expect(result.accuracy, greaterThan(0.9));
        },
      );

      test('a correct character written small still scores well', () {
        // Same shape, half size, shifted — normalization should absorb this.
        final List<Stroke> small = <Stroke>[
          for (final StrokeTemplate t in _cross)
            _stroke(<Offset>[
              for (final Offset p in t.scaledTo(_canvas))
                Offset(p.dx * 0.5 + 20, p.dy * 0.5 + 60),
            ]),
        ];
        expect(_score(small, _cross), greaterThan(0.85));
      });

      test('accidental taps are filtered instead of scored as strokes', () {
        final List<Stroke> withSpecks = <Stroke>[
          ..._perfectTrace(_cross),
          _stroke(const <Offset>[Offset(150, 150), Offset(151, 150.5)]),
        ];
        // The speck is discarded, so this still reads as a clean 2-stroke cross.
        expect(_score(withSpecks, _cross), greaterThan(0.9));
      });
    });

    group('incomplete drawings (Milestone 22, Issue 1)', () {
      test('a single dot scores zero, not a lucky partial match', () {
        final double score = _score(<Stroke>[
          _stroke(const <Offset>[Offset(150, 150), Offset(151, 151)]),
        ], _cross);
        expect(score, 0);
      });

      test(
        'a single dot produces "too small" feedback, not a shape verdict',
        () {
          final result = evaluator.evaluate(
            strokes: <Stroke>[
              _stroke(const <Offset>[Offset(150, 150), Offset(151, 151)]),
            ],
            expectedStrokeCount: 2,
            expectedBoundingBox: _expectedBox,
            canvasSize: _canvas,
            isDrawingCompleted: true,
            referenceStrokes: _cross,
          );
          expect(result.feedbackMessage, contains('too small to count'));
        },
      );

      test('an extremely short stroke scores zero', () {
        // Below _denoise's own noise-length threshold, same as a dot.
        final double score = _score(<Stroke>[
          _strokeAcross(const Offset(150, 150), const Offset(152, 151)),
        ], _cross);
        expect(score, 0);
      });

      test('one full stroke out of three expected scores well under half', () {
        final List<StrokeTemplate> threeStrokes = <StrokeTemplate>[
          ..._cross,
          _template(const Offset(0.2, 0.2), const Offset(0.8, 0.8)),
        ];
        final double score = _score(
          _perfectTrace(threeStrokes).take(1).toList(),
          threeStrokes,
        );
        expect(
          score,
          lessThan(0.35),
          reason:
              'one accurate stroke out of three is incomplete, not '
              'roughly-a-third correct',
        );
      });

      test(
        'a faithful full-length trace is unaffected by the completion check',
        () {
          // Guards the completion factor itself: a complete attempt must not
          // be penalised by the new gate — covered here directly rather than
          // relying only on the pre-existing "faithful trace" test above.
          expect(_score(_perfectTrace(_cross), _cross), greaterThan(0.9));
        },
      );
    });

    group('without reference geometry', () {
      test('cannot award a confident high score', () {
        final result = evaluator.evaluate(
          strokes: <Stroke>[
            _strokeAcross(const Offset(0, 0), const Offset(100, 100)),
          ],
          expectedStrokeCount: 1,
          expectedBoundingBox: const Rect.fromLTWH(0, 0, 100, 100),
          canvasSize: const Size(100, 100),
          isDrawingCompleted: true,
        );

        expect(result.strokeCountCorrect, isTrue);
        expect(result.completed, isTrue);
        expect(result.accuracy, greaterThan(0.5));
        expect(result.accuracy, lessThanOrEqualTo(0.6));
        expect(result.feedbackMessage, contains('stroke count is correct'));
        expect(result.feedbackMessage, contains('guides are unavailable'));
      });
    });

    group('against the bundled KanjiVG data', () {
      final Map<String, List<StrokeTemplate>> data = _loadRealStrokeData();

      test('every lesson character has reference strokes', () {
        for (final String script in <String>['hiragana', 'katakana', 'kanji']) {
          final Map<String, dynamic> lessons =
              jsonDecode(
                    File(
                      'assets/data/${script}_lessons.json',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          for (final dynamic lesson in lessons['lessons'] as List<dynamic>) {
            for (final dynamic c
                in (lesson as Map<String, dynamic>)['characters']
                    as List<dynamic>) {
              final String symbol =
                  (c as Map<String, dynamic>)['character'] as String;
              expect(
                data.containsKey(symbol),
                isTrue,
                reason: 'no stroke data for $symbol ($script)',
              );
            }
          }
        }
      });

      test('real glyphs: faithful trace scores high, scribble scores low', () {
        for (final String symbol in <String>['あ', 'ア', '学', 'の']) {
          final List<StrokeTemplate> reference = data[symbol]!;
          final math.Random rng = math.Random(3);
          final List<Stroke> scribble = <Stroke>[
            for (int s = 0; s < reference.length; s++)
              _stroke(<Offset>[
                for (int i = 0; i < 14; i++)
                  Offset(
                    30 + rng.nextDouble() * 240,
                    30 + rng.nextDouble() * 240,
                  ),
              ]),
          ];

          expect(
            _score(_perfectTrace(reference), reference),
            greaterThan(0.9),
            reason: 'faithful trace of $symbol should score high',
          );
          expect(
            _score(scribble, reference),
            lessThan(0.2),
            reason: 'scribble for $symbol should score low',
          );
        }
      });
    });
  });
}
