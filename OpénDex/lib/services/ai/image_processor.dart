import 'dart:typed_data';

import 'package:image/image.dart';

/// Post-processes a raw PNG image (e.g., from Gemini) by:
/// 1. Discovering background colour from four edges
/// 2. Removing border-connected near-white regions via chrominance-aware flood-fill
/// 3. Morphological close (dilate + erode) for edge smoothing
/// 4. Resizing to 256x64 with nearest-neighbour interpolation
Future<Uint8List> processSpriteSheet(Uint8List imageBytes) async {
  final Image? decoded = decodeImage(imageBytes);
  if (decoded == null) {
    throw ArgumentError('Unable to decode image from provided bytes');
  }

  // Clone into own RGBA buffer so we can mutate freely
  final Image workingImage = decoded.numChannels != 4
      ? _cloneToRgba(decoded)
      : copyCrop(decoded, x: 0, y: 0, width: decoded.width, height: decoded.height);

  final int w = workingImage.width;
  final int h = workingImage.height;
  final ByteData px = workingImage.data!.getBytes().buffer.asByteData();

  // Step 1: discover dominant border colour
  final EdgeCol bg = _findDominantEdgeColour(workingImage, w, h);

  // Step 2: BFS connectivity from edges
  final List<List<bool>> conn = List.generate(h, (_) => List.filled(w, false));
  final List<List<bool>> seen = List.generate(h, (_) => List.filled(w, false));
  final List<int> queue = <int>[];
  const int colTol = 24;

  void enqueue(int cx, int cy) {
    if (cx >= 0 && cx < w && cy >= 0 && cy < h && !seen[cy][cx]) {
      seen[cy][cx] = true;
      conn[cy][cx] = true;
      queue.add(cx | (cy << 16));
    }
  }

  // Seed top row
  for (int x = 0; x < w; x++) {
    final o = x * 4;
    if (_near(px, o, bg.r, bg.g, bg.b, colTol)) enqueue(x, 0);
  }
  // Seed bottom row
  for (int x = 0; x < w; x++) {
    final o = (h - 1) * w * 4 + x * 4;
    if (_near(px, o, bg.r, bg.g, bg.b, colTol)) enqueue(x, h - 1);
  }
  // Seed left column
  for (int y = 0; y < h; y++) {
    final o = y * w * 4;
    if (_near(px, o, bg.r, bg.g, bg.b, colTol)) enqueue(0, y);
  }
  // Seed right column
  for (int y = 0; y < h; y++) {
    final o = y * w * 4 + (w - 1) * 4;
    if (_near(px, o, bg.r, bg.g, bg.b, colTol)) enqueue(w - 1, y);
  }

  // BFS along 8-connected similar neighbours
  while (queue.isNotEmpty) {
    final v = queue.removeAt(0);
    final cx = v & 0xFFFF;
    final cy = v >> 16;
    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        if (dx == 0 && dy == 0) continue;
        final nx = cx + dx;
        final ny = cy + dy;
        if (nx < 0 || nx >= w || ny < 0 || ny >= h || seen[ny][nx]) continue;
        final no = ny * w * 4 + nx * 4;
        if (_near(px, no, bg.r, bg.g, bg.b, colTol) && _lumaDiffOk(no, bg, px)) {
          enqueue(nx, ny);
        }
      }
    }
  }

  // Step 3: build alpha mask
  const int satGuard = 6; // delta > this means "colourful enough"
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final o = y * w * 4 + x * 4;
      if (px.getUint8(o + 3) == 0) continue; // already transparent
      if (!conn[y][x]) continue;              // foreground, keep original alpha
      final r = px.getUint8(o), g = px.getUint8(o + 1), b = px.getUint8(o + 2);
      final mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final delta = mx - mn;
      // Near-white but saturated → character highlight, keep opaque
      if (delta > satGuard && mx > 200) continue;
      // Achromatic + very bright + connected to border → transparent
      if (mx > 220) {
        px.setUint8(o + 3, 0);
      }
    }
  }

  // Step 4: morphological close on alpha mask
  final Uint8List amask = Uint8List(w * h);
  for (int i = 0; i < w * h; i++) {
    amask[i] = px.getUint8(i * 4 + 3);
  }

  // Dilate – any cell whose 3x3 neighbourhood has alpha > 128 becomes opaque
  final Uint8List dilated = Uint8List(w * h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool hasStrong = false;
      for (int dy = -1; dy <= 1 && !hasStrong; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        for (int dx = -1; dx <= 1 && !hasStrong; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) continue;
          if (amask[ny * w + nx] > 128) hasStrong = true;
        }
      }
      dilated[y * w + x] = hasStrong ? 255 : 0;
    }
  }

  // Erode – cell stays opaque only if ALL 3x3 neighbours are opaque
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      bool allStrong = true;
      for (int dy = -1; dy <= 1 && allStrong; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) { allStrong = false; break; }
        for (int dx = -1; dx <= 1 && allStrong; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) { allStrong = false; break; }
          if (dilated[ny * w + nx] <= 128) allStrong = false;
        }
      }
      amask[y * w + x] = allStrong ? 255 : 0;
    }
  }

  // Write morphed-alpha back into pixel buffer
  for (int i = 0; i < w * h; i++) {
    px.setUint8(i * 4 + 3, amask[i]);
  }

  // Step 5: resize to 256x64 nearest-neighbour
  final Image resized = copyResize(
    workingImage,
    width: 256,
    height: 64,
    interpolation: Interpolation.nearest,
  );

  return encodePng(resized);
}

