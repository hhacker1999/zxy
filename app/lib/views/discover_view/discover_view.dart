import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/discover_view/discover_view_model.dart';

class DiscoverView extends StatefulWidget {
  final LibraryFilter? filter;
  const DiscoverView({super.key, this.filter});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  late final DiscoverViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = context.read<DiscoverViewModel>();
    if (widget.filter != null) {
      vm.onFilterUpdate(widget.filter!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
