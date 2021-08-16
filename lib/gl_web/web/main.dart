import 'dart:html';
import 'dart:math';

import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'gl_utils.dart';
import 'wavefront_object.dart';

const vShaderSource = '''
attribute vec3 pos;
attribute vec3 normal;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform mat4 normalMatrix;

varying float vIntense;

void main() {
    gl_Position = projection * view * model * vec4(pos, 1.0);
    vec3 light = normalize(vec3(0.0, 0.3, 1.0));

    vIntense = max(dot(light, (normalMatrix * vec4(normal, 1)).xyz), 0.1);
}
''';

const fShaderSource = '''
precision mediump float;

varying float vIntense;

void main() {
    gl_FragColor = vec4(vec3(0.117, 0.631, 0.945) * vIntense, 1);
}
''';

Future<String> loadModel(String name) async {
  final res = await window.fetch(name);
  final text = await res.text() as String;
  return text;
}

void render(CanvasElement canvas, String model) async {
  final gl = canvas.getContext('webgl') as RenderingContext;

  final width = canvas.width!;
  final height = canvas.height!;

  gl.enable(WebGL.DEPTH_TEST);

  // #161F2B
  gl.clearColor(0.06, 0.12, 0.16, 1);

  gl.viewport(0, 0, width, height);

  gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

  var projMatrix = makePerspectiveMatrix(
    pi / 2,
    width / height,
    0.1,
    100,
  );

  var viewMatrix = makeViewMatrix(
    Vector3(0, 0.5, 3),
    Vector3(0, 0, 0),
    Vector3(0, 1, 0),
  );

  var modelMatrix = Matrix4.identity();

  var normalMatrix = modelMatrix.clone()
    ..invert()
    ..transpose();

  UniformLocation? modelMatrixLocation;
  UniformLocation? normalMatrixLocation;
  List<WavefrontObject>? objects;

  final vShader = createShader(gl, WebGL.VERTEX_SHADER, vShaderSource);
  final fShader = createShader(gl, WebGL.FRAGMENT_SHADER, fShaderSource);
  final program = createProgram(gl, vShader, fShader);

  gl.useProgram(program);

  objects = WavefrontObject.parseObj(model);

  final posLoc = gl.getAttribLocation(program, 'pos');
  final normalLoc = gl.getAttribLocation(program, 'normal');

  final projLoc = gl.getUniformLocation(program, 'projection');
  final viewLoc = gl.getUniformLocation(program, 'view');
  modelMatrixLocation = gl.getUniformLocation(program, 'model');
  normalMatrixLocation = gl.getUniformLocation(program, 'normalMatrix');

  gl.enableVertexAttribArray(posLoc);
  gl.enableVertexAttribArray(normalLoc);

  final _buffers =
      objects.fold<Map<WavefrontObject, Map<String, Buffer>>>({}, (acc, e) {
    acc[e] = {
      'pos': gl.createBuffer(),
      'normal': gl.createBuffer(),
    };
    return acc;
  });

  gl.uniformMatrix4fv(projLoc, false, projMatrix.storage);
  gl.uniformMatrix4fv(viewLoc, false, viewMatrix.storage);
  gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
  gl.uniformMatrix4fv(normalMatrixLocation, false, normalMatrix.storage);

  objects.forEach((element) {
    final vbo = element.vbo;
    final posBuffer = _buffers[element]!['pos'];
    final normalBuffer = _buffers[element]!['normal'];

    gl.bindBuffer(WebGL.ARRAY_BUFFER, posBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      vbo.position,
      WebGL.STATIC_DRAW,
    );

    gl.vertexAttribPointer(posLoc, 3, WebGL.FLOAT, false, 0, 0);

    gl.bindBuffer(WebGL.ARRAY_BUFFER, normalBuffer);
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      vbo.normal,
      WebGL.STATIC_DRAW,
    );

    gl.vertexAttribPointer(normalLoc, 3, WebGL.FLOAT, false, 0, 0);

    gl.drawArrays(WebGL.TRIANGLES, 0, vbo.position.length ~/ 3);
  });

  void frame(_) {
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    modelMatrix.rotateY(1 * degrees2Radians);
    normalMatrix = modelMatrix.clone()
      ..invert()
      ..transpose();

    gl.uniformMatrix4fv(modelMatrixLocation, false, modelMatrix.storage);
    gl.uniformMatrix4fv(normalMatrixLocation, false, normalMatrix.storage);

    window.requestAnimationFrame(frame);

    objects!.forEach((element) {
      final vbo = element.vbo;

      gl.drawArrays(WebGL.TRIANGLES, 0, vbo.position.length ~/ 3);
    });
  }

  frame(0);
}

void main() async {
  final body = document.body!;
  final width = body.offsetWidth ~/ 1;
  final height = body.offsetHeight ~/ 1;

  final canvas = CanvasElement()
    ..width = width * window.devicePixelRatio ~/ 1
    ..height = height * window.devicePixelRatio ~/ 1;

  body.append(canvas);

  canvas.style.width = '${width}px';
  canvas.style.height = '${height}px';

  final model = await loadModel('monkey.obj');
  render(canvas, model);
}
