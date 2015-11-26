part of chronosgl;

class Utils {
/*
  Texture createCheckerboardTexture() {
    var pixels = new Uint8List.fromList(
        [255, 255, 255, 0, 0, 0, 0, 0, 0, 255, 255, 255]);
    var texture = gl.createTexture();
    gl.bindTexture(TEXTURE_2D, texture);
    gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
    gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
    gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, NEAREST);
    gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, NEAREST);
    //  gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR);
    //  gl.texParameteri(TEXTURE_2D, TEXTURE_MAG_FILTER, LINEAR);
    gl.pixelStorei(UNPACK_ALIGNMENT, 1);
    gl.texImage2DTyped(TEXTURE_2D, 0, RGB, 2, 2, 0, RGB, UNSIGNED_BYTE, pixels);
    return texture;
  }
*/
  
  static HTML.CanvasElement createCanvas(
      HTML.CanvasElement canvas, callback(HTML.CanvasRenderingContext2D ctx),
      [int size = 512]) {
    if (canvas == null) canvas =
        new HTML.CanvasElement(width: size, height: size);
    HTML.CanvasRenderingContext2D context = canvas.getContext('2d');
    callback(context);
    return canvas;
  }

  static HTML.CanvasElement createGradientImage2(
      double time, HTML.CanvasElement canvas) {
    int d = 512;
    return createCanvas(canvas, (HTML.CanvasRenderingContext2D ctx) {
      double sint = Math.sin(time);
      double n = (sint + 1) / 2;
      ctx.rect(0, 0, d, d);
      HTML.CanvasGradient grad = ctx.createLinearGradient(0, 0, d * n, d);
      double cs1 = (360 * n).floorToDouble();
      double cs2 = (90 * n).floorToDouble();
      grad.addColorStop(0, 'hsla($cs1, 100%, 40%, 1)');
      grad.addColorStop(0.2, 'black');
      grad.addColorStop(0.3, 'black');
      grad.addColorStop(0.5, 'hsla($cs2, 100%, 40%, 1)');
      grad.addColorStop(0.7, 'black');
      grad.addColorStop(0.9, 'black');
      grad.addColorStop(1, 'hsla($cs1, 100%, 40%, 1)');
      ctx.fillStyle = grad;
      ctx.fill();
    });
  }

  static TextureWrapper createParticleTexture([String name= "Utils::Particles"]) {
    return new TextureWrapper.Canvas(name, createParticleCanvas());
  }

