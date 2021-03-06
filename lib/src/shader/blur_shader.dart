part of chronosshader;

// https://en.wikipedia.org/wiki/Gaussian_blur

double _gaussianPdf(double x, double sigma) {
  // 0.39894... =  1 / sqrt(2 * pi)
  return 0.39894 * Math.exp(-0.5 * x * x / (sigma * sigma)) / sigma;
}

String makeGaussianPdfKernelString(int radius, double sigma) {
  List<double> w = [];
  double total = 0.0;
  for (int i = 0; i < radius; ++i) {
    double x = _gaussianPdf(i * 1.0, sigma);
    w.add(x);
    total += x;
    if (i > 0) total += x;
  }

  String lst = "";
  String sep = "";
  for (int i = 0; i < radius; ++i) {
    lst += sep;
    sep = ", ";
    lst += "${w[i] / total}";
  }

  return "float kernel[$radius] = float[$radius]($lst);";
}

String _kernelFragment = """
void main() {
    vec2 invSize = 1.0 / vec2(textureSize(${uTexture}, 0));
    vec3 sum = texture(${uTexture}, ${vTextureCoordinates}).rgb * kernel[0];
    for (int i = 1; i < kernel.length(); i++) {
        vec2 offset = ${uDirection} * invSize * float(i);
        sum += texture(${uTexture}, ${vTextureCoordinates} + offset).rgb * kernel[i];
        sum += texture(${uTexture}, ${vTextureCoordinates} - offset).rgb * kernel[i];
    }
    ${oFragColor} = vec4(sum, 1.0);
}
""";

List<ShaderObject> createBloomTextureShader(int radius, double sigma) {
  String constants = makeGaussianPdfKernelString(radius, sigma);
  return [
    new ShaderObject("uv-passthru")
      ..AddAttributeVars([aVertexPosition, aTextureCoordinates])
      ..AddVaryingVars([vTextureCoordinates])
      ..SetBodyWithMain(
          [NullVertexBody, "${vTextureCoordinates} = ${aTextureCoordinates};"]),
    new ShaderObject("BloomPassF")
      ..AddVaryingVars([vTextureCoordinates])
      ..AddUniformVars([uDirection, uTexture])
      ..SetBody([constants, _kernelFragment])
  ];
}

String _applyBloomEffectFragment = """
void main() {
	${oFragColor} = texture(${uTexture}, ${vTextureCoordinates}) +
	                ${uScale} *
	                vec4(${uColor}, 1.0) *
	                texture(${uTexture2}, ${vTextureCoordinates});
}
""";

List<ShaderObject> createApplyBloomEffectShader() {
  return [
    new ShaderObject("uv-passthru")
      ..AddAttributeVars([aVertexPosition, aTextureCoordinates])
      ..AddVaryingVars([vTextureCoordinates])
      ..SetBodyWithMain(
          [NullVertexBody, "${vTextureCoordinates} = ${aTextureCoordinates};"]),
    new ShaderObject("BloomPassF")
      ..AddVaryingVars([vTextureCoordinates])
      ..AddUniformVars([uTexture, uTexture2, uScale, uColor])
      ..SetBody([_applyBloomEffectFragment])
  ];
}
