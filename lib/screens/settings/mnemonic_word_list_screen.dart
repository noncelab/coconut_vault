import 'package:coconut_design_system/coconut_design_system.dart';
import 'package:coconut_lib/coconut_lib.dart';
import 'package:coconut_vault/localization/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MnemonicWordListScreen extends StatefulWidget {
  const MnemonicWordListScreen({super.key});

  @override
  State<MnemonicWordListScreen> createState() => _MnemonicWordListScreenState();
}

class _MnemonicWordListScreenState extends State<MnemonicWordListScreen> {
  final String _titleText = t.mnemonic_wordlist;
  final String _hintText = t.mnemonic_word_list_screen.search_mnemonic_word;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _filteredItems = [];
  late bool _isTop;
  bool _isFabShown = false;

  Color _searchbarBackgroundColor = CoconutColors.white;
  Color _searchbarFillColor = CoconutColors.black.withOpacity(0.06);

  @override
  void initState() {
    super.initState();
    _filteredItems =
        List.generate(wordList.length, (index) => {'index': index + 1, 'item': wordList[index]});

    _isTop = true;

    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final scrollPosition = _scrollController.position;

    if (_isTop) {
      if (scrollPosition.pixels > 0) {
        _isTop = !_isTop;
        setState(() {
          _searchbarBackgroundColor = CoconutColors.whiteLilac;
          _searchbarFillColor = CoconutColors.white;
        });
      }
    } else {
      if (scrollPosition.pixels <= 0) {
        _isTop = !_isTop;
        setState(() {
          _searchbarBackgroundColor = CoconutColors.white;
          _searchbarFillColor = CoconutColors.borderLightGray;
        });
      }
    }

    if (!_isFabShown && scrollPosition.pixels > 450) {
      setState(() => _isFabShown = true);
    } else if (_isTop) {
      setState(() => _isFabShown = false);
    }
  }

  void _scrollToTop() {
    _scrollController.jumpTo(0.0);
  }

  void _filterItems() {
    if (_searchController.text.isNotEmpty) {
      setState(_queryWord);
    } else {
      setState(() {
        _filteredItems = List.generate(
            wordList.length, (index) => {'index': index + 1, 'item': wordList[index]});
      });
    }
  }

