import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_button/group_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/src/controller/controller.dart';
import 'package:talker_flutter/src/ui/talker_monitor/talker_monitor.dart';
import 'package:talker_flutter/src/ui/talker_settings/talker_settings.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'talker_actions/talker_actions.dart';
import 'theme/default_theme.dart';

class TalkerView extends StatefulWidget {
  const TalkerView({
    Key? key,
    required this.talker,
    required this.theme,
    required this.appBarTitle,
    required this.controller,
    this.itemsBuilder,
  }) : super(key: key);

  /// Talker implementation
  final Talker talker;

  /// Theme for customize [TalkerScreen]
  final TalkerScreenTheme theme;

  /// Screen [AppBar] title
  final String appBarTitle;

  /// Optional Builder to customize
  /// log items cards in list
  final TalkerDataBuilder? itemsBuilder;

  final TalkerScreenController controller;

  @override
  State<TalkerView> createState() => _TalkerViewState();
}

class _TalkerViewState extends State<TalkerView> {
  final _titilesController = GroupButtonController();

  @override
  Widget build(BuildContext context) {
    final talkerTheme = widget.theme;
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return TalkerBuilder(
          talker: widget.talker,
          builder: (context, data) {
            final filtredElements =
                data.where((e) => widget.controller.filter.filter(e)).toList();
            final titles = data.map((e) => e.title).toList();
            final unicTitles = titles.toSet().toList();
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: talkerTheme.backgroundColor,
                  elevation: 0,
                  pinned: true,
                  floating: true,
                  expandedHeight: 180,
                  collapsedHeight: 60,
                  toolbarHeight: 60,
                  actions: [
                    UnconstrainedBox(
                      child: _MonitorButton(
                        talker: widget.talker,
                        onPressed: () => _openTalkerMonitor(context),
                      ),
                    ),
                    UnconstrainedBox(
                      child: IconButton(
                        onPressed: () => _openTalkerSettings(
                          context,
                          talkerTheme,
                        ),
                        icon: const Icon(Icons.settings_rounded),
                      ),
                    ),
                    UnconstrainedBox(
                      child: IconButton(
                        onPressed: () => _showActionsBottomSheet(context),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  title: Text(widget.appBarTitle),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 50,
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                scrollDirection: Axis.horizontal,
                                children: [
                                  GroupButton(
                                    controller: _titilesController,
                                    isRadio: false,
                                    buttonBuilder: (selected, value, context) {
                                      final count = titles
                                          .where((e) => e == value)
                                          .length;
                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: selected
                                              ? theme.primaryColor
                                              : cardBackgroundColor,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$count',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$value',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onSelected: (_, i, selected) {
                                      _onToggleTitle(unicTitles[i], selected);
                                    },
                                    buttons: unicTitles,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            _SearchTextField(
                              controller: widget.controller,
                              talkerScreenTheme: talkerTheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final data = _getListItem(filtredElements, i);
                      if (widget.itemsBuilder != null) {
                        return widget.itemsBuilder!.call(context, data);
                      }
                      return TalkerDataCard(
                        data: data,
                        onTap: () => _copyTalkerDataItemText(data),
                        expanded: widget.controller.expandedLogs,
                      );
                    },
                    childCount: filtredElements.length,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onToggleTitle(String title, bool selected) {
    if (selected) {
      widget.controller.addFilterTitle(title);
    } else {
      widget.controller.removeFilterTitle(title);
    }
  }

  TalkerDataInterface _getListItem(
    List<TalkerDataInterface> filtredElements,
    int i,
  ) {
    final data = filtredElements[widget.controller.isLogOrderReversed
        ? filtredElements.length - 1 - i
        : i];
    return data;
  }

  void _openTalkerSettings(BuildContext context, TalkerScreenTheme theme) {
    final talker = ValueNotifier(widget.talker);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return TalkerSettingsBottomSheet(
          talkerScreenTheme: theme,
          talker: talker,
        );
      },
    );
  }

  void _openTalkerMonitor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TalkerMonitor(
          theme: widget.theme,
          talker: widget.talker,
        ),
      ),
    );
  }

  void _copyTalkerDataItemText(TalkerDataInterface data) {
    final text = data.generateTextMessage();
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(context, 'Log item is copied in clipboard');
  }

  void _showSnackBar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _showActionsBottomSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TalkerActionsBottomSheet(
          actions: [
            TalkerActionItem(
              onTap: widget.controller.toggleLogOrder,
              title: 'Reverse logs',
              icon: Icons.swap_vert,
            ),
            TalkerActionItem(
              onTap: () => _copyAllLogs(context),
              title: 'Copy all logs',
              icon: Icons.copy,
            ),
            TalkerActionItem(
              onTap: _toggleLogsExpanded,
              title: widget.controller.expandedLogs
                  ? 'Collapse logs'
                  : 'Expand logs',
              icon: widget.controller.expandedLogs
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            TalkerActionItem(
              onTap: _cleanHistory,
              title: 'Clean history',
              icon: Icons.delete_outline,
            ),
            TalkerActionItem(
              onTap: _shareLogsInFile,
              title: 'Share logs file',
              icon: Icons.ios_share_outlined,
            ),
          ],
          talkerScreenTheme: widget.theme,
        );
      },
    );
  }

  Future<void> _shareLogsInFile() async {
    final path = await widget.controller.saveLogsInFile(
      widget.talker.history.text,
    );
    // ignore: deprecated_member_use
    await Share.shareFilesWithResult([path]);
  }

  void _cleanHistory() {
    widget.talker.cleanHistory();
    widget.controller.update();
  }

  void _toggleLogsExpanded() {
    widget.controller.expandedLogs = widget.controller.expandedLogs;
  }

  void _copyAllLogs(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.talker.history.text));
    _showSnackBar(context, 'All logs copied in buffer');
  }
}

class _SearchTextField extends StatelessWidget {
  const _SearchTextField({
    Key? key,
    required this.talkerScreenTheme,
    required this.controller,
  }) : super(key: key);

  final TalkerScreenTheme talkerScreenTheme;
  final TalkerScreenController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        style: theme.textTheme.bodyLarge!.copyWith(
          color: talkerScreenTheme.textColor,
          fontSize: 14,
        ),
        onChanged: controller.updateFilterSearchQuery,
        decoration: InputDecoration(
          fillColor: theme.cardColor,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: talkerScreenTheme.textColor),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: talkerScreenTheme.textColor),
            borderRadius: BorderRadius.circular(10),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: talkerScreenTheme.textColor,
          ),
          hintText: 'Search...',
          hintStyle: theme.textTheme.bodyLarge!.copyWith(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _MonitorButton extends StatelessWidget {
  const _MonitorButton({
    Key? key,
    required this.talker,
    required this.onPressed,
  }) : super(key: key);

  final Talker talker;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TalkerBuilder(
      talker: talker,
      builder: (context, data) {
        final haveErrors = data
            .where((e) => e is TalkerError || e is TalkerException)
            .isNotEmpty;
        return Stack(
          children: [
            Center(
              child: IconButton(
                onPressed: onPressed,
                icon: const Icon(Icons.monitor_heart_outlined),
              ),
            ),
            if (haveErrors)
              Positioned(
                right: 6,
                top: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  height: 7,
                  width: 7,
                ),
              ),
          ],
        );
      },
    );
  }
}
