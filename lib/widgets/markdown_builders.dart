// lib/widgets/markdown_builders.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json5/json5.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lzstring/lzstring.dart';



class ExtendedMarkdownElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    switch (element.tag) {
      case 'warning':
        return _buildWarning(element.textContent, preferredStyle);
      case 'wait':
        return _buildWait(element.textContent, preferredStyle);
      case 'searchImage':
        return _buildSearchImage(element);
      case 'searchResult':
        return _buildSearchResult(element);
      case 'customImage':
        return _buildCustomImage(element);
      case 'customLink':
        return _buildCustomLink(element, preferredStyle);
      default:
        return null;
    }
  }

  Widget _buildWarning(String? text, TextStyle? style) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text ?? '', style: style),
          ),
        ],
      ),
    );
  }

  Widget _buildWait(String? text, TextStyle? style) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Text(text ?? '', style: style),
          const SizedBox(width: 4),
          const _WaitingDots(),
        ],
      ),
    );
  }

  Widget _buildCustomImage(md.Element element) {
    final String? path = element.attributes['src'];
    final bool isExternal = path?.startsWith('http') ?? false;
    final String imagePath = _processImagePath(path ?? '', isExternal);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imagePath,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) => _buildImageError(),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: _buildDownloadButton(imagePath),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchImage(md.Element element) {
    // element.textContent 会包含 JSON 字符串
    final List<dynamic> images = _parseSearchImages(element.textContent);
    print('Images: $images');
    return GridView.builder(
      key: ValueKey('thumbnail_grid_${images.length}'), // 使用 ValueKey 而不是 GlobalKey
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return _buildSearchImageItem(image);
      },
    );
  }

  Widget _buildSearchResult(md.Element element) {
    final List<dynamic> results = _parseSearchResults(element.textContent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Source:',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold
          ),
        ),
        const SizedBox(height: 8),
        ...results.map((result) => _buildSearchResultItem(result)),
      ],
    );
  }

  Widget _buildCustomLink(md.Element element, TextStyle? style) {
    final String text = element.textContent ?? '';
    final String? url = element.attributes['href'];
    final String? title = element.attributes['title'];

    return InkWell(
      onTap: () => _launchUrl(url),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// 辅助组件
class _WaitingDots extends StatefulWidget {
  const _WaitingDots({Key? key}) : super(key: key);

  @override
  _WaitingDotsState createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
    _controller.addListener(() {
      setState(() {
        _dotCount = (_controller.value * 3).floor() + 1;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('.' * _dotCount);
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';
    if (element.attributes['class'] != null) {
      language = element.attributes['class']!
          .replaceAll('language-', '');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[800]!,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                language,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Text(
              element.textContent ?? '',
              style: TextStyle(
                color: Colors.grey[300],
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class SearchImageSyntax extends md.InlineSyntax {
  SearchImageSyntax()
      : super(
    r':::ThumbnailStart\s+((?:(?!:::).)+?):::',
    startCharacter: ':'.codeUnits.single,
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      final compressed = match[1] ?? '';
      print('Compressed: $compressed');
      final decompressed = LZString.decompressFromBase64Sync(compressed);
      if (decompressed == null) {
        throw FormatException('Failed to decompress data');
      }

      final List<dynamic> parsed = json5Decode(decompressed);
      print('Parsed: $parsed');
      // 创建带有 thumbnail 标签的 Element
      parser.addNode(md.Element('searchImage', [
        md.Text(json.encode(parsed))
      ]));
    } catch (e) {
      print('Error parsing searchImage data: $e');
      parser.addNode(md.Element('searchImage', []));    }
    return true;
  }
}

// WaringSyntax

class WaringSyntax extends md.InlineSyntax {
  WaringSyntax()
      : super(
    r':::warning\s+((?:(?!:::).)+?):::',
    startCharacter: ':'.codeUnits.single,
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      final match_str = match[1] ?? '';
      print('match_str: $match_str');
      // 创建带有 thumbnail 标签的 Element
      parser.addNode(md.Element('warning', [
        md.Text(match_str)
      ]));
    } catch (e) {
      print('Error parsing warning data: $e');
      parser.addNode(md.Element('warning', []));    }
    return true;
  }
}


// WaitSyntax

class WaitSyntax extends md.InlineSyntax {
  WaitSyntax()
      : super(
    r':::wait\s+((?:(?!:::).)+?):::',
    startCharacter: ':'.codeUnits.single,
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      final match_str = match[1] ?? '';
      print('match_str: $match_str');
      // 创建带有 thumbnail 标签的 Element
      parser.addNode(md.Element('wait', [
        md.Text(match_str)
      ]));
    } catch (e) {
      print('Error parsing wait data: $e');
      parser.addNode(md.Element('wait', []));
    }
    return true;
  }
}



// LinkStart
class SearchWebSyntax extends md.InlineSyntax {
  SearchWebSyntax()
      : super(
    r':::LinkStart\s+((?:(?!:::).)+?):::',
    startCharacter: ':'.codeUnits.single,
  );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    try {
      final compressed = match[1] ?? '';
      print('Compressed: $compressed');
      final decompressed = LZString.decompressFromBase64Sync(compressed);
      if (decompressed == null) {
        throw FormatException('Failed to decompress data');
      }

      final List<dynamic> parsed = json5Decode(decompressed);
      print('Parsed: $parsed');
      // 创建带有 thumbnail 标签的 Element
      parser.addNode(md.Element('searchResult', [
        md.Text(json.encode(parsed))
      ]));
    } catch (e) {
      print('Error parsing searchResult data: $e');
      parser.addNode(md.Element('searchResult', []));    }
    return true;
  }
}


class ImageElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'];
    if (src == null) return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          src,
          // 限制最大高度
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    '图片加载失败',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


String _processImagePath(String path, bool isExternal) {
  if (isExternal) return path;
  if (path.endsWith('.png') || path.endsWith('.jpeg') || path.endsWith('.jpg')) {
    return '/image/$path';
  }
  return '/image/gen/img/$path';
}

List<dynamic> _parseSearchImages(String data) {
  try {
    return json5Decode(data);
  } catch (e) {
    print('Error parsing search images: $e');
    return [];
  }
}

List<dynamic> _parseSearchResults(String data) {
  try {
    return json5Decode(data);
  } catch (e) {
    print('Error parsing search results: $e');
    return [];
  }
}

Future<void> _launchUrl(String? url) async {
  if (url == null) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Widget _buildSearchImageItem(Map<String, dynamic> image) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // 图片
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            image['thumbnail_src'] ?? '',
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
          ),
        ),

        // 悬浮层
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (image['link'] != null) {
                launchUrl(Uri.parse(image['link']));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        // 底部信息栏
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 分辨率
                Expanded(
                  child: Text(
                    image['resolution'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 下载按钮
                if (image['img_src'] != null)
                  GestureDetector(
                    onTap: () {
                      launchUrl(Uri.parse(image['img_src']));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.download_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSearchResultItem(Map<String, dynamic> result) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 网站图标
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(top: 2, right: 8),
          child: Image.network(
            'https://www.google.com/s2/favicons?domain=${Uri.parse(result['link'] ?? '').host}',
            width: 16,
            height: 16,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.public,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),

        // 内容
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              InkWell(
                onTap: () {
                  if (result['link'] != null) {
                    launchUrl(Uri.parse(result['link']));
                  }
                },
                child: Text(
                  result['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // 描述
              Text(
                result['description'] ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildImageError() {
  return Container(
    height: 200,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 32,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 8),
        Text(
          '图片加载失败',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDownloadButton(String imageUrl) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _downloadImage(imageUrl),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.download_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    ),
  );
}

// 下载图片的方法
Future<void> _downloadImage(String imageUrl) async {
  try {
    final uri = Uri.parse(imageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  } catch (e) {
    print('Error downloading image: $e');
  }
}