// helpers

class EdgeCol {
  final int r, g, b;
  const EdgeCol(this.r, this.g, this.b);
}

EdgeCol _findDominantEdgeColour(Image img, int w, int h) {
  final ByteData pxBuf = img.data!.getBytes().buffer.asByteData();
  final Map<String, int> hist = <String, int>{};

  void count(int o) {
    final a = pxBuf.getUint8(o + 3);
    if (a <= 20) return;
    final k = '${pxBuf.getUint8(o).toRadixString(16).padLeft(2, '0')}'
              '${pxBuf.getUint8(o + 1).toRadixString(16).padLeft(2, '0')}'
              '${pxBuf.getUint8(o + 2).toRadixString(16).padLeft(2, '0')}';
    hist[k] = (hist[k] ?? 0) + 1;
  }

  for (int x = 0; x < w; x++) {
    count(x * 4);
    count((h - 1) * w * 4 + x * 4);
  }
  for (int y = 0; y < h; y++) {
    count(y * w * 4);
    count(y * w * 4 + (w - 1) * 4);
  }

  final sorted = hist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final String top = sorted.isEmpty ? 'ffffff' : sorted.first.key;
  return EdgeCol(int.parse(top.substring(0, 2), radix: 16),
                  int.parse(top.substring(2, 4), radix: 16),
                  int.parse(top.substring(4, 6), radix: 16));
}

bool _near(ByteData px, int off, int br, int bg, int bb, int tol) {
  final r = px.getUint8(off), g = px.getUint8(off + 1), b = px.getUint8(off + 2);
  final a = px.getUint8(off + 3);
  if (a <= 20) return false;
  return (r - br).abs() <= tol && (g - bg).abs() <= tol && (b - bb).abs() <= tol;
}

bool _lumaDiffOk(int offA, EdgeCol bg, ByteData px) {
  final ra = px.getUint8(offA);
  final ga = px.getUint8(offA + 1);
  final ba = px.getUint8(offA + 2);
  final dr = ra - bg.r, dg = ga - bg.g, db = ba - bg.b;
  return (0.299 * dr.abs() + 0.587 * dg.abs() + 0.114 * db.abs()) < 25.0;
}

Image _cloneToRgba(Image src) {
  final int ch = src.numChannels;
  final Uint8List srcBuf = src.data!.getBytes();
  final int pxCount = src.width * src.height;
  final Uint8List rgba = Uint8List(pxCount * 4);

  for (int i = 0; i < pxCount; i++) {
    final so = i * ch;
    final do_ = i * 4;
    rgba[do_] = srcBuf[so];
    rgba[do_ + 1] = ch > 1 ? srcBuf[so + 1] : srcBuf[so];
    rgba[do_ + 2] = ch > 2 ? srcBuf[so + 2] : srcBuf[so];
    rgba[do_ + 3] = 255;
  }

  return Image.fromBytes(
    width: src.width,
    height: src.height,
    bytes: rgba.buffer,
    numChannels: 4,
  );
}
