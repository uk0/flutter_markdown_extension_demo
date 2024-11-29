// lib/widgets/markdown_view.dart.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'markdown_builders.dart';
import 'package:markdown/markdown.dart' as md;


class MarkdownView extends StatelessWidget {
  final String data;

  const MarkdownView({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Markdown(
              data: data,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              builders: {
                'searchImage': ExtendedMarkdownElementBuilder(),
                'searchResult': ExtendedMarkdownElementBuilder(),
                'wait': ExtendedMarkdownElementBuilder(),
                'warning': ExtendedMarkdownElementBuilder(),
              },
              extensionSet: md.ExtensionSet(

                <md.BlockSyntax>[
                  ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                ],
                <md.InlineSyntax>[
                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                  SearchImageSyntax(), //图片搜索加密内容解析
                  SearchWebSyntax(), // web搜索内容加密解析
                  WaitSyntax(), // 等待
                  WaringSyntax(), // 警告
                ],
              ),
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyMedium,
                h1: Theme.of(context).textTheme.headlineMedium,
                h2: Theme.of(context).textTheme.titleLarge,
                h3: Theme.of(context).textTheme.titleMedium,
                code: TextStyle(
                  backgroundColor: Colors.grey[200],
                  fontFamily: 'monospace',
                ),
                blockquote: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                tableBorder: TableBorder.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
                tableHead: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tableBody: Theme.of(context).textTheme.bodyMedium,
                listBullet: Theme.of(context).textTheme.bodyMedium,
              ),
              selectable: true,
              softLineBreak: true,
              listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
            ),
          ),
        );
      },
    );
  }
}