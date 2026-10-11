// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appName => 'RideLink';

  @override
  String get appTagline => 'Mizigo na safari unazoweza kuamini';

  @override
  String get signInTitle => 'Ingia';

  @override
  String get emailLabel => 'Barua pepe';

  @override
  String get passwordLabel => 'Nenosiri';

  @override
  String get showPassword => 'Onyesha nenosiri';

  @override
  String get hidePassword => 'Ficha nenosiri';

  @override
  String get forgotPasswordLink => 'Umesahau nenosiri?';

  @override
  String get signInButton => 'Ingia';

  @override
  String get orDivider => 'au';

  @override
  String get continueWithGoogle => 'Endelea na Google';

  @override
  String get noAccountPrompt => 'Mgeni kwenye RideLink?';

  @override
  String get createAccountLink => 'Fungua akaunti';

  @override
  String get riderPrompt => 'Unataka kupata kipato kama mwendesha boda?';

  @override
  String get riderJoinLink => 'Jiunge kama mwendesha boda boda';

  @override
  String get signUpTitle => 'Fungua akaunti yako';

  @override
  String get signUpRiderNote =>
      'Utaweka wasifu wako wa mwendesha boda baada ya kuthibitisha barua pepe yako.';

  @override
  String get firstNameLabel => 'Jina la kwanza';

  @override
  String get lastNameLabel => 'Jina la mwisho';

  @override
  String get passwordHint => 'Angalau herufi 15';

  @override
  String get signUpButton => 'Fungua akaunti';

  @override
  String get haveAccountPrompt => 'Tayari una akaunti?';

  @override
  String get signInLink => 'Ingia';

  @override
  String get verifyTitle => 'Angalia barua pepe yako';

  @override
  String verifySentTo(String email) {
    return 'Tumetuma nambari ya tarakimu 6 kwa $email.';
  }

  @override
  String verifyNotConfirmed(String email) {
    return 'Barua pepe yako $email bado haijathibitishwa. Omba nambari mpya kisha uiweke hapa chini.';
  }

  @override
  String get codeLabel => 'Nambari ya tarakimu 6';

  @override
  String get verifyButton => 'Thibitisha';

  @override
  String get resendCode => 'Tuma nambari tena';

  @override
  String resendIn(int seconds) {
    return 'Tuma tena baada ya sekunde $seconds';
  }

  @override
  String get codeResent => 'Tumetuma nambari mpya.';

  @override
  String get forgotTitle => 'Badilisha nenosiri lako';

  @override
  String get forgotBody =>
      'Weka barua pepe ya akaunti yako, tutakutumia nambari.';

  @override
  String get sendCodeButton => 'Tuma nambari';

  @override
  String get backToSignIn => 'Rudi kwenye kuingia';

  @override
  String get resetTitle => 'Chagua nenosiri jipya';

  @override
  String resetSentTo(String email) {
    return 'Kama kuna akaunti ya $email, tumeitumia nambari ya tarakimu 6.';
  }

  @override
  String get newPasswordLabel => 'Nenosiri jipya';

  @override
  String get resetButton => 'Hifadhi nenosiri jipya';

  @override
  String get errorEmailInvalid => 'Weka barua pepe sahihi.';

  @override
  String get errorFirstNameRequired => 'Weka jina lako la kwanza.';

  @override
  String get errorLastNameRequired => 'Weka jina lako la mwisho.';

  @override
  String get errorNameTooLong => 'Tumia herufi 50 au chache.';

  @override
  String get errorPasswordRequired => 'Weka nenosiri lako.';

  @override
  String get errorPasswordTooShort => 'Tumia angalau herufi 15.';

  @override
  String get errorPasswordTooLong => 'Tumia herufi 72 au chache.';

  @override
  String get errorCodeFormat => 'Weka nambari ya tarakimu 6.';

  @override
  String get errorWrongCredentials => 'Barua pepe au nenosiri si sahihi.';

  @override
  String get errorInvalidCode => 'Nambari hiyo si sahihi au muda wake umeisha.';

  @override
  String get errorTooManyAttempts =>
      'Umejaribu mara nyingi mno. Subiri kidogo kisha ujaribu tena.';

  @override
  String get errorServiceUnavailable =>
      'Hatukuweza kukamilisha hilo sasa hivi. Tafadhali jaribu tena baadaye kidogo.';

  @override
  String get errorNetwork =>
      'Hakuna mtandao. Angalia muunganisho wako kisha ujaribu tena.';

  @override
  String get errorGeneric => 'Kuna hitilafu. Tafadhali jaribu tena.';

  @override
  String get errorGoogleFailed =>
      'Kuingia kwa Google hakukufanikiwa. Tafadhali jaribu tena.';

  @override
  String get offlineTitle => 'Huna mtandao';

  @override
  String get offlineBody =>
      'Hatukuweza kufikia RideLink. Bado umeingia kwenye akaunti yako.';

  @override
  String get retryButton => 'Jaribu tena';

  @override
  String get riderOnboardingTitle => 'Usajili wa mwendesha boda';
}
