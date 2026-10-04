import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/gallery/presentation/gallery_cubit.dart';
import 'package:tamkeen2/features/gallery/presentation/widgets/gallery_image.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';

class LiveAlbumPage extends StatefulWidget {
  const LiveAlbumPage({super.key, required this.albumId, this.repository});
  final String albumId;
  final AccountContentRepository? repository;

  @override
  State<LiveAlbumPage> createState() => _LiveAlbumPageState();
}

class _LiveAlbumPageState extends State<LiveAlbumPage> {
  late final GalleryCubit _cubit = GalleryCubit(
    widget.repository ?? context.read<AccountContentRepository>(),
  )..load();

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child:
          BlocBuilder<GalleryCubit, ResourceState<List<AccountGallerySummary>>>(
            bloc: _cubit,
            builder: (context, state) {
              final album = (state.data ?? const <AccountGallerySummary>[])
                  .where((album) => album.id.toString() == widget.albumId)
                  .firstOrNull;
              return ListView(
                children: [
                  const AccountTopBar(title: AppCopy.galleryTitle),
                  if (state.status == ResourceStatus.loading)
                    const AccountGalleryGridSkeleton()
                  else if (state.status == ResourceStatus.failure ||
                      album == null ||
                      album.images.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          AppText(
                            state.status == ResourceStatus.failure
                                ? state.error ?? AppCopy.accountLoadingFailed
                                : album == null
                                ? AppCopy.albumNotFound
                                : AppCopy.galleryImagesUnavailable,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: _cubit.load,
                            child: const AppText(AppCopy.retryAction),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: album.images.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth >= 600
                                    ? 3
                                    : 2,
                                mainAxisSpacing: 20,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.12,
                              ),
                          itemBuilder: (context, index) => Semantics(
                            label: AppCopy.format(
                              context.tr(AppCopy.viewImageLabel),
                              [index + 1],
                            ),
                            button: true,
                            child: InkWell(
                              key: ValueKey('album-photo-$index'),
                              onTap: () => showGalleryImage(
                                context,
                                album.images[index],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    GalleryImage(album.images[index]),
                                    const Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Icon(
                                        Icons.center_focus_weak,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
    ),
  );
}
