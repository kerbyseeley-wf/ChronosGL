part of core;

class TextureProperties {
  bool mipmap = false;
  bool clamp = false;
  bool shadow = false;
  bool flipY = true;
  int anisotropicFilterLevel = kNoAnisotropicFilterLevel;
  int minFilter = GL_LINEAR;
  int magFilter = GL_LINEAR;

  TextureProperties();

  TextureProperties.forFramebuffer() {
    flipY = false;
    clamp = true;
    mipmap = false;
    SetFilterNearest();
  }

  // http://stackoverflow.com/questions/22419682/glsl-sampler2dshadow-and-shadow2d-clarification\
  TextureProperties.forShadowMap() {
    flipY = false;
    clamp = false;
    mipmap = false;
    shadow = true;
  }

  void SetFilterNearest() {
    minFilter = GL_NEAREST;
    magFilter = GL_NEAREST;
  }

  // Very good but also a bit slow
  void SetMipmapLinear() {
    minFilter = GL_LINEAR_MIPMAP_LINEAR;
    magFilter = GL_LINEAR; // is this the best?
  }

  // This assumes a texture is already bound
  void InstallEarly(ChronosGL cgl, int type) {
    //LogInfo("Setup texture ${flipY}  ${anisotropicFilterLevel}");
    if (flipY) {
      cgl.pixelStorei(GL_UNPACK_FLIP_Y_WEBGL, 1);
    }
  }

  // This assumes a texture is already bound
  void InstallLate(ChronosGL cgl, int type) {
    if (anisotropicFilterLevel != kNoAnisotropicFilterLevel) {
      cgl.texParameterf(
          type, GL_TEXTURE_MAX_ANISOTROPY_EXT, anisotropicFilterLevel + 0.0);
    }
    cgl.texParameteri(type, GL_TEXTURE_MAG_FILTER, magFilter);
    cgl.texParameteri(type, GL_TEXTURE_MIN_FILTER, minFilter);

    if (clamp) {
      // this fixes glitches on skybox seams
      cgl.texParameteri(type, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
      cgl.texParameteri(type, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    if (mipmap) {
      cgl.generateMipmap(type);
    }

    if (shadow) {
      cgl.texParameteri(
          type, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE);
    }
  }
}

bool IsCubeChildTextureType(int t) {
  switch (t) {
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_X:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_X:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Y:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Y:
    case GL_TEXTURE_CUBE_MAP_NEGATIVE_Z:
    case GL_TEXTURE_CUBE_MAP_POSITIVE_Z:
      return true;
    default:
      return false;
  }
}

/// ## Class TextureProperties
/// is the base class for all textures
class Texture {
  final String _url;
  dynamic /* GL Texture */ _texture;
  final int _textureType;
  final ChronosGL _cgl;
  final TextureProperties properties;

  Texture(this._cgl, this._textureType, this._url, this.properties);

  void Bind([bool initTime = false]) {
    if (initTime) {
      _texture = _cgl.createTexture();
      properties.InstallEarly(_cgl, _textureType);
    }

    _cgl.bindTexture(_textureType, _texture);
  }

  void UnBind([bool initTime = false]) {
    if (initTime) {
      properties.InstallLate(_cgl, _textureType);
      int err = _cgl.getError();
      assert(err == GL_NO_ERROR);
    }
    _cgl.bindTexture(_textureType, null);
  }

  void SetImageData(var data) {
    _cgl.texImage2Dweb(
        _textureType, 0, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, data);
  }

  int GetTextureType() => _textureType;

  dynamic /* gl Texture */ GetTexture() {
    return _texture;
  }

  @override
  String toString() {
    return "Texture[${_url}, ${_textureType}]";
  }
}

// Used for depth and shadows
// Common format combos are:
// GL_DEPTH_COMPONENT16, GL_UNSIGNED_SHORT
// GL_DEPTH_COMPONENT24, GL_UNSIGNED_INT
class DepthTexture extends Texture {
  int _width;
  int _height;
  final int _internalFormatType;
  // e.g.  GL_UNSIGNED_SHORT, GL_UNSIGNED_BYTE. GL_FLOAT
  final int _dataType;

  DepthTexture(ChronosGL cgl, String url, this._width, this._height,
      this._internalFormatType, this._dataType, bool forShadow)
      : super(
            cgl,
            GL_TEXTURE_2D,
            url,
            forShadow
                ? new TextureProperties.forShadowMap()
                : new TextureProperties.forFramebuffer()) {
    _texture = _cgl.createTexture();
    _cgl.bindTexture(_textureType, _texture);
    _cgl.texImage2D(GL_TEXTURE_2D, 0, _internalFormatType, _width, _height, 0,
        GL_DEPTH_COMPONENT, _dataType, null);
    properties.InstallLate(_cgl, _textureType);
    int err = _cgl.getError();
    assert(err == GL_NO_ERROR, "problems intalling depth texture");
  }
}

class DepthStencilTexture extends Texture {
  int _width;
  int _height;

  DepthStencilTexture(ChronosGL cgl, String url, this._width, this._height)
      : super(cgl, GL_TEXTURE_2D, url, new TextureProperties.forFramebuffer()) {
    _texture = _cgl.createTexture();
    _cgl.bindTexture(_textureType, _texture);
    _cgl.texImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, _width, _height, 0,
        GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, null);
    //properties.InstallLate(_cgl, _textureType);
    int err = _cgl.getError();
    assert(err == GL_NO_ERROR, "problems intalling depth-stencil texture");
  }

  @override
  void SetImageData(var data) {
    _cgl.bindTexture(_textureType, _texture);
    _cgl.texImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, _width, _height, 0,
        GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, data);
  }
}

// https://www.khronos.org/registry/OpenGL-Refpages/es3.0/html/glTexImage2D.xhtml
class TypedTexture extends Texture {
  int _width;
  int _height;
  final int _internalFormatType;
  // e.g. GL_DEPTH_COMPONENT, GL_RGB, GL_RGBA
  final int _formatType;
  // e.g.  GL_UNSIGNED_SHORT, GL_UNSIGNED_BYTE, GL_FLOAT
  final int _dataType;
  // null, Float32List, etc
  // null is required by the shadow example
  // There used to be a bug - this seems fixed now, cf.:
  // sdk: https://github.com/dart-lang/sdk/issues/23517
  var _data;

