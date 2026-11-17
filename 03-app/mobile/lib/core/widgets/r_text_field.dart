import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

class RTextField extends StatelessWidget {
  const RTextField({
    super.key,
    this.label,
    this.controller,
    this.validator,
    this.obscure = false,
    this.keyboardType,
    this.helper,
  });

  final String? label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(RRadius.xl),
      borderSide: BorderSide(color: color, width: width),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: RSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: RType.label.copyWith(color: c.textPrimary)),
            const SizedBox(height: RSpace.s1_5),
          ],
          TextFormField(
            controller: controller,
            validator: validator,
            obscureText: obscure,
            keyboardType: keyboardType,
            textAlign: TextAlign.start,
            style: RType.body.copyWith(color: c.textPrimary),
            cursorColor: c.primary,
            decoration: InputDecoration(
              // An external label keeps the board's label/control spacing intact.
              hintText: label,
              helperText: helper,
              helperMaxLines: null,
              errorMaxLines: null,
              helperStyle: RType.caption.copyWith(color: c.textSecondary),
              errorStyle: RType.caption.copyWith(color: c.feedbackErrorText),
              hintStyle: RType.body.copyWith(color: c.textTertiary),
              filled: true,
              fillColor: c.surface,
              isDense: true,
              constraints: const BoxConstraints(minHeight: RSpace.s14),
              contentPadding: EdgeInsetsDirectional.symmetric(
                horizontal: RSpace.s4,
                vertical:
                    (RSpace.s14 -
                        RType.body.fontSize! * RType.body.height! -
                        RBorderWidth.thin * 2) /
                    2,
              ),
              enabledBorder: border(c.borderStrong, RBorderWidth.thin),
              focusedBorder: border(c.borderFocus, RBorderWidth.medium),
              errorBorder: border(c.borderError, RBorderWidth.medium),
              focusedErrorBorder: border(c.borderError, RBorderWidth.medium),
              disabledBorder: border(c.borderDisabled, RBorderWidth.thin),
            ),
          ),
        ],
      ),
    );
  }
}
