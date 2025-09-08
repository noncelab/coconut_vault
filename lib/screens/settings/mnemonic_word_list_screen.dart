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

    if (!_isFabShown) {
      if (scrollPosition.pixels > 450) {
        setState(() {
          _isFabShown = true;
        });
      }
    } else if (_isTop) {
      setState(() {
        _isFabShown = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.jumpTo(
      0.0,
    );
  }

  void _filterItems() {
    if (_searchController.text.isNotEmpty) {
      setState(() {
        _queryWord();
      });
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

    _filteredItems = List.generate(wordList.length, (index) => {
        'index': index + 1,
        'item': wordList[index],
      }).where((element) {
    final item = element['item'] as String;
    final indexNum = element['index'] as int;

    if (isBinary && query.length >= 4) {
      // Binary 검색
      final binaryStr = (indexNum - 1).toRadixString(2).padLeft(11, '0');
      return binaryStr.contains(query);
    } else if (isNumeric) {
      // 목차 검색
      return indexNum.toString().contains(query);
    } else if (isAlphabetic) {
      // 영문 검색
      return item.toLowerCase().contains(query);
    } else {
      return false;
    }
  }).toList()
    ..sort((a, b) {
      final itemA = (a['item'] as String).toLowerCase();
      final itemB = (b['item'] as String).toLowerCase();
      final indexA = a['index'] as int;
      final indexB = b['index'] as int;

      // 문자열 검색 시 query로 시작하는 순서 우선
      if (isAlphabetic) {
        final startsWithA = itemA.startsWith(query);
        final startsWithB = itemB.startsWith(query);

        if (startsWithA && !startsWithB) {
          return -1;
        } else if (!startsWithA && startsWithB) {
          return 1;
        } else {
          return itemA.compareTo(itemB);
        }
      } else {
        // 숫자/바이너리 검색 시 index 오름차순
        return indexA.compareTo(indexB);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: CoconutColors.white,
        appBar: CoconutAppBar.build(
          title: _titleText,
          context: context,
          isBottom: false,
        ),
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
                        hintStyle: CoconutTypography.body2_14.setColor(
                          CoconutColors.searchbarHint,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: CoconutColors.searchbarHint,
                        ),
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
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: _resultWidget(),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _filteredItems.length,
                itemBuilder: (ctx, index) {
                  return _buildListItem(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultWidget() {
    return _searchController.text.isEmpty
        ? Container()
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.mnemonic_word_list_screen.result(text: _searchController.text),
                    style: CoconutTypography.body1_16.setColor(
                      CoconutColors.black.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              _filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Text(
                          t.mnemonic_word_list_screen.such_no_result,
                          style: CoconutTypography.body1_16_Bold.setColor(
                            CoconutColors.searchbarHint,
                          ),
                        ),
                      ),
                    )
                  : Container(),
            ],
          );
  }

  Widget _buildListItem(BuildContext context, int index) {
    String item = _filteredItems[index]['item'];
    int indexNum = _filteredItems[index]['index'];
    String query = _searchController.text.toLowerCase();

    final isBinary = RegExp(r'^[01]+$').hasMatch(query);
    final isNumeric = RegExp(r'^\d+$').hasMatch(query);
    final isAlphabetic = RegExp(r'^[a-zA-Z]+$').hasMatch(query);

    String highlightTarget;
    if (isBinary && query.length >= 5) {
      highlightTarget = (indexNum - 1).toRadixString(2).padLeft(11, '0');
    } else if (isNumeric) {
      highlightTarget = indexNum.toString();
    } else {
      highlightTarget = item.toLowerCase();
    }
    
    List<TextSpan> highlightOccurrences(String source, String query, {bool isIndex = false}) {
      if (query.isEmpty) {
        return [
          TextSpan(
            text: source,
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: CoconutColors.black),
          )
        ];
      }
      var matches = query.allMatches(source);
      if (matches.isEmpty) {
        return [
          TextSpan(
            text: source,
            style: const TextStyle(color: CoconutColors.black),
          )
        ];
      }
      List<TextSpan> spans = [];
      int lastMatchEnd = 0;
      for (var match in matches) {
        if (match.start != lastMatchEnd) {
          spans.add(TextSpan(
            text: source.substring(lastMatchEnd, match.start),
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: CoconutColors.black),
          ));
        }
        spans.add(
          TextSpan(
            text: source.substring(match.start, match.end),
            style: const TextStyle(fontWeight: FontWeight.bold, color: CoconutColors.cyanBlue),
          ),
        );
        lastMatchEnd = match.end;
      }
      if (lastMatchEnd != source.length) {
        spans.add(
          TextSpan(
            text: source.substring(lastMatchEnd),
            style: isIndex
                ? CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500)
                : const TextStyle(color: CoconutColors.black),
          ),
        );
      }
      return spans;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    RichText(
                      text: TextSpan(
                        style: CoconutTypography.body1_16_Number.setColor(CoconutColors.gray500),
                        children: highlightOccurrences(
                          '${indexNum}. ',
                          isNumeric ? query : '',
                          isIndex: true,
                        ),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: highlightOccurrences(item, _searchController.text.toLowerCase()),
                        style: CoconutTypography.heading4_18_Bold
                            .merge(const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: CoconutTypography.body2_14.setColor(
                    CoconutColors.black.withOpacity(0.5),
                  ),
                  children: [
                    const TextSpan(text: "Binary: "),
                    ...highlightOccurrences((indexNum - 1).toRadixString(2).padLeft(11, '0'), isBinary ? query : ''),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (index != wordList.length - 1) const Divider(color: CoconutColors.borderLightGray),
      ],
    );
  }
}
