import 'dart:ui';

import 'package:flutter/material.dart';

class MediaAlbumsSheet extends StatelessWidget {
  final int initial;
  final List<String> folders;

  const MediaAlbumsSheet({
    super.key,
    required this.initial,
    required this.folders,
  });

  static Future<int> show(
    BuildContext context, {
    int initial = 0,
    required List<String> folders,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaAlbumsSheet(initial: initial, folders: folders);
      },
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.35),
    ).onError((e, _) => 0).then((value) => value is int ? value : initial);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 20, sigmaX: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        "Select album",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 24,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                  const SizedBox(height: 22),
                  ...List.generate(folders.length, (index) {
                    final e = folders.elementAt(index);
                    final selected = e == folders.elementAtOrNull(initial);
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.vertical(
                            top: folders.first == e
                                ? const Radius.circular(16)
                                : Radius.zero,
                            bottom: folders.last == e
                                ? const Radius.circular(16)
                                : Radius.zero,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e,
                              style: TextStyle(
                                color: selected ? Colors.black : Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check,
                                size: 24,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
