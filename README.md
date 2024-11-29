## Flutter markdown ext demo



> test 文件夹内包含测试的方式，[widgets](lib%2Fwidgets)内包含基础的代码，代码是完全可用的，可以直接复制到项目中使用。




#### code examples


```dart
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

```


### package

* [pubspec.yaml](pubspec.yaml) 文件内有一些没用的可以去掉，我为什么没去掉`我懒` ：）

```yaml
  markdown: ^7.1.1
  json5: ^0.8.2
  flutter_markdown: ^0.7.4+3
  image_picker: ^1.1.2
  url_launcher: ^6.0.0
  json_annotation: ^4.0.0
  permission_handler: ^11.0.1
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  lzstring: ^2.0.0
```


### project init

```bash
flutter pub get
```