  void _queryWord() {
    String query = _searchController.text.toLowerCase();

    final isBinary = RegExp(r'^[01]+$').hasMatch(query);
    final isNumeric = RegExp(r'^\d+$').hasMatch(query);
    final isAlphabetic = RegExp(r'^[a-zA-Z]+$').hasMatch(query);

    List<Map<String, dynamic>> numericResults = [];
    List<Map<String, dynamic>> binaryResults = [];
    List<Map<String, dynamic>> alphabeticResults = [];

    for (int i = 0; i < wordList.length; i++) {
      final item = wordList[i];
      final indexNum = i + 1;

      if (isNumeric && query.length <= 4 && indexNum.toString().contains(query)) {
        numericResults.add({'index': indexNum, 'item': item, 'type': 'numeric'});
      }

      if (isBinary) {
        final binaryStr = (indexNum - 1).toRadixString(2).padLeft(11, '0');
        if (binaryStr.contains(query)) {
          binaryResults.add({'index': indexNum, 'item': item, 'type': 'binary'});
        }
      }

      if (isAlphabetic && item.toLowerCase().contains(query)) {
        alphabeticResults.add({'index': indexNum, 'item': item, 'type': 'alphabetic'});
      }
    }

    if (isAlphabetic) {
      alphabeticResults.sort((a, b) {
        final itemA = (a['item'] as String).toLowerCase();
        final itemB = (b['item'] as String).toLowerCase();

        final startsWithA = itemA.startsWith(query);
        final startsWithB = itemB.startsWith(query);

        if (startsWithA && !startsWithB) return -1;
        if (!startsWithA && startsWithB) return 1;
        return itemA.compareTo(itemB);
      });
      _filteredItems = alphabeticResults;
    } else {
      numericResults.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
      binaryResults.sort((a, b) => (a['index'] as int).compareTo(b['index'] as int));
      _filteredItems = [...numericResults, ...binaryResults];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(title: _titleText, context: context, isBottom: false),
        floatingActionButton: Visibility(
          visible: _isFabShown,
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            backgroundColor: CoconutColors.white,
            foregroundColor: CoconutColors.gray500,
            shape: const CircleBorder(),
            mini: true,
            child: const Icon(Icons.arrow_upward),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: _searchbarBackgroundColor,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: _searchbarFillColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                      ],
                      controller: _searchController,
                      maxLines: 1,
                      maxLength: 11,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: _hintText,
                        hintStyle: CoconutTypography.body2_14.setColor(CoconutColors.searchbarHint),
                        prefixIcon: const Icon(Icons.search_rounded, color: CoconutColors.searchbarHint),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                      ),
                      style: const TextStyle(
                        decorationThickness: 0,
                        color: CoconutColors.searchbarText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: MediaQuery.of(context).size.width, child: _resultWidget()),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _filteredItems.length,
                itemBuilder: (ctx, index) => _buildListItem(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultWidget() {
    if (_searchController.text.isEmpty) return Container();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t.mnemonic_word_list_screen.result(text: _searchController.text),
              style: CoconutTypography.body1_16.setColor(CoconutColors.black.withOpacity(0.5)),
            ),
          ),
        ),
        if (_filteredItems.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Text(
                t.mnemonic_word_list_screen.such_no_result,
                style: CoconutTypography.body1_16_Bold.setColor(CoconutColors.searchbarHint),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    final item = _filteredItems[index]['item'] as String;
    final indexNum = _filteredItems[index]['index'] as int;
    final type = _filteredItems[index]['type'] as String?;
    final query = _searchController.text.toLowerCase();

    List<TextSpan> highlightOccurrences(String source, String query,
        {String? type, bool isIndex = false}) {
      if (query.isEmpty) {
        return [
          TextSpan(
            text: source,
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: Colors.black),
          )
        ];
      }

      final matches = query.allMatches(source);
      if (matches.isEmpty) {
        return [
          TextSpan(
            text: source,
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: Colors.black),
          )
        ];
      }

      Color highlightColor;
      switch (type) {
        case 'numeric':
          highlightColor = CoconutColors.cyanBlue;
          break;
        case 'binary':
          highlightColor = CoconutColors.cyanBlue;
          break;
        default:
          highlightColor = CoconutColors.cyanBlue;
      }

      final spans = <TextSpan>[];
      int lastMatchEnd = 0;
      for (final match in matches) {
        if (match.start != lastMatchEnd) {
          spans.add(TextSpan(
            text: source.substring(lastMatchEnd, match.start),
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: Colors.black),
          ));
        }
        spans.add(TextSpan(
          text: source.substring(match.start, match.end),
          style: TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
        ));
        lastMatchEnd = match.end;
      }
      if (lastMatchEnd != source.length) {
        spans.add(TextSpan(
          text: source.substring(lastMatchEnd),
          style: isIndex
              ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
              : const TextStyle(color: Colors.black),
        ));
      }
      return spans;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      style: CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500),
                      children: highlightOccurrences(
                        '$indexNum. ',
                        type == 'numeric' ? query : '',
                        isIndex: true,
                        type: type,
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: highlightOccurrences(item, query, type: type),
                      style: CoconutTypography.heading4_18_Bold
                          .merge(const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: CoconutTypography.body2_14.setColor(
                    CoconutColors.black.withOpacity(0.5),
                  ),
                  children: [
                    const TextSpan(text: 'Binary: '),
                    ...highlightOccurrences(
                      (indexNum - 1).toRadixString(2).padLeft(11, '0'),
                      type == 'binary' ? query : '',
                      type: 'binary',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (index != _filteredItems.length - 1)
          const Divider(color: CoconutColors.borderLightGray),
      ],
    );
  }
}