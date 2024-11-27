import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

const kIsoIgnorablePaths = [
  "Long Exposure",
  "Spatial",
  "Panoramas",
  "Time lapse",
  "Slo-mo",
  "Cinematic",
  "Bursts",
  "Animated",
  "RAW",
  "Hidden",
  // "Favourites",
  // "Favorites",
  // "Portrait",
  "Time-lapse",
  "Time-lapse",
  // "Videos",
  // "Selfies",
  "Live Photos",
  "Recents",
];

const kAndroidIgnorablePaths = ["Recent"];

class _Key {
  final AssetEntity entity;

  const _Key(this.entity);

  DateTime get createDateTime => entity.createDateTime;

  int get year => createDateTime.year;

  int get month => createDateTime.month;

  String get key => "$year-$month";

  @override
  int get hashCode => key.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is _Key) {
      return other.key == key;
    }
    return hashCode == other.hashCode;
  }
}

class Media {
  final AssetEntity entity;
  final File? file;
  final Uint8List? bytes;
  final Uint8List? thumbnail;

  Uint8List? get verifiedBytes {
    if (bytes != null && bytes!.isNotEmpty) return bytes;
    if (thumbnail != null && thumbnail!.isNotEmpty) return thumbnail;
    return null;
  }

  bool get isConverted => bytes != null || file != null;

  bool get isValid => isValidBytes || isValidFile;

  bool get isValidBytes => verifiedBytes != null;

  bool get isValidFile => file != null;

  bool get isAudio => type == AssetType.audio;

  bool get isImage => type == AssetType.image;

  bool get isVideo => type == AssetType.video;

  String get id => entity.id;

  AssetType get type => entity.type;

  DateTime get createDateTime => entity.createDateTime;

  DateTime get modifiedDateTime => entity.modifiedDateTime;

  Future<File?> get data => entity.file;

  Future<Uint8List> get originBytes {
    return entity.originBytes.then((value) => value ?? Uint8List(0));
  }

  const Media({
    required this.entity,
    this.file,
    this.bytes,
    this.thumbnail,
  });

  Media copy({
    AssetEntity? entity,
    File? file,
    Uint8List? bytes,
    Uint8List? thumbnail,
  }) {
    return Media(
      entity: entity ?? this.entity,
      file: file ?? this.file,
      bytes: bytes ?? this.bytes,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Media && other.id == id;
  }
}

class MediaFolder {
  final String id;
  final String? name;
  final int albumType;
  final DateTime? createDateTime;
  final DateTime? lastModified;
  final RequestType type;
  final bool isAll;
  final PMFilter filterOption;
  final AlbumType? albumTypeEx;
  final Iterable<Media> contents;

  MediaFolder({
    required this.id,
    this.name,
    this.albumType = 1,
    this.createDateTime,
    this.lastModified,
    this.type = RequestType.common,
    this.isAll = false,
    this.albumTypeEx,
    this.contents = const [],
    PMFilter? filterOption,
  }) : filterOption = filterOption ??= FilterOptionGroup();

  factory MediaFolder.all(Iterable<Media> contents) {
    return MediaFolder(id: "isAll", name: "Recent", contents: contents);
  }

  factory MediaFolder.empty() => MediaFolder(id: '');

  MediaFolder copy({
    String? id,
    String? name,
    int? albumType,
    DateTime? createDateTime,
    DateTime? lastModified,
    RequestType? type,
    bool? isAll,
    PMFilter? filterOption,
    AlbumType? albumTypeEx,
    Iterable<Media>? contents,
  }) {
    return MediaFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      albumType: albumType ?? this.albumType,
      createDateTime: createDateTime ?? this.createDateTime,
      lastModified: lastModified ?? this.lastModified,
      type: type ?? this.type,
      isAll: isAll ?? this.isAll,
      filterOption: filterOption ?? this.filterOption,
      albumTypeEx: albumTypeEx ?? this.albumTypeEx,
      contents: contents ?? this.contents,
    );
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      albumType.hashCode ^
      createDateTime.hashCode ^
      lastModified.hashCode ^
      type.hashCode ^
      isAll.hashCode ^
      filterOption.hashCode ^
      albumTypeEx.hashCode ^
      contents.hashCode;

