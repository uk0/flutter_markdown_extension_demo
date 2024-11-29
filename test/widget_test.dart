import 'package:flutter_test/flutter_test.dart';
import 'package:json5/json5.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:convert';
import 'package:lzstring/lzstring.dart';

class ThumbnailSyntax extends md.InlineSyntax {
  ThumbnailSyntax()
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
      parser.addNode(md.Element.text('thumbnail', json.encode(parsed)));
    } catch (e) {
      print('Error parsing thumbnail data: $e');
      parser.addNode(md.Element.text('thumbnail', 'ERROR: ${e.toString()}'));
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

void main() {
  group('ThumbnailSyntax Tests', () {
    late md.Document document;
    late ThumbnailSyntax thumbnailSyntax;
    late SearchWebSyntax webSearchSyntax;

    setUp(() {
      thumbnailSyntax = ThumbnailSyntax();
      webSearchSyntax = SearchWebSyntax();
      document = md.Document(
        extensionSet: md.ExtensionSet(
          <md.BlockSyntax>[],
          <md.InlineSyntax>[thumbnailSyntax,webSearchSyntax],
        ),
      );
    });

    test('should parse valid thumbnail data', () async {
      // // 准备测试数据
      // final testData = [
      //   {
      //     'url': 'https://example.com/image.jpg',
      //     'title': 'Test Image'
      //   }
      // ];
      //
      // // 压缩数据
      // final compressed = LZString.compressToBase64Sync(json5Encode(testData));
      // print('Compressed data: $compressed');

      final markdown = ':::ThumbnailStart xxxxxxxxxxxxxxxx :::';

      // 解析markdown
      final nodes = document.parse(markdown);

      final markdown_web = ':::LinkStart xxxxxxxxxxxxxxxxx :::';

      // 解析markdown
      final nodes_web = document.parse(markdown_web);


      // 验证结果
      expect(nodes, isNotEmpty);
      expect(nodes_web, isNotEmpty);
    });
  });
}