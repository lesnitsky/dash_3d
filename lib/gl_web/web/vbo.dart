import 'dart:typed_data';

class VBO {
  final Float32List position;
  final Float32List texCoord;
  final Float32List normal;

  VBO(this.position, this.texCoord, this.normal);
}
