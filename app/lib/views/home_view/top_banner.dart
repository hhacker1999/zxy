import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/image_bloc.dart';
import 'package:zxy_app/usecase/resource/models.dart';
import 'package:zxy_app/views/filter_view/filter_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/series_view/series_view.dart';
import 'package:zxy_app/views/shared/zxy_button.dart';
import 'package:zxy_app/views/shared/zxy_image.dart';

class TopBanner extends StatefulWidget {
  final List<ZxyMedia> media;
  final ScrollController? parentScrollController;

  const TopBanner({
    super.key,
    required this.media,
    this.parentScrollController,
  });

  @override
  State<TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<TopBanner> {
  late final PageController _pageController;
  double _pageValue = 0.0;
  int _currentPage = 0;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageScroll);
    widget.parentScrollController?.addListener(_onParentScroll);
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      final old = _currentPage;
      setState(() {
        _pageValue = _pageController.page ?? 0.0;
        _currentPage = _pageValue.round();
      });
      if (old != _currentPage) {
        context.read<ImageBloc>().setGradColorFromImage(
          widget.media[_currentPage].backdropPath ?? "",
          context,
        );
      }
    }
  }

  void _onParentScroll() {
    if (widget.parentScrollController?.hasClients ?? false) {
      setState(() {
        _scrollOffset = widget.parentScrollController!.offset;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    widget.parentScrollController?.removeListener(_onParentScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    final isMobile = screenData.shouldRenderMobile;

    // Responsive aspect ratio: 16:9 for desktop, poster-friendly for mobile
    final aspectRatio = isMobile ? 0.75 : 16 / 9;

    // Calculate scroll-based scale (1.0 -> 0.94)
    final maxScrollForEffect = 200.0;
    final scrollProgress = (_scrollOffset / maxScrollForEffect).clamp(0.0, 1.0);
    final scrollScale = 1.0 - (scrollProgress * 0.06);

    return Padding(
      padding: EdgeInsets.only(
        left: !screenData.shouldRenderMobile ? AppTheme.spacingM : 0,
      ),
      child: Column(
        children: [
          Transform.scale(
            scale: scrollScale,
            alignment: Alignment.topCenter,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                children: [
                  // Page View with zoom effect on page change
                  ClipRRect(
                    borderRadius: BorderRadiusGeometry.only(
                      bottomRight: Radius.circular(AppTheme.radiusMedium),
                      bottomLeft: Radius.circular(AppTheme.radiusMedium),
                      topRight: Radius.circular(AppTheme.radiusMedium),
                      topLeft: Radius.circular(AppTheme.radiusMedium),
                    ),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.media.length,
                      itemBuilder: (context, index) {
                        // Calculate scale for each page (zoom effect on swipe)
                        final distance = (_pageValue - index).abs();
                        final scale = (1 - (distance * 0.1)).clamp(0.85, 1.0);
                        final opacity = (1 - (distance * 0.3)).clamp(0.6, 1.0);

                        return Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: _BannerSlide(
                              media: widget.media[index],
                              isMobile: isMobile,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Page Indicators
                  Positioned(
                    bottom: isMobile ? AppTheme.spacingM : AppTheme.spacingL,
                    left: 0,
                    right: 0,
                    child: _PageIndicators(
                      itemCount: widget.media.length,
                      currentPage: _currentPage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isMobile ? AppTheme.spacingM : AppTheme.spacingL),
        ],
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final ZxyMedia media;
  final bool isMobile;

  const _BannerSlide({required this.media, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final title = media.title ?? media.name ?? '';
    final year = _getYear();
    final genres = _getGenres();
    final overview = media.overview;

    // Get logo path - always prefer logo
    final logo = _getLogo(isMobile);
    // final posterBanner = _getPosterOrBanner(isMobile);
    final imagePath = isMobile
        ? (media.posterPath.isNotEmpty
              ? media.posterPath
              : media.backdropPath ?? "")
        : (media.backdropPath ?? media.posterPath);

    return ClipRRect(
      borderRadius: BorderRadiusGeometry.only(
        bottomRight: Radius.circular(AppTheme.radiusMedium),
        bottomLeft: Radius.circular(AppTheme.radiusMedium),
        topRight: Radius.circular(AppTheme.radiusMedium),
        topLeft: Radius.circular(AppTheme.radiusMedium),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ZxyImage(
            path: imagePath,
            size: isMobile ? 'w780' : 'original',
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // Gradient Overlay - stronger for mobile text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isMobile
                    ? [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.95),
                      ]
                    : [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Left-side gradient for desktop
          if (!isMobile)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),

          // Content Overlay
          Positioned(
            bottom: isMobile ? 50 : 80,
            left: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
            right: isMobile ? AppTheme.spacingM : AppTheme.spacingXL,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoZxyImage(
                  path: logo?.filePath ?? "",
                  alignment: Alignment.bottomLeft,
                  size: isMobile ? 'w300' : 'w500',
                  maxWidth: isMobile ? 200 : 400,
                  fit: BoxFit.contain,
                  replacement: Text(
                    title,
                    maxLines: isMobile ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: isMobile
                        ? Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: _textShadows,
                          )
                        : Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: _textShadows,
                          ),
                  ),
                ),
                SizedBox(
                  height: isMobile ? AppTheme.spacingXS : AppTheme.spacingM,
                ),

                // Meta Info Row (Year + Genres) - wrapped for mobile
                Wrap(
                  spacing: AppTheme.spacingXS,
                  runSpacing: AppTheme.spacingXS,
                  children: [
                    if (year.isNotEmpty)
                      _MetaChip(text: year, isMobile: isMobile),
                    ...genres
                        .take(isMobile ? 2 : 3)
                        .map(
                          (genre) => _MetaChip(text: genre, isMobile: isMobile),
                        ),
                  ],
                ),

                // Overview - desktop only
                if (!isMobile && overview.isNotEmpty) ...[
                  SizedBox(height: AppTheme.spacingM),
                  SizedBox(
                    width: 500,
                    child: Text(
                      overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                SizedBox(
                  height: isMobile ? AppTheme.spacingS : AppTheme.spacingM,
                ),

                // Play Button
                _PlayButton(
                  onTap: () => _navigateToDetail(context),
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getYear() {
    final date = media.releaseDate ?? media.firstAirDate;
    if (date != null) {
      return date.year.toString();
    }
    return '';
  }

  List<String> _getGenres() {
    final genreMap = media.type == ZxyMediaType.movie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;
    return media.genreIds
        .take(3)
        .map((id) => genreMap[id]?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Backdrop? _getLogo(bool mobile) {
    final logos = media.images?.logos;
    if (logos != null && logos.isNotEmpty) {
      // Prefer English logo
      final englishLogo = logos.firstWhere(
        (logo) => logo.iso6391 == 'en',
        orElse: () => logos.first,
      );
      return englishLogo;
    }
    return null;
  }

  Backdrop? _getPosterOrBanner(bool mobile) {
    final posters = media.images?.posters;
    final backDrops = media.images?.backdrops;
    if (mobile) {
      if (posters != null && posters.isNotEmpty) {
        // Prefer English logo
        final englishLogo = posters.firstWhere(
          (logo) => logo.iso6391 == null,
          orElse: () => posters.first,
        );
        return englishLogo;
      }
    } else {
      if (backDrops != null && backDrops.isNotEmpty) {
        // Prefer English logo
        final englishLogo = backDrops.firstWhere(
          (logo) => logo.iso6391 == "en",
          orElse: () => backDrops.first,
        );
        return englishLogo;
      }
    }
    return null;
  }

  void _navigateToDetail(BuildContext context) {
    if (media.type == ZxyMediaType.movie) {
      Navigator.pushNamed(context, AppRoutes.movieView, arguments: media.id);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.seriesView,
        arguments: SeriesViewData(id: media.id),
      );
    }
  }

  List<Shadow> get _textShadows => [
    Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 12),
    Shadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];
}

class _MetaChip extends StatelessWidget {
  final String text;
  final bool isMobile;

  const _MetaChip({required this.text, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingXS : AppTheme.spacingS,
        vertical: isMobile ? 2 : AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: AppTheme.roundedSmall,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style:
            (isMobile
                    ? Theme.of(context).textTheme.labelSmall
                    : Theme.of(context).textTheme.labelSmall)
                ?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 10 : 12,
                ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isMobile;

  const _PlayButton({required this.onTap, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return ZxyButton(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppTheme.spacingM : AppTheme.spacingL,
        vertical: isMobile ? AppTheme.spacingS : AppTheme.spacingM,
      ),
      radius: AppTheme.radiusXXLarge,
      onTap: onTap,
      color: AppTheme.accentColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            AppIcons.play,
            colorFilter: ColorFilter.mode(
              AppTheme.backgroundDark,
              BlendMode.srcIn,
            ),
            height: isMobile ? 14 : AppTheme.spacingL,
          ),
          SizedBox(width: isMobile ? AppTheme.spacingXS : AppTheme.spacingS),
          Text(
            'Play',
            style:
                (isMobile
                        ? Theme.of(context).textTheme.labelLarge
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      color: AppTheme.backgroundDark,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int itemCount;
  final int currentPage;

  const _PageIndicators({required this.itemCount, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: AppTheme.spacingXS / 2),
          height: 5,
          width: isActive ? 20 : 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? AppTheme.accentColor
                : Colors.white.withValues(alpha: 0.4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.accentColor.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
