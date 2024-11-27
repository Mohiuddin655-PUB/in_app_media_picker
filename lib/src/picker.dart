import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'bottom_sheet.dart';
import 'loader.dart';
import 'provider.dart';

enum MediaType {
  audio,
  image,
  video;

  List<RequestType> get type {
    switch (this) {
      case MediaType.audio:
        return [RequestType.audio];
      case MediaType.image:
        return [RequestType.image];
      case MediaType.video:
        return [RequestType.video];
    }
  }
}

class MediaPicker extends StatefulWidget {
  final bool singleMode;
  final MediaType type;
  final Iterable<Media> selections;
  final int? maxSelections;

  const MediaPicker({
    super.key,
    this.singleMode = false,
    this.type = MediaType.image,
    this.selections = const [],
    this.maxSelections,
  });

  @override
  State<MediaPicker> createState() => _MediaPickerState();

  static Future<Media?> _pick(
    BuildContext context,
    MediaType type, {
    Iterable<Media> selections = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => MediaPicker(
        type: type,
        singleMode: true,
        selections: selections,
      ),
      isScrollControlled: true,
      useSafeArea: true,
    ).onError((e, _) => null).then((value) {
      return value is Media ? value : null;
    });
  }

  static Future<List<Media>?> _picks(
    BuildContext context,
    MediaType type, {
    Iterable<Media> selections = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => MediaPicker(
        type: type,
        singleMode: false,
        selections: selections,
      ),
      isScrollControlled: true,
      useSafeArea: true,
    ).onError((e, _) => null).then((value) {
      return value is List<Media> ? value : null;
    });
  }

  static Future<Media?> pickAudio(
    BuildContext context, {
    Iterable<Media> selections = const [],
  }) {
    return _pick(
      context,
      MediaType.audio,
      selections: selections,
    );
  }

  static Future<List<Media>?> pickAudios(
    BuildContext context, {
    Iterable<Media> selections = const [],
  }) {
    return _picks(
      context,
      MediaType.audio,
      selections: selections,
    );
  }

  static Future<Media?> pickImage(
    BuildContext context, {
    Iterable<Media> selections = const [],
  }) {
    return _pick(
      context,
      MediaType.image,
      selections: selections,
    );
  }

  static Future<List<Media>?> pickImages(
    BuildContext context, {
    Iterable<Media> selections = const [],
  }) {
    return _picks(
      context,
      MediaType.image,
      selections: selections,
    );
  }

// static Future<Media?> pickVideo(
//   BuildContext context, {
//   Iterable<Media> selections = const [],
// }) {
//   return _pick(
//     context,
//     MediaType.video,
//     selections: selections,
//   );
// }
//
// static Future<List<Media>?> pickVideos(
//   BuildContext context, {
//   Iterable<Media> selections = const [],
// }) {
//   return _picks(
//     context,
//     MediaType.video,
//     selections: selections,
//   );
// }
}

class _MediaPickerState extends State<MediaPicker> {
  late List<Media> selectedPhotos = widget.selections.toList();
  List<Media> mediaItems = [];
  Iterable<MediaFolder> albums = [];
  MediaFolder? selectedAlbum;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    if (await MediaProvider.requestPermissionExtend) {
      final albumList = await MediaProvider.folders(types: widget.type.type);
      if (albumList.isNotEmpty) {
        setState(() {
          albums = albumList;
          selectedAlbum = albumList.first;
        });
        _loadMedia(selectedAlbum!);
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _loadMedia(MediaFolder album) async {
    final media = await MediaProvider.entities(directoryId: album.id);
    setState(() {
      mediaItems = media.map((e) {
        return Media(entity: e);
      }).toList();
    });
  }

  void _onAlbumSelected(MediaFolder album) {
    setState(() {
      selectedAlbum = album;
      mediaItems.clear();
      // selectedPhotos.clear(); // Clear selection when switching albums
    });
    _loadMedia(album);
  }

  void _buildAlbumDropdown() {
    MediaAlbumsSheet.show(
      context,
      initial: albums.toList().indexWhere((e) => e == selectedAlbum),
      folders: albums.map((e) => e.name ?? "sss").toList(),
    ).then((value) {
      final album = albums.elementAtOrNull(value);
      if (album == null || album.id == selectedAlbum?.id) return;
      _onAlbumSelected(album);
    });
  }

  Widget _buildMediaGrid(ScrollController scrollController) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      controller: scrollController,
      itemCount: mediaItems.length,
      itemBuilder: (context, index) {
        final media = mediaItems[index];
        return MediaLoader(
          initial: MediaResponse(data: media),
          builder: (context, value) {
            if (value.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            Widget child = const SizedBox();

            if (value.isValidBytes) {
              child = Image.memory(
                value.data.verifiedBytes!,
                fit: BoxFit.cover,
              );
            }
            if (value.isValidFile) {
              child = Image.file(
                value.data.file!,
                fit: BoxFit.cover,
              );
            }

            return GestureDetector(
              onTap: () {
                if (widget.singleMode) {
                  return _onConfirmSelection(value.data);
                }
                _onMediaTapped(value.data);
              },
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  if (selectedPhotos.contains(media))
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onMediaTapped(Media media) {
    setState(() {
      if (selectedPhotos.contains(media)) {
        selectedPhotos.remove(media);
      } else if (selectedPhotos.length <
          (widget.maxSelections ?? mediaItems.length)) {
        selectedPhotos.add(media);
      }
    });
  }

  void _onConfirmSelection([Media? data]) {
    Navigator.pop(context, data ?? selectedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.6,
      maxChildSize: 0.94,
      builder: (BuildContext context, ScrollController scrollController) {
        return Scaffold(
          appBar: AppBar(
            leadingWidth: MediaQuery.of(context).size.width,
            leading: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedPhotos.length}/${widget.maxSelections ?? mediaItems.length}',
                  ),
                  GestureDetector(
                    onTap: () => _buildAlbumDropdown(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(
                        //   color: Colorx.black.withOpacity(0.25),
                        //   width: 0.5,
                        // ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 10),
                          Text(
                            selectedAlbum?.name ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _onConfirmSelection,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: selectedAlbum == null
              ? const Center(child: CircularProgressIndicator())
              : _buildMediaGrid(scrollController),
        );
      },
    );
  }
}
