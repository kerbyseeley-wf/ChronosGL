library chronosutil;

import 'dart:html';

const int _numBars = 90;
const int _graphHeight = 30;
const int _maxFps = 90;

class Stats {
  Element _root;
  Element _text;
  Element _extra;
  Element _graph;

  Element MakeText(String initial) {
    Element text = new Element.div();
    text.style..fontWeight = "bold";
    text.text = initial;
    return text;
  }

  Element MakeGraph(String fg, String bg, int bars, int height) {
    Element graph = new Element.div();
    graph.style
      ..width = "${bars}px"
      ..height = "${height}px"
      ..color = fg
      ..background = fg;

    for (int i = 0; i < bars; i++) {
      Element e = new Element.span();
      e.style
        ..width = "1px"
        ..height = "${height}px"
        ..float = "left"
        ..opacity = "0.9"
        ..background = bg;
      graph.append(e);
    }
    return graph;
  }

  Stats(Element root, String fg, String bg) {
    if (root == null) throw "no element provided";
    _root = root;
    _root.style
      ..color = fg
      ..fontFamily = "Helvetica,Arial,sans-serif"
      ..fontSize = "9px"
      ..lineHeight = "15px"
      ..padding = "0 0 3px 3px"
      ..textAlign = "left"
      ..background = bg;

    _text = MakeText("@@@@");
    _root.append(_text);

    _graph = MakeGraph(fg, bg, _numBars, _graphHeight);
    _root.append(_graph);

    _extra = new Element.div();
    _root.append(_extra);
  }

  void AddRawValue(int v) {
    if (v < 0) v = 0;
    if (v > _graphHeight) v = _graphHeight;
    Element e = _graph.firstChild;
    e.style.height = "${v}px";
    _graph.append(e);
  }
}

const double SAMPLE_RATE_MS = 1000.0;

class StatsFps extends Stats {
  int _frames = 0;
  double _lastSample = 0.0;

  void UpdateFrameCount(double now, [String extra = ""]) {
    _frames++;
    if ((now - _lastSample) < SAMPLE_RATE_MS) return;
    double fps = _frames * 1000.0 / SAMPLE_RATE_MS;
    //print("${fps}");
    _frames = 0;
    _lastSample = now;
    _text.text = fps.toStringAsFixed(2) + " fps";
    _extra.innerHtml = extra;
    AddRawValue(_graphHeight * fps.ceil() ~/ _maxFps);
  }

  StatsFps(Element root, String fg, String bg) : super(root, fg, bg);
}
