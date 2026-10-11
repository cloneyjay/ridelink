import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// Product name.
  ///
  /// In en, this message translates to:
  /// **'RideLink'**
  String get appName;

  /// Short line under the logo on the sign-in screen. Launch services are deliveries and rides only (no errands).
  ///
  /// In en, this message translates to:
  /// **'Deliveries and rides you can trust'**
  String get appTagline;

  /// Heading of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Accessibility label for the eye icon that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Accessibility label for the eye icon that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Link on the sign-in screen to reset a password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// Primary button on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// Divider between email sign-in and Google sign-in.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// Google sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Text before the create-account link.
  ///
  /// In en, this message translates to:
  /// **'New to RideLink?'**
  String get noAccountPrompt;

  /// Link to the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccountLink;

  /// Text above the rider sign-up link at the bottom of the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Want to earn as a rider?'**
  String get riderPrompt;

  /// Link that starts sign-up with the intent to become a rider.
  ///
  /// In en, this message translates to:
  /// **'Join as a boda boda rider'**
  String get riderJoinLink;

  /// Heading of the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get signUpTitle;

  /// Shown on sign-up when the user came from 'Join as a boda boda rider'.
  ///
  /// In en, this message translates to:
  /// **'You\'ll set up your rider profile after confirming your email.'**
  String get signUpRiderNote;

  /// First name field label.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameLabel;

  /// Last name field label.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameLabel;

  /// Live hint under a new-password field. No other password rules apply.
  ///
  /// In en, this message translates to:
  /// **'At least 15 characters'**
  String get passwordHint;

  /// Primary button on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// Text before the sign-in link on the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// Link back to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// Heading of the email confirmation code screen.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyTitle;

  /// Explains where the confirmation code was sent.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String verifySentTo(String email);

  /// Shown when a sign-in found an unconfirmed email.
  ///
  /// In en, this message translates to:
  /// **'Your email {email} isn\'t confirmed yet. Request a new code and enter it below.'**
  String verifyNotConfirmed(String email);

  /// Label of the confirmation code field.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// Button that submits the confirmation code.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get verifyButton;

  /// Button to send a new code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Disabled resend button with a countdown.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendIn(int seconds);

  /// Confirmation after a new code is sent.
  ///
  /// In en, this message translates to:
  /// **'We sent a new code.'**
  String get codeResent;

  /// Heading of the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// Instructions on the forgot-password screen.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll send you a code.'**
  String get forgotBody;

  /// Button that requests a password reset code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCodeButton;

  /// Link back to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// Heading of the reset-password screen.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  /// Neutral wording: the server never reveals whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we sent it a 6-digit code.'**
  String resetSentTo(String email);

  /// New password field label.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// Button that sets the new password.
  ///
  /// In en, this message translates to:
  /// **'Save new password'**
  String get resetButton;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorEmailInvalid;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name.'**
  String get errorFirstNameRequired;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name.'**
  String get errorLastNameRequired;

  /// Validation error for names.
  ///
  /// In en, this message translates to:
  /// **'Use 50 characters or fewer.'**
  String get errorNameTooLong;

  /// Validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordRequired;

  /// Validation error for new passwords.
  ///
  /// In en, this message translates to:
  /// **'Use at least 15 characters.'**
  String get errorPasswordTooShort;

  /// Validation error for new passwords.
  ///
  /// In en, this message translates to:
  /// **'Use 72 characters or fewer.'**
  String get errorPasswordTooLong;

  /// Validation error for the code field.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get errorCodeFormat;

  /// Sign-in failed.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get errorWrongCredentials;

  /// Code rejected by the server.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired.'**
  String get errorInvalidCode;

  /// Server rate limit (429).
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get errorTooManyAttempts;

  /// Server or upstream error (5xx).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete that right now. Please try again shortly.'**
  String get errorServiceUnavailable;

  /// The server could not be reached.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorNetwork;

  /// Fallback error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// Google sign-in failed (not cancelled).
  ///
  /// In en, this message translates to:
  /// **'Google sign-in didn\'t work. Please try again.'**
  String get errorGoogleFailed;

  /// Splash heading when a stored session can't be checked because there is no connection.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineTitle;

  /// Splash body for the offline state.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach RideLink. You\'re still signed in.'**
  String get offlineBody;

  /// Retry button.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// Heading of the placeholder rider onboarding screen (real screens come later).
  ///
  /// In en, this message translates to:
  /// **'Rider setup'**
  String get riderOnboardingTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
