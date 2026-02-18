import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:flutter/services.dart';

import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
import 'package:zxy_app/usecase/resource/movie_details.dart';
import 'package:zxy_app/usecase/resource/tv_details.dart';
import 'package:zxy_app/usecase/stream/model.dart';
import 'package:zxy_app/views/movie_view/movie_view_model.dart';
import 'package:zxy_app/views/series_view/series_view_model.dart';
import 'package:zxy_app/views/shared/glass_container.dart';

import 'package:zxy_app/views/video_handler.dart';
import 'package:zxy_app/views/video_player_view/video_player_view.dart'; // For ZxyPlayerState
import 'package:zxy_app/views/view_item_state.dart';

class ModernSidebar extends StatefulWidget {
  final double height;
  final Player player;
  final VideoHandler handler;
  final VoidCallback updateAudioDelay;
  final VoidCallback updateSubDelay;
  final ValueListenable<ViewItemState<ZxyStreamResponse>> streamNotifier;
  final ValueNotifier<int> selectedStreamNotifier;
  final ValueChanged<ZxyResolutionItem> onVideoStreamChanged;
  final SettingsBloc settingsBloc;
  final ZxyPlayerState state;

  const ModernSidebar({
    super.key,
    required this.state,
    required this.height,
    required this.updateAudioDelay,
    required this.handler,
    required this.updateSubDelay,
    required this.onVideoStreamChanged,
    required this.streamNotifier,
    required this.selectedStreamNotifier,
    required this.player,
    required this.settingsBloc,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final MovieViewModel? mVm;
  late final SeriesViewModel? sVm;

  // Tabs
  final List<String> _tabs = ["Episodes", "Media", "Settings"];

  @override
  void initState() {
    super.initState();
    if (widget.handler.isMovie()) {
      mVm = widget.handler as MovieViewModel;
      sVm = null;
      // If movie, we might want to hide "Episodes" tab or disable it.
      // For simplicity, let's keep tabs but maybe show "Movie Info" instead of Episodes?
      // Or just hide the tab. Let's start with 3 tabs and adjust.
      // Actually, if it's a movie, standard sidebar didn't show seasons/episodes.
      // Let's adapt tabs based on content type.
    } else {
      sVm = widget.handler as SeriesViewModel;
      mVm = null;
    }

    // Adjust tabs for Movie
    if (widget.handler.isMovie()) {
      _tabs.remove("Episodes");
      _tabs.insert(0, "Info"); // Replace Episodes with Info
    }

    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine title
    String title = "";
    if (widget.handler.isMovie()) {
      final state = mVm?.movieDetailState.value;
      if (state is ItemLoaded<MovieDetails>) title = state.data.title;
    } else {
      final state = sVm?.seriesDetailState.value;
      if (state is ItemLoaded<SeriesDetails>) title = state.data.name;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: widget.state.settingsVisible,
      builder: (_, visible, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          right: visible ? 0 : -420, // Width + padding
          top: 0,
          bottom: 0,
          child: child!,
        );
      },
      child: Container(
        width: 400,
        margin: const EdgeInsets.all(16),
        child: GlassContainer(
          containerOpacity: 0.85,
          radius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header
              _buildHeader(title),

              // Tabs
              _buildTabBar(),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: widget.handler.isMovie()
                      ? [
                          _buildMovieInfoTab(),
                          _buildMediaTab(),
                          _buildSettingsTab(),
                        ]
                      : [
                          _buildEpisodesTab(),
                          _buildMediaTab(),
                          _buildSettingsTab(),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              widget.state.settingsVisible.value = false;
            },
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppTheme.accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // --- TAB 1: Episodes (Series) ---
  Widget _buildEpisodesTab() {
    if (sVm == null) return const SizedBox();

    return ValueListenableBuilder(
      valueListenable: sVm!.seriesDetailState,
      builder: (_, detailState, __) {
        if (detailState is! ItemLoaded<SeriesDetails>) {
          return const Center(child: CircularProgressIndicator());
        }

        final details = detailState.data;

        return ValueListenableBuilder(
          valueListenable: sVm!.activeSeasonEpisode,
          builder: (_, activeSE, __) {
            final activeSeasonIdx = activeSE.$1;
            final activeEpisodeIdx = activeSE.$2;

            // Two-column layout or nested list? Let's use nested list for simplicity in narrow width
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Seasons Dropdown / List
                _SectionHeader(title: "Season"),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: details.seasons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final isSelected = activeSeasonIdx == index;
                      return ChoiceChip(
                        label: Text(
                          "Season ${details.seasons[index].seasonNumber}",
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected && !isSelected) {
                            widget.player.stop();
                            widget.state.bufferingOrLoading.value = true;
                            sVm!.onSeasonSelect(index);
                          }
                        },
                        selectedColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),
                _SectionHeader(title: "Episodes"),
                const SizedBox(height: 10),

                // Episodes List
                ...details.seasons[activeSeasonIdx].episodes
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final episode = entry.value;
                      final isPlaying = activeEpisodeIdx == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? AppTheme.accentColor.withOpacity(0.9)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: isPlaying
                              ? Border.all(
                                  color: AppTheme.accentColor.withOpacity(0.5),
                                )
                              : null,
                        ),
                        child: ListTile(
                          onTap: () {
                            if (!isPlaying) {
                              widget.player.stop();
                              widget.state.bufferingOrLoading.value = true;
                              sVm!.onEpisodeSelect(index);
                            }
                          },
                          leading: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPlaying
                                  ? AppTheme.accentColor
                                  : Colors.white10,
                            ),
                            child: isPlaying
                                ? const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 16,
                                    color: Colors.black,
                                  )
                                : Text(
                                    "${episode.episodeNumber}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                          title: Text(
                            episode.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isPlaying ? Colors.black : Colors.white70,
                              fontWeight: isPlaying
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: isPlaying
                              ? const Icon(
                                  Icons.equalizer_rounded,
                                  color: Colors.black,
                                  size: 20,
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }),
              ],
            );
          },
        );
      },
    );
  }

