import 'package:material_ui/material_ui.dart';

import 'generated/l10n.dart';

enum ConfirmAction { reject, accept }

/// Present an irreversible-action warning with accept and reject choices.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog(
      {super.key,
      this.title,
      this.content,
      this.onConfirm,
      this.displayMsg,
      this.okBtnText = "Accept",
      this.noBtnText = "Reject"});

  final String? title;
  final String? content;
  final Function? onConfirm;
  final String? displayMsg;
  final String okBtnText;
  final String noBtnText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.current.areYouSure),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        displayMsg == null ? const SizedBox() : Text(displayMsg!),
        Text(S.current.thisActionCannotBeUndone),
      ]),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.cancel),
          onPressed: () => Navigator.of(context).pop(ConfirmAction.reject),
          label: Text(noBtnText),
        ),
        TextButton.icon(
          icon: const Icon(Icons.done),
          onPressed: () => Navigator.of(context).pop(ConfirmAction.accept),
          label: Text(okBtnText),
        ),
      ],
    );
  }
}

/// Shows confirmation and treats dismissal of the dialog as rejection.
Future<ConfirmAction> confirmDialog(BuildContext context, String? displayMsg,
        {String okBtnText = "Accept", String noBtnText = "Reject"}) =>
    showDialog<ConfirmAction>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => ConfirmDialog(
        displayMsg: displayMsg,
        okBtnText: okBtnText,
        noBtnText: noBtnText,
      ),
    ).then((value) => value ?? ConfirmAction.reject);
