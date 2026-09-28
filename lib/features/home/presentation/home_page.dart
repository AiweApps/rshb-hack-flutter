import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:winescan/core/helpers/format_extensions.dart';
import 'package:winescan/core/services/language_service.dart';

import '../../../core/application/bloc/base_bloc_presentation_listener.dart';
import '../../../core/application/bloc/screen_status.dart';
import '../../../core/constants/app_style_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/remote_image.dart';
import '../../../shared/helpers/service_locator.dart';
import '../application/bloc/home_bloc.dart';
import '../application/bloc/home_state.dart';
import '../domain/models/track.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.localization.home)),
      body: SafeArea(
        child: BaseBlocPresentationListener<HomePageBloc>(
          listener: (BuildContext context, event) {},
          child: BlocBuilder<HomePageBloc, HomeState>(
            builder: (BuildContext context, state) {
              // Update controller text if state changes from elsewhere
              // but don't update cursor position
              if (_searchController.text != state.searchQuery) {
                _searchController.value = TextEditingValue(
                  text: state.searchQuery,
                  selection: _searchController.selection,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSearchBar(context, state),
                  const SizedBox(height: 16),
                  Expanded(
                    child: state.screenStatus == ScreenStatus.loading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSearchResults(state.searchResults),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeState state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: context.localization.searchForTracks,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              suffixIcon: IconButton(
                onPressed: state.searchQuery.trim().isEmpty
                    ? null
                    : () {
                        context.read<HomePageBloc>().add(
                          Search(query: state.searchQuery),
                        );
                      },
                icon: const Icon(Icons.search),
              ),
            ),
            onChanged: (value) {
              context.read<HomePageBloc>().add(UpdateSearchQuery(query: value));
            },
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<HomePageBloc>().add(Search(query: value));
              }
            },
            controller: _searchController,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Track> tracks) {
    if (tracks.isEmpty) {
      return Center(child: Text(context.localization.noTracksFound));
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: RemoteImage(
            url: track.album.coverSmall,
            width: AppSize.s56,
            height: AppSize.s56,
            borderRadius: AppRadius.r8,
            errorWidget: const _TrackCoverPlaceholder(),
          ),
          title: Text(track.title),
          subtitle: Text(track.artist.name),
          trailing: Text((track.duration ?? 0).formattedDuration),
          onTap: () {
            sl<AppRouter>().navigateToTrackDetails(track);
          },
        );
      },
    );
  }
}

/// Shown in the results list when a track has no usable cover.
class _TrackCoverPlaceholder extends StatelessWidget {
  const _TrackCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.s56,
      height: AppSize.s56,
      child: ColoredBox(
        color: context.colors.neutrals300,
        child: const Center(child: Icon(Icons.music_note, size: AppSize.s24)),
      ),
    );
  }
}
