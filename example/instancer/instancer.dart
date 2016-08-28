import 'package:chronosgl/chronosgl.dart';
import 'package:chronosgl/chronosutil.dart';
import 'dart:html' as HTML;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart' as VM;

List<ShaderObject> createInstancedShader() {
  return [
    new ShaderObject("InstancedV")
      ..AddAttributeVar(aVertexPosition)
      ..AddAttributeVar(iaRotatation)
      ..AddAttributeVar(iaTranslation)
      ..AddVaryingVar(vColors)
      ..AddUniformVar(uPerspectiveViewMatrix)
      ..AddUniformVar(uModelMatrix)
      ..SetBody([
        """
        vec3 rotate_vertex_position(vec3 pos, vec4 rot) { 
          return pos + 2.0 * cross(rot.xyz, cross(rot.xyz, pos) + rot.w * pos);
        }

        void main(void) {
          vec3 P = rotate_vertex_position(${aVertexPosition}, ${iaRotatation}) + 
                    ${iaTranslation};
          gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * vec4(P, 1);
          ${vColors} = vec3( sin(${aVertexPosition}.x)/2.0+0.5, 
                       cos(${aVertexPosition}.y)/2.0+0.5, 
                       sin(${aVertexPosition}.z)/2.0+0.5);
        }
        """
      ]),
    new ShaderObject("InstancedF")
      ..AddVaryingVar(vColors)
      ..SetBodyWithMain([" gl_FragColor = vec4( ${vColors}, 1. );"])
  ];
}

void main() {
  StatsFps fps =
      new StatsFps(HTML.document.getElementById("stats"), "blue", "gray");
  HTML.CanvasElement canvas = HTML.document.querySelector('#webgl-canvas');
  ChronosGL chronosGL = new ChronosGL(canvas);
  OrbitCamera orbit = new OrbitCamera(265.0);
  Perspective perspective = new Perspective(orbit);
  RenderingPhase phase = new RenderingPhase("main", chronosGL.gl, perspective);

  Material mat = new Material("mat");
  Mesh m = new Mesh("torus", Shapes.TorusKnot(radius: 12.0), mat);

  int count = 1000;
  Float32List translations = new Float32List(count * 3);
  Float32List rotations = new Float32List(count * 4);

  Spatial spatial = new Spatial("dummy");
  int pos = 0;
  for (int x = -5; x < 5; x++) {
    for (int y = -5; y < 5; y++) {
      for (int z = -5; z < 5; z++) {
        spatial.setPos(x * 40.0, y * 40.0, z * 30.0);
        translations.setAll(pos * 3, spatial.getPos().storage);
        VM.Quaternion q =
            new VM.Quaternion.fromRotation(spatial.transform.getRotation());
        rotations.setAll(pos * 3, q.storage);
        pos++;
      }
    }
  }

  m.AddBuffer(iaRotatation, rotations);
  m.AddBuffer(iaTranslation, translations);
  m.numInstances = 1000;

  ShaderProgram prg = phase.createProgram(createInstancedShader());
  prg.add(m);

  ShaderProgram programSprites =
      phase.createProgram(createPointSpritesShader());
  programSprites.add(Utils.MakeParticles(2000));

  double _lastTimeMs = 0.0;
  void animate(double timeMs) {
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs;
    orbit.azimuth += 0.001;
    orbit.animate(elapsed);
    fps.UpdateFrameCount(timeMs);
    perspective.Adjust(canvas);
    phase.draw([]);
    HTML.window.animationFrame.then(animate);
  }

  Texture.loadAndInstallAllTextures(chronosGL.gl).then((dummy) {
    animate(0.0);
  });
}