  @override
  bool operator ==(Object other) {
    return other is MediaFolder &&
        other.id == id &&
        other.name == name &&
        other.albumType == albumType &&
        other.createDateTime == createDateTime &&
        other.lastModified == lastModified &&
        other.type == type &&
        other.isAll == isAll &&
        other.filterOption == filterOption &&
        other.albumTypeEx == albumTypeEx &&
        other.contents == contents;
  }
}

class YearlyFolder {
  final int year;
  final Iterable<MonthlyFolder> contents;

  const YearlyFolder({
    required this.year,
    this.contents = const [],
  });
}

class MonthlyFolder {
  final int year;
  final int month;
  final Iterable<DailyFolder> contents;

  const MonthlyFolder({
    required this.year,
    required this.month,
    this.contents = const [],
  });
}

class DailyFolder {
  final int year;
  final int month;
  final int day;
  final Iterable<Media> contents;

  const DailyFolder({
    required this.year,
    required this.month,
    required this.day,
    this.contents = const [],
  });
}

class MediaProvider {
  MediaProvider._();

  final Map<String, Media> _keeper = {};

  static MediaProvider? _i;

  static MediaProvider get i => _i ??= MediaProvider._();

  static Future<bool> get isPermissionChecked {
    return permission.then((value) => value.status.isGranted);
  }