  static HTML.CanvasElement createParticleCanvas() {
    int d = 64;
    return createCanvas(null, (HTML.CanvasRenderingContext2D ctx) {
      int x = d ~/ 2, y = d ~/ 2;

      var gradient = ctx.createRadialGradient(x, y, 1, x, y, 22);
      gradient.addColorStop(0, 'gray');
      gradient.addColorStop(1, 'black');

      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, d, d);

      gradient = ctx.createRadialGradient(x, y, 1, x, y, 6);
      gradient.addColorStop(0, 'white');
      gradient.addColorStop(1, 'gray');

      ctx.globalAlpha = 0.9;
      ctx.fillStyle = gradient;
      ctx.arc(x, y, 4, 0, 2 * Math.PI);
      ctx.fill();
    }, d);
  }

  // TODO: think about deprecating this
  static Mesh createQuad(Material mat, int size) {
    List<double> verts = [
      -1.0 * size,
      -1.0 * size,
      0.0,
      1.0 * size,
      -1.0 * size,
      0.0,
      1.0 * size,
      1.0 * size,
      0.0,
      -1.0 * size,
      1.0 * size,
      0.0
    ];

    List<double> textureCoords = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0];

    List<int> vertexIndices = [0, 1, 2, 0, 2, 3];
    return new Mesh(new MeshData(
        vertices: verts,
        textureCoords: textureCoords,
        vertexIndices: vertexIndices), mat);
  }

  static Mesh MakeSkycube(TextureWrapper cubeTexture) {
    Material mat  = new Material()..SetUniform(uTextureCubeSampler, cubeTexture);
    return createCubeInternal().multiplyVertices(512).createMesh(mat);
   
  }

  /*
  void addSkybox(String prefix, String suffix, String nx, String px, String nz,
      String pz, String ny, String py) {
    Material mm(String middle) {
      return new Material()..SetUniform(uTextureSampler, textureCache.getTW(prefix + middle + suffix).texture);
    }
    
    Mesh skybox_nx = createQuad(mm(nx), 1004);
    skybox_nx.setPos(-2.0, 2.0, -1000.0);
    chronosGL.programBasic.addFollowCameraObject(skybox_nx);

    Mesh skybox_px = createQuad(mm(px), 1004);
    skybox_px.setPos(-2.0, 2.0, 1000.0);
    skybox_px.rotY(Math.PI);
    chronosGL.programBasic.addFollowCameraObject(skybox_px);

    Mesh skybox_nz = createQuad(mm(nz), 1004);
    skybox_nz.setPos(-1000.0, 2.0, -2.0);
    skybox_nz.rotY(0.5 * Math.PI);
    chronosGL.programBasic.addFollowCameraObject(skybox_nz);

    Mesh skybox_pz = createQuad(mm(pz), 1004);
    skybox_pz.setPos(1000.0, 2.0, -2.0);
    skybox_pz.rotY(1.5 * Math.PI);
    chronosGL.programBasic.addFollowCameraObject(skybox_pz);

    Mesh skybox_ny = createQuad(mm(ny), 1004);
    skybox_ny.setPos(-2.0, -1000.0, -2.0);
    skybox_ny.rotX(1.5 * Math.PI);
    skybox_ny.rotZ(1.5 * Math.PI);
    chronosGL.programBasic.addFollowCameraObject(skybox_ny);

    Mesh skybox_py = createQuad(mm(py), 1004);
    skybox_py.setPos(-2.0, 1000.0, -2.0);
    skybox_py.rotX(0.5 * Math.PI);
    skybox_py.rotZ(0.5 * Math.PI);
    chronosGL.programBasic.addFollowCameraObject(skybox_py);
  }*/

  /*
  @deprecated // use chronosGL.shapes.create...
  MeshData createIcosahedron([int subdivisions = 4]) {
    return new Icosahedron(subdivisions);
  }

  @deprecated // use chronosGL.shapes.create...
  MeshData createCube(
      {double x: 1.0,
      double y: 1.0,
      double z: 1.0,
      double uMin: 0.0,
      double uMax: 1.0,
      double vMin: 0.0,
      double vMax: 1.0}) {
    return createCubeInternal(
        x: x, y: y, z: z, uMin: uMin, uMax: uMax, vMin: vMin, vMax: vMax);
  }

  @deprecated // use chronosGL.shapes.create...
  Mesh createTorusKnotMesh(
      {double radius: 20.0,
      double tube: 4.0,
      int segmentsR: 128,
      int segmentsT: 16,
      int p: 2,
      int q: 3,
      double heightScale: 1.0,
      Texture texture}) {
    Material mat = new Material()..SetUniform(uTextureSampler, texture);
    return new Mesh(createTorusKnotInternal(
        radius: radius,
        tube: tube,
        segmentsR: segmentsR,
        segmentsT: segmentsT,
        p: p,
        q: q,
        heightScale: heightScale), mat);
  } 
   */

  
  static Mesh MakeParticles(int numPoints, [int dimension = 100]) {
    return MakePointSprites(numPoints, createParticleTexture(), dimension);
  }
  

  static int id = 1;
  
  static Mesh MakePointSprites(int numPoints, TextureWrapper texture, [int dimension = 500]) {
    // TODO: make this asynchronous (async/await?)
    Math.Random rand = new Math.Random();
    Float32List vertices = new Float32List(numPoints * 3);
    for (var i = 0; i < vertices.length; i++) {
      vertices[i] = (rand.nextDouble() - 0.5) * dimension;
    }
    MeshData md = new MeshData(vertices: vertices);

    Material mat = new Material()
      ..SetUniform(uTextureSampler, texture)
      ..SetUniform(uPointSize, 1000)
      ..blend = true
      ..depthWrite = false
      ..blend_dFactor = WEBGL.ONE_MINUS_SRC_COLOR;
    id++;
    return new Mesh(md, mat, drawPoints: true)
      ..name = 'point_sprites_mesh_' + id.toString();
  }

  static Future<Object> loadFile(String url, [bool binary = false]) {
    Completer c = new Completer();
    HTML.HttpRequest hr = new HTML.HttpRequest();
    hr.open("GET", url);
    if (binary) hr.responseType = "arraybuffer";
    hr.onLoadEnd.listen((e) {
      c.complete(hr.response);
    });
    hr.send();
    return c.future;
  }

  static Future<Object> loadBinaryFile(String url) {
    return loadFile(url, true);
  }

  static Future<Object> loadJsonFile(String url) {
    Completer c = new Completer();
    HTML.HttpRequest hr = new HTML.HttpRequest();
    hr.open("GET", url);
    hr.onLoadEnd.listen((e) {
      c.complete(JSON.decode(hr.responseText));
    });
    hr.send();
    return c.future;
  }

  static String getQueryVariable(String name) {
    String query = HTML.window.location.search.substring(1);
    List<String> vars = query.split("&");
    for (int i = 0; i < vars.length; i++) {
      List<String> pair = vars[i].split("=");
      if (pair[0] == name) {
        return Uri.decodeComponent(pair[1]);
      }
    }
    return null;
  }
}
