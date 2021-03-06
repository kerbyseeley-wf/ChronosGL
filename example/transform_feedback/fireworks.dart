import 'package:chronosgl/chronosgl.dart';
import 'dart:math' as Math;
import 'dart:html' as HTML;
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart' as VM;

const double kMaxDistance = 100.1;
const double kMinDistance = 0.2;
const int kIons = 10000;

List<ShaderObject> createFireWorksShader() {
  return [
    new ShaderObject("FireWorksV")
      ..AddAttributeVars([aVertexPosition])
      ..AddUniformVars([uPerspectiveViewMatrix, uModelMatrix, uPointSize])
      ..AddTransformVars([tPosition])
      ..SetBody([
        """
      
const float kMaxDistance = ${kMaxDistance};
  
const float kMinDistance = ${kMinDistance};
  
const float dt = 0.1666;
const float speed = 2.0;  
  
const vec3 srcs[] = vec3[](vec3(6.0, 0.0, 6.0),
                           vec3(3.0, 0.0, 6.0),
                           vec3(0.0, 0.0, 6.0),
                           vec3(-3.0, 0.0, 6.0),
                           vec3(-6.0, 0.0, 6.0));
                           
const vec3 dsts[] = vec3[](vec3(6.0, 0.0, -6.0),
                           vec3(3.0, 0.0, -6.0),
                           vec3(0.0, 0.0, -6.0),
                           vec3(-3.0, 0.0, -6.0),
                           vec3(-6.0, 0.0, -6.0));   
float rand(vec2 seed){
    return fract(sin(dot(seed ,vec2(12.9898,78.233))) * 43758.5453);
}      

int irand(int n, vec2 seed) {
    return 1;
}

vec3 vec3rand(vec3 seed) {
    return vec3(rand(seed.yz), rand(seed.xz), rand(seed.xy));
}

vec3 Update(vec3 pos, vec3 seed) {
    vec3 force = vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < srcs.length(); ++i) {
       vec3 d = pos - srcs[i];
       float l = length(d);
       if (l <= kMinDistance) continue;
       if (l >= kMaxDistance) {
           return srcs[irand(srcs.length(), seed.xy)] +
                       vec3rand(seed) * 20.0 * dt;
       }
       force += d / (l * l); 
    } 
    
    for (int i = 0; i < dsts.length(); ++i) {
       vec3 d = dsts[i] - pos;
       float l = length(d);
       if (l <= kMinDistance) {
           return srcs[irand(srcs.length(), seed.xy)] +
                       vec3rand(seed) * 20.0 * dt;
       }
       force += d / (l * l); 
    } 
    return pos + normalize(force) * dt * speed;
}
      
void main() {        
    gl_Position = ${uPerspectiveViewMatrix} * ${uModelMatrix} * 
                  vec4(${aVertexPosition}, 1.0);

    gl_PointSize = ${uPointSize}/gl_Position.z;
    ${tPosition} = Update(${aVertexPosition}, gl_Position.xyz);
}
"""
      ]),
    new ShaderObject("FireWorksF")
      ..AddUniformVars([uTexture])
      ..SetBodyWithMain(
          ["${oFragColor} = texture( ${uTexture},  gl_PointCoord);"])
  ];
}

String DumpVec(VM.Vector3 v) {
  return "${v.x} ${v.y} ${v.z}";
}

// Source or Sink for Ions.
// Can move themselves - currently not used.
class Pole {
  VM.Vector3 _pos = new VM.Vector3.zero();
  VM.Vector3 _src = new VM.Vector3.zero();
  VM.Vector3 _dst = new VM.Vector3.zero();
  double _t = 0.0;

  Pole(VM.Vector3 dst) {
    setNewTarget(dst);
  }

  void setNewTarget(VM.Vector3 dst) {
    _dst.xyz = dst.xyz;
    _src.xyz = _pos.xyz;
    Update(0.0);
  }

  void Update(double t) {
    _t = t;
    VM.Vector3.mix(_src, _dst, t, _pos);
  }

  VM.Vector3 Pos() => _pos;

  @override
  String toString() =>
      "POLE: ${DumpVec(_pos)} time ${_t} [${DumpVec(_src)}] => [${DumpVec(_dst)}]";
}

// Particle emitted from a Source Pole and heading towards a Sink Pole.
class Ion {
  VM.Vector3 _pos;
  double _speed;

  Ion(this._speed, VM.Vector3 pos) {
    _pos = pos.clone();
  }

  VM.Vector3 Pos() => _pos;

  @override
  String toString() => "ION: ${DumpVec(_pos)} speed: ${_speed}";

  // Update position based on distance Source/Sink Poles
  void Update(List<Pole> srcs, List<Pole> dsts, Math.Random rng, double dt) {
    VM.Vector3 force = new VM.Vector3.zero();

    for (Pole pole in srcs) {
      VM.Vector3 t = _pos - pole.Pos(); // pushing force
      final double len = t.length;
      if (len <= kMinDistance) continue;
      // stop if we are out of bounds
      if (len > kMaxDistance) {
        Pole p = srcs[rng.nextInt(srcs.length)];
        _pos = p.Pos() + RandomVector(rng, 20.0 * dt);
        print("too far ${len}");
        return;
      }
      // the further the distance the weaker the force
      force += t / (len * len);
    }

    for (Pole pole in dsts) {
      VM.Vector3 t = pole.Pos() - _pos; // pulling force
      final double len = t.length;
      // stop if we would hit the pole in the next timestep
      if (len <= kMinDistance) {
        Pole p = srcs[rng.nextInt(srcs.length)];
        _pos = p.Pos() + RandomVector(rng, 20.0 * dt);
        print("too close: ${len}");
        return;
      }
      force += t / (len * len);
    }

    // the normalization sacrifices physics for aesthetics
    _pos += force.normalized() * dt * _speed;
  }
}