  static Future<Permission> get permission async {
    Permission whichPermission;
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt <= 32) {
        whichPermission = Permission.storage;
      } else {
        whichPermission = Permission.photos;
      }
    } else {
      whichPermission = Permission.photos;
    }
    return whichPermission;
  }

  static Future<void> get openSettings => PhotoManager.openSetting();

  static Future<bool> get requestPermissionExtend async {
    var x = await PhotoManager.requestPermissionExtend();
    if (!x.hasAccess) {
      await PhotoManager.openSetting();
      x = await PhotoManager.requestPermissionExtend();
    }
    if (x.hasAccess) return true;
    return false;
  }

  static Future<T> _on<T>(Future<T> Function(bool permission) executor) {
    return permission.then((value) => value.isGranted.then(executor));
  }

  static Future<Iterable<AssetPathEntity>> directories({
    bool hasAll = true,
    bool onlyAll = false,
    PMFilter? filterOption,
    PMPathFilter pathFilterOption = const PMPathFilter(),
    List<String> iosIgnores = const [],
    List<String> androidIgnores = const [],
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      return PhotoManager.getAssetPathList(
        hasAll: hasAll,
        onlyAll: onlyAll,
        type: RequestType.fromTypes(types),
        filterOption: filterOption ??
            FilterOptionGroup(
              containsPathModified: true,
              orders: [
                const OrderOption(type: OrderOptionType.createDate, asc: false),
              ],
            ),
        pathFilterOption: pathFilterOption,
      ).then((value) {
        if (kIsWeb) return value;
        List<String> ignores = [
          if (Platform.isAndroid) ...androidIgnores,
          if (Platform.isIOS || Platform.isMacOS) ...iosIgnores,
        ];
        if (ignores.isEmpty) return value;
        final x = ignores.map((e) => e.toLowerCase());
        return value.where((e) => !x.contains(e.name.toLowerCase()));
      });
    });
  }

  static Future<Iterable<AssetEntity>> entities({
    int start = 0,
    int end = 1000,
    int albumType = 1,
    String? directoryId,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      if (directoryId != null && directoryId.isNotEmpty) {
        return AssetPathEntity.fromId(
          directoryId,
          albumType: albumType,
          type: RequestType.fromTypes(types),
          filterOption: filterOption,
        ).then((value) => value.getAssetListRange(start: start, end: end));
      }
      return PhotoManager.getAssetListRange(
        start: start,
        end: end,
        type: RequestType.fromTypes(types),
        filterOption: filterOption,
      );
    });
  }

  static Future<int> count({
    PMFilter? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) async {
    return _on((permission) {
      if (!permission) return Future.value(0);
      return PhotoManager.getAssetCount(
        filterOption: filterOption,
        type: RequestType.fromTypes(types),
      );
    });
  }

  static Future<Iterable<MediaFolder>> folders({
    int albumType = 1,
    int start = 0,
    int end = 1000,
    bool hasAll = true,
    bool onlyAll = false,
    PMFilter? filterOption,
    FilterOptionGroup? filterOptionGroup,
    PMPathFilter pathFilterOption = const PMPathFilter(),
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
    List<String> iosIgnores = const [],
    List<String> androidIgnores = const [],
  }) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      return directories(
        hasAll: hasAll,
        onlyAll: onlyAll,
        filterOption: filterOption,
        pathFilterOption: pathFilterOption,
        iosIgnores: iosIgnores,
        androidIgnores: androidIgnores,
        types: types,
      ).then((value) {
        return Future.wait(value.map((e) {
          return entities(
            start: start,
            end: end,
            albumType: albumType,
            directoryId: e.id,
            types: types,
            filterOption: filterOptionGroup,
          ).then((x) {
            return MediaFolder(
              albumType: e.albumType,
              albumTypeEx: e.albumTypeEx,
              filterOption: e.filterOption,
              id: e.id,
              isAll: e.isAll,
              lastModified: e.lastModified,
              name: e.name,
              type: e.type,
              contents: x.map((e) => Media(entity: e)),
            );
          });
        })).then((value) => value.where((e) => e.contents.isNotEmpty));
      });
    });
  }

  static Future<Iterable<MediaFolder>> foldersAsMonthly({
    int start = 0,
    int end = 1000,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      return entities(
        start: start,
        end: end,
        filterOption: filterOption,
        types: types,
      ).then((value) {
        Map<_Key, Map<String, Media>> map = {};
        for (var item in value) {
          final key = _Key(item);
          map.putIfAbsent(key, () => {});
          map[key]![item.id] = Media(entity: item);
        }
        return map.entries.map((e) {
          return MediaFolder(
            id: e.key.key,
            createDateTime: e.key.createDateTime,
            contents: e.value.values,
          );
        });
      });
    });
  }

  static Future<Iterable<YearlyFolder>> foldersAsYearly({
    int start = 0,
    int end = 1000,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      return entities(
        start: start,
        end: end,
        filterOption: filterOption,
        types: types,
      ).then((value) {
        Map<int, Map<int, Map<int, Map<String, Media>>>> map = {};
        for (var item in value) {
          final day = item.createDateTime.day;
          final month = item.createDateTime.month;
          final year = item.createDateTime.year;

          final x = map[year];
          if (x == null) map[year] = {};

          final y = map[year]![month];
          if (y == null) map[year]![month] = {};

          final z = map[year]![month]![day];
          if (z == null) map[year]![month]![day] = {};

          map[year]![month]![day]![item.id] = Media(entity: item);
        }
        final x = map.entries.map(
          (year) => YearlyFolder(
            year: year.key,
            contents: year.value.entries.map(
              (month) => MonthlyFolder(
                year: year.key,
                month: month.key,
                contents: month.value.entries.map(
                  (day) => DailyFolder(
                    year: year.key,
                    month: month.key,
                    day: day.key,
                    contents: day.value.values,
                  ),
                ),
              ),
            ),
          ),
        );
        return x;
      });
    });
  }

  static Future<YearlyFolder> yearly(
    int year, {
    int start = 0,
    int end = 1000,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return foldersAsYearly(
      start: start,
      end: end,
      filterOption: filterOption,
      types: types,
    ).then((value) {
      final x = value.where((e) => e.year == year).firstOrNull;
      return x ?? YearlyFolder(year: year);
    });
  }

  static Future<MonthlyFolder> monthly(
    int year,
    int month, {
    int start = 0,
    int end = 1000,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return yearly(
      year,
      start: start,
      end: end,
      filterOption: filterOption,
      types: types,
    ).then((value) {
      final x = value.contents.where((e) => e.month == month).firstOrNull;
      return x ?? MonthlyFolder(year: year, month: month);
    });
  }

  static Future<DailyFolder> daily(
    int year,
    int month,
    int day, {
    int start = 0,
    int end = 1000,
    FilterOptionGroup? filterOption,
    List<RequestType> types = const [
      RequestType.image,
      RequestType.video,
    ],
  }) {
    return monthly(
      year,
      month,
      start: start,
      end: end,
      filterOption: filterOption,
      types: types,
    ).then((value) {
      final x = value.contents.where((e) => e.day == day).firstOrNull;
      return x ?? DailyFolder(year: year, month: month, day: day);
    });
  }

  static Future<String> delete(String id) {
    return deletes([id]).then((value) => value.firstOrNull ?? '');
  }

  static Future<List<String>> deletes(Iterable<String> ids) {
    return _on((permission) {
      if (!permission) return Future.value([]);
      return PhotoManager.editor.deleteWithIds(List.from(ids));
    });
  }

  Media? pick(String name) => _keeper[name];

  Media put(Media value) => _keeper[value.id] ??= value;

  Future<Media> load(String name, Future<Media> Function() callback) async {
    return _keeper[name] ??= await callback();
  }
}
