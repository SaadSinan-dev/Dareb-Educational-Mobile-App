import 'package:tamkeen2/features/gallery/presentation/screens/live_album_page.dart';
import 'package:tamkeen2/features/gallery/presentation/widgets/gallery_image.dart';
import 'package:tamkeen2/core/widgets/app_widgets.dart';
import 'package:tamkeen2/l10n/app_copy.g.dart';
import 'package:tamkeen2/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tamkeen2/core/state/resource_cubit.dart';
import 'package:tamkeen2/features/gallery/presentation/gallery_cubit.dart';
import 'package:tamkeen2/core/router/app_routes.dart';
import 'package:tamkeen2/core/theme/app_palette.dart';
import 'package:tamkeen2/features/account/domain/account_content.dart';
import 'package:tamkeen2/features/account/domain/account_content_repository.dart';
import 'package:tamkeen2/features/account/domain/account_models.dart';
import 'package:tamkeen2/features/account/presentation/account_common.dart';
import 'package:tamkeen2/features/account/presentation/account_preview_mode.dart';

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key, this.repository, this.previewMode});

  final AccountContentRepository? repository;
  final bool? previewMode;

  @override
  Widget build(BuildContext context) => PageLayout(
    title: AppCopy.galleryTitle,
    back: false,
    body: accountPreviewMode(context, previewMode)
        ? const _PreviewGallery()
        : _LiveGallery(repository: repository),
  );
}

Color _accountAccent(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? context.colors.secondary
    : accountBlue;

class _LiveGallery extends StatefulWidget {
  const _LiveGallery({this.repository});

  final AccountContentRepository? repository;

  @override
  State<_LiveGallery> createState() => _LiveGalleryState();
}

class _LiveGalleryState extends State<_LiveGallery> {
  late final GalleryCubit _cubit = GalleryCubit(
    widget.repository ?? context.read<AccountContentRepository>(),
  )..load();
  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<GalleryCubit, ResourceState<List<AccountGallerySummary>>>(
        bloc: _cubit,
        builder: (context, snapshot) => ListView(
          children: [
            if (snapshot.status == ResourceStatus.loading)
              const AccountGalleryGridSkeleton()
            else if (snapshot.status == ResourceStatus.failure)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    AppText(
                      snapshot.error ?? AppCopy.accountLoadingFailed,
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _cubit.load,
                      child: const AppText(AppCopy.retryAction),
                    ),
                  ],
                ),
              )
            else if (snapshot.data?.isEmpty ?? true)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: AppText(AppCopy.galleryEmpty)),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: constraints.maxWidth >= 600 ? 3 : 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 16,
                      childAspectRatio: .82,
                    ),
                    itemBuilder: (context, index) =>
                        _LiveAlbumCard(snapshot.data![index]),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _LiveAlbumCard extends StatelessWidget {
  const _LiveAlbumCard(this.album);

  final AccountGallerySummary album;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => context.push(AppRoutes.album(album.id.toString())),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: _accountAccent(context), width: 1.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: album.images.isEmpty
                ? Center(
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: _accountAccent(context),
                      size: 42,
                    ),
                  )
                : Stack(
                    children: [
                      Positioned(
                        left: 16,
                        right: 0,
                        top: 0,
                        bottom: 22,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GalleryImage(album.images.last),
                        ),
                      ),
                      Positioned(
                        left: 8,
                        right: 8,
                        top: 13,
                        bottom: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GalleryImage(album.images.first),
                        ),
                      ),
                    ],
                  ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(
              '${album.name} (${album.imageCount})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (album.images.isEmpty)
            AppText(
              AppCopy.galleryImagesUnavailable,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: context.colors.muted),
            ),
        ],
      ),
    ),
  );
}

class _PreviewGallery extends StatelessWidget {
  const _PreviewGallery();

  @override
  Widget build(BuildContext context) => AccountContent(
    loadingKind: AccountSkeletonKind.gallery,
    builder: (context, state) => LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 3 : 2;
        return CustomScrollView(
          slivers: [
            if (state.data.preview)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: AccountPreviewLabel(),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              sliver: SliverGrid.builder(
                itemCount: state.data.albums.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 16,
                  childAspectRatio: .82,
                ),
                itemBuilder: (context, index) =>
                    _AlbumCard(state.data.albums[index]),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard(this.album);
  final AccountAlbum album;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: () => context.push(AppRoutes.album(album.id)),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: _accountAccent(context), width: 1.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned(
                    left: 16,
                    right: 0,
                    top: 0,
                    bottom: 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: const AccountPhoto('assets/images/gallery_4.png'),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    top: 13,
                    bottom: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AccountPhoto(album.coverAsset),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: AppText(
              '${album.title} (${album.photoCount})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

class AlbumPage extends StatelessWidget {
  const AlbumPage({
    super.key,
    required this.albumId,
    this.previewMode,
    this.repository,
  });
  final String albumId;
  final bool? previewMode;
  final AccountContentRepository? repository;

  @override
  Widget build(BuildContext context) =>
      !accountPreviewMode(context, previewMode)
      ? LiveAlbumPage(albumId: albumId, repository: repository)
      : Scaffold(
          body: SafeArea(
            child: AccountContent(
              loadingKind: AccountSkeletonKind.gallery,
              builder: (context, state) {
                AccountAlbum? album;
                for (final candidate in state.data.albums) {
                  if (candidate.id == albumId) album = candidate;
                }
                if (album == null) {
                  return const Center(child: AppText(AppCopy.albumNotFound));
                }
                final selected = album;
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: const AccountTopBar(
                            title: AppCopy.galleryTitle,
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
                          sliver: SliverGrid.builder(
                            itemCount: selected.photoAssets.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
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
                                onTap: () => showDialog<void>(
                                  context: context,
                                  barrierColor: Colors.black.withValues(
                                    alpha: .67,
                                  ),
                                  builder: (dialogContext) => Dialog(
                                    insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    backgroundColor: Colors.transparent,
                                    elevation: 0,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: 1.1,
                                            child: AccountPhoto(
                                              selected.photoAssets[index],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: IconButton.filled(
                                            onPressed: () => Navigator.of(
                                              dialogContext,
                                            ).pop(),
                                            icon: const Icon(Icons.close),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black54,
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      AccountPhoto(selected.photoAssets[index]),
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
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
}
