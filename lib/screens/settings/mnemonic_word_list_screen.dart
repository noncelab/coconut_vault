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
    _filteredItems = List.generate(
        wordList.length, (index) => {'index': index + 1, 'item': wordList[index]}).where((element) {
      final item = element['item'] as String;
      return item.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) {
        final itemA = (a['item'] as String).toLowerCase();
        final itemB = (b['item'] as String).toLowerCase();

        final startsWithA = itemA.startsWith(query);
        final startsWithB = itemB.startsWith(query);

        if (startsWithA && !startsWithB) {
          return -1; // itemA가 우선
        } else if (!startsWithA && startsWithB) {
          return 1; // itemB가 우선
        } else {
          // 둘 다 query로 시작하거나 둘 다 포함하는 경우는 알파벳 순으로 결정
          return itemA.compareTo(itemB);
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
          isBottom: true,
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
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                      controller: _searchController,
                      maxLines: 1,
                      maxLength: 10,
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
    List<TextSpan> highlightOccurrences(String source, String query) {
      if (query.isEmpty) {
        return [
          TextSpan(
            text: source,
            style: const TextStyle(color: CoconutColors.black),
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
            style: const TextStyle(color: CoconutColors.black),
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
            style: const TextStyle(fontWeight: FontWeight.bold, color: CoconutColors.black),
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
                    Text(
                      '${_filteredItems[index]['index']}. ',
                      style: CoconutTypography.body1_16_Number.setColor(
                        CoconutColors.gray500,
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
              Text(
                'Binary: ${(_filteredItems[index]['index'] - 1).toRadixString(2).padLeft(11, '0')}',
                style: CoconutTypography.body2_14.setColor(
                  CoconutColors.black.withOpacity(0.5),
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
