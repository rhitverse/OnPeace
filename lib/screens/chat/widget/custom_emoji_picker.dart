import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:on_peace/colors.dart';
import 'package:on_peace/secret/secret.dart';

class GifItem {
  final String id;
  final String previewUrl;
  final String originalUrl;

  const GifItem({
    required this.id,
    required this.previewUrl,
    required this.originalUrl,
  });

  factory GifItem.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>;
    return GifItem(
      id: json['id'] as String,
      previewUrl:
          (images['fixed_width_small'] ?? images['fixed_width'])['url']
              as String,
      originalUrl: images['original']['url'] as String,
    );
  }
}

class CustomEmojiPicker extends StatefulWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final void Function(String gifUrl)? onGiftSelected;

  const CustomEmojiPicker({
    super.key,
    required this.controller,
    required this.scrollController,
    this.onGiftSelected,
  });

  @override
  State<CustomEmojiPicker> createState() => _CustomEmojiPickerState();
}

class _CustomEmojiPickerState extends State<CustomEmojiPicker>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didUpdateWidget(covariant CustomEmojiPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _tabController.index = 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          height: MediaQuery.of(context).size.height * 0.04,
          decoration: BoxDecoration(
            color: const Color(0xff131419),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: searchBarColor,
              borderRadius: BorderRadius.circular(20),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            labelPadding: EdgeInsets.zero,
            padding: const EdgeInsets.all(3),
            tabs: const [
              Tab(text: "Emoji"),
              Tab(text: "GIFs"),
              Tab(text: "Stickers"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _emojiTab(),
              _GifGridTab(
                type: _GifType.gif,
                onGifSelected: widget.onGiftSelected,
              ),
              _GifGridTab(
                type: _GifType.sticker,
                onGifSelected: widget.onGiftSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emojiTab() {
    return EmojiPicker(
      textEditingController: widget.controller,
      onEmojiSelected: (category, emoji) {
        final text = widget.controller.text;
        final selection = widget.controller.selection;
        final newText = selection.isValid
            ? text.replaceRange(selection.start, selection.end, emoji.emoji)
            : text + emoji.emoji;

        widget.controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
            offset: selection.isValid
                ? selection.start + emoji.emoji.length
                : newText.length,
          ),
        );
      },
      config: Config(
        checkPlatformCompatibility: true,
        emojiViewConfig: EmojiViewConfig(
          columns: 8,
          emojiSizeMax: 28,
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          backgroundColor: backgroundColor,
          buttonMode: ButtonMode.MATERIAL,
          noRecents: const Text(
            'No Recents',
            style: TextStyle(fontSize: 15, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          loadingIndicator: const SizedBox.shrink(),
          replaceEmojiOnLimitExceed: false,
        ),
        categoryViewConfig: const CategoryViewConfig(
          backgroundColor: backgroundColor,
          indicatorColor: whiteColor,
          iconColorSelected: whiteColor,
          iconColor: Colors.grey,
          categoryIcons: CategoryIcons(),
        ),
        searchViewConfig: const SearchViewConfig(
          backgroundColor: Color(0xff131419),
          buttonIconColor: Colors.grey,
        ),
        bottomActionBarConfig: const BottomActionBarConfig(
          enabled: true,
          buttonColor: backgroundColor,
          backgroundColor: backgroundColor,
          buttonIconColor: whiteColor,
          showSearchViewButton: true,
          showBackspaceButton: true,
        ),
        skinToneConfig: const SkinToneConfig(enabled: false),
      ),
    );
  }
}

enum _GifType { gif, sticker }

class _GifGridTab extends StatefulWidget {
  final _GifType type;
  final void Function(String gifUrl)? onGifSelected;
  const _GifGridTab({required this.type, this.onGifSelected});

  @override
  State<_GifGridTab> createState() => _GifGridTabState();
}

class _GifGridTabState extends State<_GifGridTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<GifItem> _gifs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _query = '';
  int _offset = 0;
  bool _hasMore = true;
  Timer? _debounce;

  static const int _limit = 24;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchTrending();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchController.text.trim();
      if (q == _query) return;
      _query = q;
      _offset = 0;
      _hasMore = true;
      setState(() => _gifs = []);
      q.isEmpty ? _fetchTrending() : _fetchSearch(q);
    });
  }

  String get _endPoint {
    if (_query.isNotEmpty) {
      return widget.type == _GifType.gif
          ? '/v1/gifs/search'
          : '/v1/stickers/search';
    }
    return widget.type == _GifType.gif
        ? '/v1/gifs/trending'
        : '/v1/stickers/trending';
  }

  Future<List<GifItem>> _callGiphy(Map<String, String> extraParams) async {
    final uri = Uri.https('api.giphy.com', _endPoint, {
      'api_key': Secrets.giphyApiKey,
      'limit': _limit.toString(),
      'rating': 'g',
      ...extraParams,
    });
    try {
      final res = await http.get(uri);
      print("✅URL: $uri");
      print("✅STATUS: ${res.statusCode}");
      print("✅BODY: ${res.body}");
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as List<dynamic>;
      if (data.length < _limit) _hasMore = false;
      return data
          .map((e) => GifItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _fetchTrending() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final gifs = await _callGiphy({'offset': '0'});
    _offset = gifs.length;
    if (mounted) {
      setState(() {
        _gifs = gifs;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSearch(String q) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final gifs = await _callGiphy({'q': q, 'offset': '0'});
    _offset = gifs.length;
    if (mounted) {
      setState(() {
        _gifs = gifs;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final params = _query.isEmpty
        ? {'offset': _offset.toString()}
        : {'q': _query, 'offset': _offset.toString()};
    final more = await _callGiphy(params);
    _offset += more.length;
    if (mounted) {
      setState(() {
        _gifs.addAll(more);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: TextField(
            controller: _searchController,
            cursorColor: uiColor,
            style: const TextStyle(color: whiteColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.type == _GifType.gif
                  ? 'Search GIPHY'
                  : 'Search GIPHY Stickers',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: _searchController.clear,
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 18,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xff131419),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _query.isEmpty
                  ? (widget.type == _GifType.gif
                        ? 'Trending GIPHY'
                        : 'Trending GIPHY Stickers')
                  : 'Results for "$_query"',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white38),
                )
              : _gifs.isEmpty
              ? Center(
                  child: Text(
                    widget.type == _GifType.gif
                        ? 'No GIFs found'
                        : 'No Stickers found',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _gifs.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == _gifs.length) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white38,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () =>
                          widget.onGifSelected?.call(_gifs[i].originalUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: _gifs[i].previewUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => Container(
                            color: const Color(0xff2a2b30),
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white24,
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (_, _, _) => Container(
                            color: const Color(0xff2a2b30),
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white24,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
