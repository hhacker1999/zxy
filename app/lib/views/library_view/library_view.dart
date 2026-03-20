import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/library_view/library_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/media_grid.dart';

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  late final LibraryViewModel vm;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    vm = context.read<LibraryViewModel>();
    vm.initialise(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenData = Screen.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingM,
        right: AppTheme.spacingM,
        top: screenData.shouldRenderMobile
            ? MediaQuery.of(context).padding.top + AppTheme.spacingS
            : AppTheme.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library',
            style: GoogleFonts.poppins(
              fontSize: screenData.shouldRenderMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Expanded(
            child: MediaGrid(
              onScrollNearEnd: vm.loadMore,
              showType: true,
              scrollController: _scrollController,
              notifier: vm.viewState,
              initialText: 'Your library is empty',
            ),
          ),
        ],
      ),
    );
  }
}
