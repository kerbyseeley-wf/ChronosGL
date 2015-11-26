import 'dart:html' as html;
import 'dart:math' as Math;
import 'dart:web_gl';
import 'package:chronosgl/chronosgl.dart';

html.CanvasElement canvas2d;
Vector p1 = new Vector();

void main() {
  ChronosGL chronosGL = new ChronosGL('#webgl-canvas');

  Camera camera = chronosGL.getCamera();

  TorusKnotCamera tkc = new TorusKnotCamera(camera);
  chronosGL.addAnimatable('tkc', tkc);

  ShaderProgram programBasic = chronosGL.createProgram(createTexturedShader());

  canvas2d = Utils.createGradientImage2(0.0, canvas2d);
  TextureWrapper generatedTexture = new TextureWrapper.Canvas("gen", canvas2d);

  Material mat = new Material()
    ..SetUniform(uTextureSampler, generatedTexture)
    ..SetUniform(uColor, new Vector())
    ..blend = true
    ..depthTest = false;
  Mesh m = chronosGL.shapes.createTorusKnot().createMesh(mat);

  programBasic.add(m);
  chronosGL.addAnimateCallback('changeTexture', (double elapsed, double time) {
    canvas2d = Utils.createGradientImage2(time / 1000, canvas2d);
    chronosGL.gl.bindTexture(TEXTURE_2D, generatedTexture.GetTexture());
    chronosGL.gl
        .texImage2DCanvas(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, canvas2d);
  });

  int p = 2;
  int q = 3;
  double radius = 20.0;
  for (int i = 0; i < 128; ++i) {
    double u = i / 128 * 2 * p * Math.PI;
    getTorusKnotPos(u, q, p, radius, 1.0, p1);
    //chronosGL.programs['point_sprites'].add(new PointSprites.fromVertex(p1, textureCache.get("textures/particle.bmp")));
  }

  ShaderProgram programSprites =
      chronosGL.createProgram(createPointSpritesShader());
  programSprites.add(Utils.MakeParticles(2000));

  TextureWrapper.loadAndInstallAllTextures(chronosGL.gl).then((dummy) {
    chronosGL.run();
  });
}
