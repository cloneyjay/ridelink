// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'RideLink';

  @override
  String get appTagline => 'Deliveries and rides you can trust';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get signInButton => 'Sign in';

  @override
  String get orDivider => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountPrompt => 'New to RideLink?';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get riderPrompt => 'Want to earn as a rider?';

  @override
  String get riderJoinLink => 'Join as a boda boda rider';

  @override
  String get signUpTitle => 'Create your account';

  @override
  String get signUpRiderNote =>
      'You\'ll set up your rider profile after confirming your email.';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get passwordHint => 'At least 15 characters';

  @override
  String get signUpButton => 'Create account';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get signInLink => 'Sign in';

  @override
  String get verifyTitle => 'Check your email';

  @override
  String verifySentTo(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String verifyNotConfirmed(String email) {
    return 'Your email $email isn\'t confirmed yet. Request a new code and enter it below.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verifyButton => 'Confirm';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get codeResent => 'We sent a new code.';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotBody =>
      'Enter your account email and we\'ll send you a code.';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get resetTitle => 'Choose a new password';

  @override
  String resetSentTo(String email) {
    return 'If an account exists for $email, we sent it a 6-digit code.';
  }

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get resetButton => 'Save new password';

  @override
  String get errorEmailInvalid => 'Enter a valid email address.';

  @override
  String get errorFirstNameRequired => 'Enter your first name.';

  @override
  String get errorLastNameRequired => 'Enter your last name.';

  @override
  String get errorNameTooLong => 'Use 50 characters or fewer.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorPasswordTooShort => 'Use at least 15 characters.';

  @override
  String get errorPasswordTooLong => 'Use 72 characters or fewer.';

  @override
  String get errorCodeFormat => 'Enter the 6-digit code.';

  @override
  String get errorWrongCredentials => 'Email or password is incorrect.';

  @override
  String get errorInvalidCode => 'That code is wrong or has expired.';

  @override
  String get errorTooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get errorServiceUnavailable =>
      'We couldn\'t complete that right now. Please try again shortly.';

  @override
  String get errorNetwork =>
      'No internet connection. Check your connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorGoogleFailed =>
      'Google sign-in didn\'t work. Please try again.';

  @override
  String get offlineTitle => 'You\'re offline';

  @override
  String get offlineBody =>
      'We couldn\'t reach RideLink. You\'re still signed in.';

  @override
  String get retryButton => 'Try again';

  @override
  String get riderOnboardingTitle => 'Rider setup';
}
