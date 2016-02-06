part of chronosgl;

List<Vector> _CubeNormals = [
  // Front face
  new Vector(0.0, 0.0, 1.0),
  // Back face
  new Vector(0.0, 0.0, -1.0),
  // Top face
  new Vector(0.0, 1.0, 0.0),
  // Bottom face
  new Vector(0.0, -1.0, 0.0),
// Right face
  new Vector(1.0, 0.0, 0.0),
  // Left face
  new Vector(-1.0, 0.0, 0.0)
];

MeshData createCubeInternal(
    {double x: 1.0,
    double y: 1.0,
    double z: 1.0,
    double uMin: 0.0,
    double uMax: 1.0,
    double vMin: 0.0,
    double vMax: 1.0}) {
  
  List<Vector> vertices = [
    // Front face
    new Vector(-x, -y, z),
    new Vector(x, -y, z),
    new Vector(x, y, z),
    new Vector(-x, y, z),

    // Back face
    new Vector(-x, -y, -z),
    new Vector(-x, y, -z),
    new Vector(x, y, -z),
    new Vector(x, -y, -z),

    // Top face
    new Vector(-x, y, -z),
    new Vector(-x, y, z),
    new Vector(x, y, z),
    new Vector(x, y, -z),

    // Bottom face
    new Vector(x, -y, -z),
    new Vector(-x, -y, -z),
    new Vector(-x, -y, z),
    new Vector(x, -y, z),

    // Right face
    new Vector(x, -y, -z),
    new Vector(x, y, -z),
    new Vector(x, y, z),
    new Vector(x, -y, z),

    // Left face
    new Vector(-x, -y, -z),
    new Vector(-x, -y, z),
    new Vector(-x, y, z),
    new Vector(-x, y, -z)
  ];

  List<Vector2> uvs = [
    // Front face
    new Vector2(uMin, vMin),
    new Vector2(uMax, vMin),
    new Vector2(uMax, vMax),
    new Vector2(uMin, vMax),

    // Back face
    new Vector2(uMax, vMin),
    new Vector2(uMax, vMax),
    new Vector2(uMin, vMax),
    new Vector2(uMin, vMin),

    // Top face
    new Vector2(uMin, vMax),
    new Vector2(uMin, vMin),
    new Vector2(uMax, vMin),
    new Vector2(uMax, vMax),

    // Bottom face
    new Vector2(uMax, vMax),
    new Vector2(uMin, vMax),
    new Vector2(uMin, vMin),
    new Vector2(uMax, vMin),

    // Right face
    new Vector2(uMax, vMin),
    new Vector2(uMax, vMax),
    new Vector2(uMin, vMax),
    new Vector2(uMin, vMin),

    // Left face
    new Vector2(uMin, vMin),
    new Vector2(uMax, vMin),
    new Vector2(uMax, vMax),
    new Vector2(uMin, vMax)
  ];

  /*
  List<int> vertIndices = [
    0,
    1,
    2,
    0,
    2,
    3,
    // Front face
    4,
    5,
    6,
    4,
    6,
    7,
    // Back face
    8,
    9,
    10,
    8,
    10,
    11,
    // Top face
    12,
    13,
    14,
    12,
    14,
    15,
    // Bottom face
    16,
    17,
    18,
    16,
    18,
    19,
    // Right face
    20,
    21,
    22,
    20,
    22,
    23
    // Left face
  ];
   */

  MeshData md = new MeshData();
  md.name = "cube";
  md.EnableAttribute(aNormal);
  md.EnableAttribute(aTextureCoordinates);

  md.AddFaces4(6);
  md.AddVertices(vertices);
  md.AddAttributesVector2(aTextureCoordinates, uvs);
  for (int i = 0; i < _CubeNormals.length; i++) {
    Vector n = _CubeNormals[i];
    md.AddAttributesVector(aNormal, [n, n, n, n]);
  }

  return md;
}