VM.Vector3 RandomVector(Math.Random rng, double d) {
  return new VM.Vector3((rng.nextDouble() - 0.5) * d,
      (rng.nextDouble() - 0.5) * d, (rng.nextDouble() - 0.5) * d);
}

List<Pole> MakeRowOfPoles(List<double> xx, double y, double z, double scale) {
  List<Pole> out = [];
  for (double x in xx) {
    out.add(new Pole(new VM.Vector3(x, y, z) * scale)..Update(1.0));
  }
  return out;
}

void main() {
  StatsFps fps =
      new StatsFps(HTML.document.getElementById("stats"), "blue", "gray");

  final Math.Random rng = new Math.Random(0);

  HTML.CanvasElement canvas = HTML.document.querySelector('#webgl-canvas');
  final int width = canvas.clientWidth;
  final int height = canvas.clientHeight;
  canvas.width = width;
  canvas.height = height;

  ChronosGL chronosGL = new ChronosGL(canvas);
  OrbitCamera orbit = new OrbitCamera(15.0, 0.5, 0.5, canvas);
  Perspective perspective = new Perspective(orbit, 0.1, 1000.0)
    ..AdjustAspect(width, height);
  RenderPhase phase = new RenderPhase("main", chronosGL)
    ..viewPortW = width
    ..viewPortH = height;
  List<Pole> srcPoles =
      MakeRowOfPoles([2.0, 1.0, 0.0, -1.0, -2.0], 0.0, 2.0, 3.0);
  List<Pole> dstPoles =
      MakeRowOfPoles([2.0, 1.0, 0.0, -1.0, -2.0], 0.0, -2.0, 3.0);

  VM.Vector3 outOfBounds = new VM.Vector3.all(kMaxDistance * 100.0);
  List<Ion> ions = [];
  for (int i = 0; i < kIons; i++) {
    Ion ion = new Ion(2.0, outOfBounds);
    ions.add(ion);
  }
  Float32List vertices = new Float32List(3 * kIons);
  Material mat = new Material.Transparent("stars", BlendEquationMix)
    ..SetUniform(uTexture, Utils.createParticleTexture(chronosGL))
    ..SetUniform(uPointSize, 200.0);
  GeometryBuilder gb = new GeometryBuilder(true);
  for (var i = 0; i < kIons; i++) {
    gb.AddVertex(new VM.Vector3.zero());
  }
  MeshData md = GeometryBuilderToMeshData("", chronosGL, gb);
  RenderProgram programSprites =
      phase.createProgram(createPointSpritesShader());
  programSprites.add(new Node("ions", md, mat));

  RenderProgram pssp = phase.createProgram(createFireWorksShader());
  MeshData md2 = GeometryBuilderToMeshData("", chronosGL, gb);
  MeshData md1 = GeometryBuilderToMeshData("", chronosGL, gb);

  Node node1 = new Node("ions1", md1, mat);
  var transform1 = chronosGL.createTransformFeedback();
  chronosGL.bindTransformFeedback(transform1);
  chronosGL.bindBufferBase(
      GL_TRANSFORM_FEEDBACK_BUFFER, 0, md2.GetBuffer(aVertexPosition));
  pssp.add(node1);

  chronosGL.bindTransformFeedback(transform1);
  programSprites.enabled = true;
  pssp.enabled = false;

  double _lastTimeMs = 0.0;
  void animate(timeMs) {
    timeMs = 0.0 + timeMs;
    double elapsed = timeMs - _lastTimeMs;
    _lastTimeMs = timeMs;
    orbit.azimuth += 0.001;

    if (programSprites.enabled && elapsed > 0.0) {
      int n = 0;
      for (Ion ion in ions) {
        ion.Update(srcPoles, dstPoles, rng, elapsed / 1000.0);
        vertices[n + 0] = ion.Pos().x;
        vertices[n + 1] = ion.Pos().y;
        vertices[n + 2] = ion.Pos().z;
        n += 3;
      }
      md.ChangeVertices(vertices);
    }
    orbit.animate(elapsed);

    phase.draw([perspective]);

    HTML.window.animationFrame.then(animate);
    fps.UpdateFrameCount(timeMs);
    if (pssp.enabled) {
      chronosGL.bindBuffer(GL_ARRAY_BUFFER, md1.GetBuffer(aVertexPosition));
      chronosGL.bindBuffer(
          GL_TRANSFORM_FEEDBACK_BUFFER, md2.GetBuffer(aVertexPosition));
      chronosGL.copyBufferSubData(
          GL_TRANSFORM_FEEDBACK_BUFFER, GL_ARRAY_BUFFER, 0, 0, kIons * 3);
    }
  }

  animate(0.0);
}
