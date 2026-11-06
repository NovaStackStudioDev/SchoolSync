import 'package:flutter/material.dart';

import '../data/school_database.dart';
import '../theme/app_colors.dart';

class LiveData<T> extends StatefulWidget {
  const LiveData({super.key, required this.load, required this.builder});
  final Future<T> Function() load;
  final Widget Function(BuildContext, T) builder;

  @override
  State<LiveData<T>> createState() => _LiveDataState<T>();
}

class _LiveDataState<T> extends State<LiveData<T>> {
  late Future<T> _future;
  @override
  void initState() {
    super.initState();
    _future = Future.sync(widget.load);
    SchoolDatabase.changes.addListener(_reload);
  }

  void _reload() {
    final next = Future.sync(widget.load);
    setState(() {
      _future = next;
    });
  }

  @override
  void dispose() {
    SchoolDatabase.changes.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 44,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load school data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: widget.builder(context, snapshot.data as T),
      );
    },
  );
}

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (context.mounted && success != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
      );
    }
    return false;
  }
}

class NoRecords extends StatelessWidget {
  const NoRecords({
    super.key,
    this.message = 'No records yet.',
    this.icon = Icons.inbox_outlined,
  });
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
    child: Column(
      children: [
        Icon(icon, size: 42, color: AppColors.greenDark),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
