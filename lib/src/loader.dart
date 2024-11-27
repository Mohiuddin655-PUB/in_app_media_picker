import 'package:flutter/material.dart';

import 'provider.dart';

class MediaLoader extends StatefulWidget {
  final MediaResponse initial;
  final Widget Function(BuildContext, MediaResponse value) builder;

  const MediaLoader({
    super.key,
    required this.initial,
    required this.builder,
  });

  @override
  State<MediaLoader> createState() => _MediaLoaderState();
}

class _MediaLoaderState extends State<MediaLoader> {
  late MediaResponse _response = widget.initial;

  Future<Media> callback() async {
    final data = _response.data;
    final thumbnail = await data.entity.thumbnailData;
    final file = await data.entity.file;
    final bytes = await file?.readAsBytes();
    return data.copy(thumbnail: thumbnail, file: file, bytes: bytes);
  }

  void _fetch() {
    if (_response.isConverted) return;
    final data = MediaProvider.i.pick(_response.data.id);
    if (data != null) {
      setState(() => _response = _response.update(data));
      return;
    }
    try {
      setState(() => _response = _response.asLoading(true));
      MediaProvider.i.load(_response.data.id, callback).then((value) {
        if (value.isConverted) {
          _response = _response.update(value);
        } else {
          _response = _response.asError("Data not converted!");
        }

        if (context.mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      setState(() => _response = _response.asError(e));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant MediaLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _response = widget.initial;
    _fetch();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _response);
}

class MediaResponse {
  final bool loading;
  final String error;
  final Media data;

  bool get isConverted => data.isConverted;

  bool get isValid => error.isEmpty && data.isValid;

  bool get isValidBytes => data.isValidBytes;

  bool get isValidFile => data.isValidFile;

  const MediaResponse({
    this.loading = false,
    this.error = '',
    required this.data,
  });

  MediaResponse asLoading(bool loading) {
    return MediaResponse(data: data, loading: loading);
  }

  MediaResponse asError(Object? error) {
    return MediaResponse(data: data, error: error.toString());
  }

  MediaResponse update(Media value) {
    return MediaResponse(data: value);
  }
}
