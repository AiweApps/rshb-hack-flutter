import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:winescan/core/helpers/format_extensions.dart';
import 'package:winescan/core/services/language_service.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/remote_image.dart';
import '../../home/domain/models/track.dart';
import '../application/bloc/track_detail_bloc.dart';
import '../application/bloc/track_detail_state.dart';

class TrackDetailPage extends StatelessWidget {
  const TrackDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.localization.trackDetails),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BaseBlocPresentationListener<TrackDetailBloc>(
          listener: (BuildContext context, event) {},
          child: BlocBuilder<TrackDetailBloc, TrackDetailState>(
            builder: (BuildContext context, state) {
              if (state.track == null) {
                return const SizedBox.shrink();
              }
              return state.screenStatus == ScreenStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTrackDetails(context, state.track!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTrackDetails(BuildContext context, Track track) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album cover
          Center(
            child: RemoteImage(
              url: track.album.coverMedium,
              width: AppSize.s250,
              height: AppSize.s250,
              borderRadius: AppRadius.r8,
              errorWidget: const _CoverPlaceholder(),
            ),
          ),
          const SizedBox(height: AppSize.s24),

          // Track title
          Text(track.title, style: context.ts.h4),
          const SizedBox(height: AppSize.s8),

          // Artist name
          Text(
            '${context.localization.artist}: ${track.artist.name}',
            style: context.ts.paragraphBold,
          ),
          const SizedBox(height: AppSize.s8),

          // Album title
          Text(
            '${context.localization.album}: ${track.album.title}',
            style: context.ts.paragraphBold,
          ),
          const SizedBox(height: AppSize.s16),

          // Duration
          if (track.duration != null)
            Text(
              '${context.localization.duration}: ${track.duration!.formattedDuration}',
              style: context.ts.paragraph,
            ),
          const SizedBox(height: AppSize.s8),

          // Explicit lyrics
          if (track.explicitLyrics == true)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppPadding.p8,
                vertical: AppPadding.p4,
              ),
              decoration: BoxDecoration(
                color: context.colors.red,
                borderRadius: BorderRadius.circular(AppRadius.r4),
              ),
              child: Text(
                context.localization.explicit,
                style: context.ts.paragraphTinyBold.copyWith(
                  color: context.colors.neutrals100,
                ),
              ),
            ),
          const SizedBox(height: AppSize.s24),

          // Preview button
          if (track.preview != null && track.preview!.isNotEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<TrackDetailBloc>().add(
                    PlayTrackPreview(previewUrl: track.preview!),
                  );
                },
                icon: const Icon(Icons.play_circle),
                label: Text(context.localization.playPreview),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shown while there is no cover art, or when loading one fails.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppSize.s250,
      width: AppSize.s250,
      child: Center(child: Icon(Icons.music_note, size: AppSize.s100)),
    );
  }
}
