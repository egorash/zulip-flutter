import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';
import '../../../generated/l10n/zulip_localizations.dart';
import '../../values/constants.dart';
import '../../utils/page.dart';
import 'login_controller.dart';

class _LoginSequenceRoute extends MaterialWidgetRoute<void> {
  _LoginSequenceRoute({required super.page});
}

class AddAccountPage extends GetView<LoginController> {
  const AddAccountPage({super.key});

  static Route<void> buildRoute() {
    return _LoginSequenceRoute(page: const AddAccountPage());
  }

  static const _serverUrlHint = 'your-org.zulipchat.com';

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final error = controller.parseResult.value?.error;
    final errorText = error == null || error.shouldDeferFeedback()
        ? null
        : error.message(zulipLocalizations);

    return Scaffold(
      appBar: AppBar(
        title: Text(zulipLocalizations.loginAddAnAccountPageTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Obx(
            () => controller.inProgress.value
                ? const LinearProgressIndicator(minHeight: 4)
                : const SizedBox.shrink(),
          ),
        ),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: controller.serverUrlController,
                  onSubmitted: (_) => controller.onServerUrlSubmitted(context),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.go,
                  onEditingComplete: () {
                    controller.serverUrlController.clearComposing();
                  },
                  decoration: InputDecoration(
                    labelText: zulipLocalizations.loginServerUrlLabel,
                    errorText: errorText,
                    helperText: kLayoutPinningHelperText,
                    hintText: AddAccountPage._serverUrlHint,
                  ),
                ),
                const SizedBox(height: 8),
                Obx(
                  () => ElevatedButton(
                    onPressed: !controller.inProgress.value && errorText == null
                        ? () => controller.onServerUrlSubmitted(context)
                        : null,
                    child: Text(zulipLocalizations.dialogContinue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Stack(
          children: [
            // Positioned.fill(
            //   child: Assets.images.bgWinter.image(fit: BoxFit.cover),
            // ),
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.topCenter,
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset('assets/app-icons/zulip-combined.png'),
              ),
            ),
            SizedBox(
              height: Get.size.height,
              width: Get.size.width,
              child: AnimatedCrossFade(
                firstChild: SizedBox(
                  height: Get.size.height,
                  width: Get.size.width,
                  child: FlutterLogin(
                    messages: LoginMessages(
                      loginButton: 'Войти',
                      userHint: 'Почта',

                      passwordHint: 'Пароль',
                      flushbarTitleError: 'Ошибка',
                      flushbarTitleSuccess: 'Успешно',
                    ),
                    title: 'Вход в систему',
                    hideForgotPasswordButton: true,
                    hideProvidersTitle: true,

                    theme: LoginTheme(
                      buttonStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        shadows: [],
                      ),
                      buttonTheme: LoginButtonTheme(
                        elevation: 0,
                        backgroundColor: Colors.green,
                      ),
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),

                      cardTheme: CardTheme(elevation: 0),
                      textFieldStyle: TextStyle(fontWeight: FontWeight.w600),
                      pageColorLight: Colors.transparent,
                      pageColorDark: Colors.transparent,
                      cardTopPosition: 400,
                    ),

                    onLogin: (data) async {
                      await controller.submitCredentials(
                        username: data.name,
                        password: data.password,
                        context: context,
                        requireEmailFormatUsernames: true,
                      );
                      return '';
                    },
                    onRecoverPassword: (_) {
                      return null;
                    },
                    validateUserImmediately: false,
                    userType: LoginUserType.email,
                    userValidator: (value) =>
                        value?.isNotEmpty == true ? null : 'Введите почту',
                    passwordValidator: (value) =>
                        value?.isNotEmpty == true ? null : 'Введите пароль',
                  ),
                ),
                secondChild: SizedBox(
                  height: Get.size.height,
                  width: Get.size.width,
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                crossFadeState: controller.inProgress.value
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: Durations.medium2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _UsernamePasswordForm extends StatefulWidget {
//   const _UsernamePasswordForm({
//     required this.serverSettings,
//     required this.controller,
//   });

//   final GetServerSettingsResult serverSettings;
//   final LoginController controller;

//   @override
//   State<_UsernamePasswordForm> createState() => _UsernamePasswordFormState();
// }

// class _UsernamePasswordFormState extends State<_UsernamePasswordForm> {
//   final GlobalKey<FormFieldState<String>> _usernameKey = GlobalKey();
//   final GlobalKey<FormFieldState<String>> _passwordKey = GlobalKey();

//   void _submit() async {
//     final usernameFieldState = _usernameKey.currentState!;
//     final passwordFieldState = _passwordKey.currentState!;
//     final usernameValid = usernameFieldState.validate();
//     final passwordValid = passwordFieldState.validate();
//     if (!usernameValid || !passwordValid) {
//       return;
//     }
//     final String username = usernameFieldState.value!.trim();
//     final String password = passwordFieldState.value!;

//     await widget.controller.submitCredentials(
//       username: username,
//       password: password,
//       context: context,
//       requireEmailFormatUsernames:
//           widget.serverSettings.requireEmailFormatUsernames,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final requireEmailFormatUsernames =
//         widget.serverSettings.requireEmailFormatUsernames;

//     final usernameField = TextFormField(
//       key: _usernameKey,
//       autofillHints: [
//         if (!requireEmailFormatUsernames) AutofillHints.username,
//         AutofillHints.email,
//       ],
//       keyboardType: TextInputType.emailAddress,
//       autovalidateMode: AutovalidateMode.onUserInteraction,
//       validator: (value) {
//         if (value == null || value.trim().isEmpty) {
//           return requireEmailFormatUsernames
//               ? zulipLocalizations.loginErrorMissingEmail
//               : zulipLocalizations.loginErrorMissingUsername;
//         }
//         if (requireEmailFormatUsernames) {
//           // TODO(#106): validate is in the shape of an email
//         }
//         return null;
//       },
//       textInputAction: TextInputAction.next,
//       decoration: InputDecoration(
//         labelText: requireEmailFormatUsernames
//             ? zulipLocalizations.loginEmailLabel
//             : zulipLocalizations.loginUsernameLabel,
//         helperText: kLayoutPinningHelperText,
//       ),
//     );

//     final passwordField = Obx(
//       () => TextFormField(
//         key: _passwordKey,
//         autofillHints: const [AutofillHints.password],
//         obscureText: widget.controller.obscurePassword.value,
//         keyboardType: widget.controller.obscurePassword.value
//             ? null
//             : TextInputType.visiblePassword,
//         autovalidateMode: AutovalidateMode.onUserInteraction,
//         validator: (value) {
//           if (value == null || value.isEmpty) {
//             return zulipLocalizations.loginErrorMissingPassword;
//           }
//           return null;
//         },
//         textInputAction: TextInputAction.go,
//         onFieldSubmitted: (value) => _submit(),
//         decoration: InputDecoration(
//           labelText: zulipLocalizations.loginPasswordLabel,
//           helperText: kLayoutPinningHelperText,
//           suffixIcon: Obx(
//             () => IconButton(
//               tooltip: zulipLocalizations.loginHidePassword,
//               onPressed: widget.controller.togglePasswordVisibility,
//               icon: const Icon(Icons.visibility),
//               isSelected: widget.controller.obscurePassword.value,
//               selectedIcon: const Icon(Icons.visibility_off),
//             ),
//           ),
//         ),
//       ),
//     );

//     return Form(
//       child: AutofillGroup(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             usernameField,
//             const SizedBox(height: 8),
//             passwordField,
//             const SizedBox(height: 8),
//             Obx(
//               () => ElevatedButton(
//                 onPressed: widget.controller.inProgress.value ? null : _submit,
//                 child: Text(zulipLocalizations.loginFormSubmitLabel),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AlternativeAuthDivider extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final zulipLocalizations = ZulipLocalizations.of(context);
//     final designVariables = DesignVariables.of(context);

//     final divider = Expanded(
//       child: Divider(color: designVariables.loginOrDivider, thickness: 2),
//     );

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Semantics(
//         excludeSemantics: true,
//         label: zulipLocalizations.loginMethodDividerSemanticLabel,
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             divider,
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 5),
//               child: Text(
//                 zulipLocalizations.loginMethodDivider,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: designVariables.loginOrDividerText,
//                   height: 1.5,
//                 ).merge(weightVariableTextStyle(context, wght: 600)),
//               ),
//             ),
//             divider,
//           ],
//         ),
//       ),
//     );
//   }
// }
