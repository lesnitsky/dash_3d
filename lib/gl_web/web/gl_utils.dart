import 'dart:web_gl';

Shader createShader(RenderingContext gl, int shaderType, String shaderSource) {
  final shader = gl.createShader(shaderType);
  gl.shaderSource(shader, shaderSource);
  gl.compileShader(shader);

  final log = gl.getShaderInfoLog(shader);
  if (log!.isNotEmpty) {
    throw Exception(log);
  }

  return shader;
}

Program createProgram(RenderingContext gl, Shader vShader, Shader fShader) {
  final program = gl.createProgram();
  gl.attachShader(program, vShader);
  gl.attachShader(program, fShader);

  gl.linkProgram(program);

  final log = gl.getProgramInfoLog(program);
  if (log!.isNotEmpty) {
    throw Exception(log);
  }

  return program;
}
