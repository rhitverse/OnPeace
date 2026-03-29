import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/chat/widget/camera_ui.dart';

Future<List<File>> showDiaryAttachmentSheet(BuildContext context) async {
  final result = await showModalBottomSheet<List<File>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => const _DiaryAttachmentSheet(),
  );
  return result ?? [];
}

class _DiaryAttachmentSheet extends StatefulWidget {
  const _DiaryAttachmentSheet();

  @override
  State<_DiaryAttachmentSheet> createState() => _DiaryAttachmentSheetState();
}

class _DiaryAttachmentSheetState extends State<_DiaryAttachmentSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  List<AssetEntity> _assets = [];
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;
  bool _loading = true;
  bool _showAlbumDropdown = false;
  String _permissionError = '';

  final List<AssetEntity> _selected = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _loadGallery();
  }

  Future<void> _loadGallery() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth && !ps.hasAccess) {
      setState(() {
        _loading = false;
        _permissionError = 'Gallery permission denied';
      });
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final defaultAlbum = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );

    final assets = await defaultAlbum.getAssetListPaged(page: 0, size: 80);

    if (mounted) {
      setState(() {
        _albums = albums;
        _currentAlbum = defaultAlbum;
        _assets = assets;
        _loading = false;
      });
    }
  }

  Future<void> _switchAlbum(AssetPathEntity album) async {
    setState(() {
      _loading = true;
      _showAlbumDropdown = false;
      _currentAlbum = album;
      _selected.clear();
    });
    final assets = await album.getAssetListPaged(page: 0, size: 80);
    if (mounted)
      setState(() {
        _assets = assets;
        _loading = false;
      });
  }

  void _toggleSelect(AssetEntity asset) {
    setState(() {
      if (_selected.contains(asset)) {
        _selected.remove(asset);
      } else if (_selected.length < 10) {
        _selected.add(asset);
      }
    });
  }

  Future<void> _confirmSelected() async {
    if (_selected.isEmpty) return;
    final files = <File>[];
    for (final asset in _selected) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }
    if (mounted) Navigator.pop(context, files);
  }

  Future<void> _openCamera() async {
    Navigator.of(context).pop();
    final filePath = await Navigator.of(context).push<String?>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CameraUi(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (filePath != null && mounted) {
      Navigator.pop(context, [File(filePath)]);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: DraggableScrollableSheet(
          initialChildSize: 0.60,
          minChildSize: 0.40,
          maxChildSize: 0.90,
          expand: false,
          snap: true,
          snapSizes: const [0.60, 0.90],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 2),
                    child: Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  _SheetHeader(
                    currentAlbum: _currentAlbum,
                    selectedCount: _selected.length,
                    showDropdown: _showAlbumDropdown,
                    onConfirm: _selected.isNotEmpty ? _confirmSelected : null,
                    onToggleDropdown: () => setState(
                      () => _showAlbumDropdown = !_showAlbumDropdown,
                    ),
                  ),

                  if (_showAlbumDropdown)
                    _AlbumDropdown(
                      albums: _albums,
                      currentAlbum: _currentAlbum,
                      onSelect: _switchAlbum,
                    ),

                  Expanded(child: _buildBody(scrollController)),
                  SizedBox(height: mq.padding.bottom),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: calendarLightTheme1),
      );
    }

    if (_permissionError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              _permissionError,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: PhotoManager.openSetting,
              child: const Text(
                'Open Settings',
                style: TextStyle(color: calendarLightTheme1),
              ),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            width: 120,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: _CameraTile(onTap: _openCamera),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'No media found',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
        ],
      );
    }

    return _MediaGrid(
      assets: _assets,
      selected: _selected,
      onToggle: _toggleSelect,
      onCameraTap: _openCamera,
      scrollController: scrollController,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final AssetPathEntity? currentAlbum;
  final int selectedCount;
  final bool showDropdown;
  final VoidCallback? onConfirm;
  final VoidCallback onToggleDropdown;

  const _SheetHeader({
    required this.currentAlbum,
    required this.selectedCount,
    required this.showDropdown,
    required this.onToggleDropdown,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white70,
              size: 22,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onToggleDropdown,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      currentAlbum?.name ?? 'Recents',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: showDropdown ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedCount > 0)
            GestureDetector(
              onTap: onConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: calendarLightTheme1,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Add $selectedCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class _AlbumDropdown extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? currentAlbum;
  final void Function(AssetPathEntity) onSelect;

  const _AlbumDropdown({
    required this.albums,
    required this.currentAlbum,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: albums.length,
        itemBuilder: (_, i) {
          final album = albums[i];
          return _AlbumRow(
            album: album,
            isSelected: album.id == currentAlbum?.id,
            onTap: () => onSelect(album),
          );
        },
      ),
    );
  }
}

class _AlbumRow extends StatefulWidget {
  final AssetPathEntity album;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlbumRow({
    required this.album,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AlbumRow> createState() => _AlbumRowState();
}

class _AlbumRowState extends State<_AlbumRow> {
  Uint8List? _thumb;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final count = await widget.album.assetCountAsync;
    if (count == 0) {
      if (mounted) setState(() => _count = 0);
      return;
    }
    final assets = await widget.album.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return;
    final bytes = await assets.first.thumbnailDataWithSize(
      const ThumbnailSize(80, 80),
      quality: 70,
    );
    if (mounted)
      setState(() {
        _thumb = bytes;
        _count = count;
      });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        color: widget.isSelected ? const Color(0xFF2A2A2A) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _thumb != null
                    ? Image.memory(_thumb!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(
                          Icons.photo,
                          color: Colors.white24,
                          size: 22,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.album.name,
                    style: TextStyle(
                      color: widget.isSelected
                          ? calendarLightTheme1
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$_count items',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (widget.isSelected)
              const Icon(
                Icons.check_rounded,
                color: calendarLightTheme1,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  final List<AssetEntity> assets;
  final List<AssetEntity> selected;
  final void Function(AssetEntity) onToggle;
  final VoidCallback onCameraTap;
  final ScrollController scrollController;

  const _MediaGrid({
    required this.assets,
    required this.selected,
    required this.onToggle,
    required this.onCameraTap,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: assets.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _CameraTile(onTap: onCameraTap);
        final asset = assets[i - 1];
        final isSelected = selected.contains(asset);
        return _MediaTile(
          asset: asset,
          isSelected: isSelected,
          selectedIndex: selected.indexOf(asset),
          onTap: () => onToggle(asset),
        );
      },
    );
  }
}

class _CameraTile extends StatelessWidget {
  final VoidCallback onTap;
  const _CameraTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: const Color(0xFF1C1C1C),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, color: Colors.white60, size: 42),
            const SizedBox(height: 4),
            Text(
              'Camera',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaTile extends StatefulWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int selectedIndex;
  final VoidCallback onTap;

  const _MediaTile({
    required this.asset,
    required this.isSelected,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  State<_MediaTile> createState() => _MediaTileState();
}

class _MediaTileState extends State<_MediaTile> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
      quality: 80,
    );
    if (mounted) setState(() => _thumb = bytes);
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.asset.type == AssetType.video;
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _thumb != null
              ? Image.memory(_thumb!, fit: BoxFit.cover)
              : Container(color: const Color(0xFF1C1C1C)),

          if (widget.isSelected)
            Container(color: calendarLightTheme1.withOpacity(0.3)),

          if (isVideo)
            Positioned(
              bottom: 5,
              left: 5,
              child: Row(
                children: [
                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _formatDuration(widget.asset.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),

          Positioned(
            top: 6,
            right: 6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? calendarLightTheme1
                    : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected
                      ? calendarLightTheme1
                      : Colors.white70,
                  width: 1.5,
                ),
              ),
              child: widget.isSelected
                  ? Center(
                      child: Text(
                        '${widget.selectedIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
