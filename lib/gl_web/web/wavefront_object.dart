import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import 'vbo.dart';

class Face {
  final List<int> vertexIndices;
  final List<int> texCoordIndices;
  final List<int> normalIndices;

  Face({
    required this.vertexIndices,
    required this.texCoordIndices,
    required this.normalIndices,
  });

  static Face parse(String objLine) {
    final chunks = objLine
        .substring(2)
        .split(' ')
        .map((e) => e.split('/').map((e) => (int.tryParse(e) ?? 1) - 1));

    if (chunks.length != 3) {
      throw Exception('Only triangular faces are supported');
    }

    final vertexIndices = [
      chunks.elementAt(0).elementAt(0),
      chunks.elementAt(1).elementAt(0),
      chunks.elementAt(2).elementAt(0),
    ];

    final texCoordIndices = [
      chunks.elementAt(0).elementAt(1),
      chunks.elementAt(1).elementAt(1),
    ];

    final normalCoordIndices = [
      chunks.elementAt(0).elementAt(2),
      chunks.elementAt(1).elementAt(2),
      chunks.elementAt(2).elementAt(2),
    ];

    return Face(
      vertexIndices: vertexIndices,
      normalIndices: normalCoordIndices,
      texCoordIndices: texCoordIndices,
    );
  }
}

Vector parseVector(String line) {
  final chunks =
      line.split(' ').sublist(1).map((v) => double.parse(v)).toList();

  if (chunks.length == 2) return Vector2.array(chunks);
  if (chunks.length == 3) return Vector3.array(chunks);

  throw Exception('Unsupported vector size: ${chunks.length}');
}

class WavefrontObject {
  final String name;
  final List<Vector3> vCoords = [];
  final List<Vector2> tCoords = [];
  final List<Vector3> nCoords = [];
  final List<Face> faces = [];

  static List<WavefrontObject> parseObj(String obj) {
    final result = <WavefrontObject>[];

    for (var line in obj.split('\n')) {
      if (line.startsWith('o ')) {
        result.add(WavefrontObject(line.substring(2)));
        continue;
      }

      if (result.isEmpty || line.isEmpty || line.length < 2) {
        continue;
      }

      final obj = result.last;

      if (line[0] == 'v') {
        if (line[1] == ' ') {
          obj.vCoords.add(parseVector(line) as Vector3);
        } else if (line[1] == 't') {
          obj.tCoords.add(parseVector(line) as Vector2);
        } else if (line[1] == 'n') {
          obj.nCoords.add(parseVector(line) as Vector3);
        }

        continue;
      }

      if (line.startsWith('f ')) {
        obj.faces.add(Face.parse(line));
        continue;
      }
    }

    return result;
  }

  VBO? _vbo;
  VBO get vbo => _vbo ??= buildVBO();

  WavefrontObject(this.name);

  Iterable<double> toIterable(
    List<Vector> Function() coordsGetter,
    List<int> Function(Face face) indicesGetter,
    int size,
  ) sync* {
    for (var face in faces) {
      final indices = indicesGetter(face);
      for (var index in indices) {
        final v = coordsGetter()[index];
        for (var i = 0; i < size; i++) {
          yield v.storage[i];
        }
      }
    }
  }

  VBO buildVBO() {
    final vbo = VBO(
      Float32List.fromList(
        toIterable(() => vCoords, (f) => f.vertexIndices, 3).toList(),
      ),
      Float32List.fromList(
        toIterable(() => tCoords, (f) => f.texCoordIndices, 2).toList(),
      ),
      Float32List.fromList(
        toIterable(() => nCoords, (f) => f.normalIndices, 3).toList(),
      ),
    );

    return vbo;
  }
}