  TypedTexture(ChronosGL cgl, String url, this._width, this._height,
      this._internalFormatType, this._formatType, this._dataType,
      [this._data = null])
      : super(cgl, GL_TEXTURE_2D, url, new TextureProperties.forFramebuffer()) {
    _Install();
  }

  void UpdateContent(var data) {
    _data = data;
    _cgl.bindTexture(_textureType, _texture);
    _cgl.texImage2D(GL_TEXTURE_2D, 0, _internalFormatType, _width, _height, 0,
        _formatType, _dataType, _data);
    _cgl.bindTexture(_textureType, null);
  }

   void SetImageDataPartial( var data, int x, int y, int w, int h) {
     _cgl.bindTexture(_textureType, _texture);
     _cgl.texSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, _formatType, _dataType, data);
     _cgl.bindTexture(_textureType, null);
  }

  void _Install() {
    Bind(true);
    _cgl.texImage2D(GL_TEXTURE_2D, 0, _internalFormatType, _width, _height, 0,
        _formatType, _dataType, _data);
    UnBind(true);
  }

  dynamic GetData() {
    return _data;
  }

  @override
  String toString() {
    return "TypedTexture[${_url}, ${_dataType}, ${_formatType}]";
  }
}

// This sort of depends on dart:html but we use a dynamic type to disguise
// it.
// TODO: We want to call  Install() in the constructor but this does not
// seem to work for video elements.
class ImageTexture extends Texture {
  dynamic _element; // CanvasElement, ImageElement, VideoElement

  ImageTexture(ChronosGL cgl, String url, this._element,
      [delayInstall = false,
      TextureProperties tp = null,
      textureType = GL_TEXTURE_2D])
      : super(
            cgl, textureType, url, tp == null ? new TextureProperties() : tp) {
    if (!delayInstall) {
      Install();
    }
  }

  void Install() {
    Bind(true);
    SetImageData(_element);
    UnBind(true);
  }

  void Update() {
    Bind();
    SetImageData(_element);
    UnBind();
  }
}

final List<int> _kCubeModifier = [
  GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
  GL_TEXTURE_CUBE_MAP_POSITIVE_X,
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
  GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
  GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
  GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
];

class CubeTexture extends Texture {
  CubeTexture(ChronosGL cgl, String url, List images)
      : super(cgl, GL_TEXTURE_CUBE_MAP, url, new TextureProperties()) {
    assert(images.length == _kCubeModifier.length);
    Bind(true);
    for (int i = 0; i < _kCubeModifier.length; ++i) {
      _cgl.texImage2Dweb(
          _kCubeModifier[i], 0, GL_RGBA, GL_RGBA, GL_UNSIGNED_BYTE, images[i]);
    }
    UnBind(true);

    properties.clamp = true;
  }
}