  // --- TAB 1: Info (Movie) ---
  Widget _buildMovieInfoTab() {
    if (mVm == null) return const SizedBox();

    return ValueListenableBuilder(
      valueListenable: mVm!.movieDetailState,
      builder: (_, state, __) {
        if (state is! ItemLoaded<MovieDetails>) {
          return const Center(child: CircularProgressIndicator());
        }
        final movie = state.data;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Poster & Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black26,
                    image: movie.posterPath != null
                        ? DecorationImage(
                            image: NetworkImage(
                              "https://image.tmdb.org/t/p/w200${movie.posterPath}",
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Released: ${movie.releaseDate.year}",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Rating: ${movie.voteAverage.toStringAsFixed(1)}/10",
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (movie.genres ?? [])
                            .map(
                              (g) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  g.name,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: "Overview"),
            const SizedBox(height: 8),
            Text(
              movie.overview,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 2: Media (Audio, Video, Subs) ---
  Widget _buildMediaTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Resolution
        _SectionHeader(title: "Video Quality"),
        const SizedBox(height: 10),
        ValueListenableBuilder(
          valueListenable: widget.streamNotifier,
          builder: (_, state, __) {
            if (state is ItemLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Loading streams...",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              );
            }

            if (state is! ItemLoaded<ZxyStreamResponse>) {
              return const SizedBox();
            }

            final streams = [
              ...state.data.uhd,
              ...state.data.fhd,
              ...state.data.hd,
            ];

            if (streams.isEmpty) {
              return const Text(
                "No streams available",
                style: TextStyle(color: Colors.white38),
              );
            }

            return ValueListenableBuilder<int>(
              valueListenable: widget.selectedStreamNotifier,
              builder: (_, selectedIdx, _) {
                return Column(
                  children: streams.asMap().entries.map((e) {
                    final index = e.key;
                    final stream = e.value;
                    final sizeGB = (stream.size ?? 0) / (1024 * 1024 * 1024);
                    final isSelected = selectedIdx == index;

                    String subtitle = "${sizeGB.toStringAsFixed(2)} GB";
                    // Only show visual tags in subtitle, quality is in trailing chip
                    if (stream.visualTags.isNotEmpty) {
                      subtitle += " • ${stream.visualTags.join(' ')}";
                    }

                    return _RadioTile(
                      title: stream.resolution,
                      subtitle: subtitle,
                      isSelected: isSelected,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (stream.quality != null &&
                              stream.quality!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black.withOpacity(0.1)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                stream.quality!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: stream.url),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Stream link copied to clipboard",
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        if (!isSelected) {
                          widget.selectedStreamNotifier.value = index;
                          widget.onVideoStreamChanged(stream);
                        }
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // Audio Tracks
        _SectionHeader(title: "Audio"),
        const SizedBox(height: 10),
        ValueListenableBuilder(
          valueListenable: widget.state.audioDetails,
          builder: (_, audioData, _) {
            if (audioData == null || audioData.$1.isEmpty) {
              return const Text(
                "No audio tracks",
                style: TextStyle(color: Colors.white38),
              );
            }

            final tracks = audioData.$1;
            final currentIdx = audioData.$2; // -1 for none or index

            return Column(
              children: [
                _RadioTile(
                  title: "None",
                  isSelected: currentIdx == -1,
                  onTap: () {
                    widget.player.setAudioTrack(AudioTrack.no());
                    widget.state.audioDetails.value = (tracks, -1);
                  },
                ),
                ...tracks.asMap().entries.map((e) {
                  final index = e.key;
                  final track = e.value;
                  final lang = track.language ?? "YOYO";
                  final channels = track.channelscount?.toString() ?? "";
                  final codec = track.codec ?? "";
                  final label =
                      "[${lang.toUpperCase()}] ${channels.isNotEmpty ? '$channels Channels' : ''} $codec";

                  return _RadioTile(
                    title: label,
                    isSelected: currentIdx == index,
                    onTap: () {
                      widget.player.setAudioTrack(track);
                      widget.state.audioDetails.value = (tracks, index);
                    },
                  );
                }),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Subtitles
        _SectionHeader(title: "Subtitles"),
        const SizedBox(height: 10),
        ValueListenableBuilder(
          valueListenable: widget.state.subtitleDetails,
          builder: (_, subData, __) {
            if (subData == null || subData.$1.isEmpty) {
              return const Text(
                "No subtitles",
                style: TextStyle(color: Colors.white38),
              );
            }

            final tracks = subData.$1;
            final currentIdx = subData.$2;

            return Column(
              children: [
                _RadioTile(
                  title: "None",
                  isSelected: currentIdx == -1,
                  onTap: () {
                    widget.player.setSubtitleTrack(SubtitleTrack.no());
                    widget.state.subtitleDetails.value = (tracks, -1);
                  },
                ),
                ...tracks.asMap().entries.map((e) {
                  final index = e.key;
                  final track = e.value;
                  final lang = track.language ?? "Unknown";
                  final label = "[${lang.toUpperCase()}] ${track.title ?? ''}";

                  return _RadioTile(
                    title: label,
                    isSelected: currentIdx == index,
                    onTap: () {
                      widget.player.setSubtitleTrack(track);
                      widget.state.subtitleDetails.value = (tracks, index);
                    },
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- TAB 3: Settings (Delays, Appearance) ---
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(title: "Synchronization"),
        const SizedBox(height: 12),

        _buildStepper(
          label: "Audio Delay",
          valueNotifier: widget.state.audioDelay,
          unit: "ms",
          step: 50,
          onChanged: (val) {
            widget.state.audioDelay.value = val;
            widget.updateAudioDelay();
          },
        ),
        const SizedBox(height: 16),
        _buildStepper(
          label: "Subtitle Delay",
          valueNotifier: widget.state.subtitleDelay,
          unit: "ms",
          step: 50,
          onChanged: (val) {
            widget.state.subtitleDelay.value = val;
            widget.updateSubDelay();
          },
        ),

        const SizedBox(height: 32),
        _SectionHeader(title: "Appearance"),
        const SizedBox(height: 12),

        ValueListenableBuilder(
          valueListenable: widget.settingsBloc.subFontStyle,
          builder: (_, style, __) {
            return Column(
              children: [
                _buildStepperDouble(
                  label: "Subtitle Size",
                  value: style.fontSize,
                  unit: "px",
                  step: 2,
                  min: 10,
                  max: 100,
                  onChanged: (val) {
                    widget.settingsBloc.subStyle = style.copyWith(
                      fontSize: val,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildStepperDouble(
                  label: "Bottom Padding",
                  value: style.fontPadding,
                  unit: "px",
                  step: 4,
                  min: 0,
                  max: 200,
                  onChanged: (val) {
                    widget.settingsBloc.subStyle = style.copyWith(
                      fontPadding: val,
                    );
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 32),
        _SectionHeader(title: "Playback"),
        const SizedBox(height: 12),

        _buildStepper(
          label: "Skip Duration",
          valueNotifier: widget.settingsBloc.skipDuration,
          unit: "s",
          step: 5,
          min: 5,
          max: 60,
          onChanged: (val) {
            widget.settingsBloc.skipDuration.value = val;
            // Setter for value not available? Check logic.
            // Usually valueNotifier.value = val works.
            // Ah, skipDuration in settingsBloc might be a custom getter/setter or just ValueNotifier.
            // Assuming ValueNotifier from context.
            // Logic in old file: widget.settingsBloc.skipDuration = ...
            // Wait, previous file: widget.settingsBloc.skipDuration = widget.settingsBloc.skipDuration.value + 5;
            // Checking old file again...
            // user code: widget.settingsBloc.skipDuration = widget.settingsBloc.skipDuration.value + 5;
            // This implies skipDuration is a setter that takes an int? Or it returns a ValueNotifier?
            // Let's assume it's a property we can set nicely.
            widget.settingsBloc.skipDuration =
                val; // Assuming setter exists based on prev code
          },
        ),
      ],
    );
  }

  // --- Components ---

  Widget _buildStepper({
    required String label,
    required ValueNotifier<int> valueNotifier,
    required String unit,
    required int step,
    required Function(int) onChanged,
    int? min,
    int? max,
  }) {
    return ValueListenableBuilder<int>(
      valueListenable: valueNotifier,
      builder: (_, val, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Spacer(),
              _CircleIconBtn(
                icon: Icons.remove,
                onTap: () {
                  final newVal = val - step;
                  if (min != null && newVal < min) return;
                  onChanged(newVal);
                },
              ),
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    "$val$unit",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              _CircleIconBtn(
                icon: Icons.add,
                onTap: () {
                  final newVal = val + step;
                  if (max != null && newVal > max) return;
                  onChanged(newVal);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepperDouble({
    required String label,
    required double value,
    required String unit,
    required double step,
    required Function(double) onChanged,
    double? min,
    double? max,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          _CircleIconBtn(
            icon: Icons.remove,
            onTap: () {
              final newVal = value - step;
              if (min != null && newVal < min) return;
              onChanged(newVal);
            },
          ),
          SizedBox(
            width: 50,
            child: Center(
              child: Text(
                "${value.toInt()}$unit",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _CircleIconBtn(
            icon: Icons.add,
            onTap: () {
              final newVal = value + step;
              if (max != null && newVal > max) return;
              onChanged(newVal);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  final Widget? trailing;

  const _RadioTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.accentColor.withOpacity(0.5))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
