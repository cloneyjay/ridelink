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

  @override
  String get menuTooltip => 'Menyu';

  @override
  String get menuSwitchToRiding => 'Badili uendeshe boda';

  @override
  String get menuSwitchToSending => 'Badili utume';

  @override
  String get menuBecomeRider => 'Kuwa mwendesha boda';

  @override
  String get menuRiderStatusError =>
      'Hatukuweza kuangalia akaunti yako ya mwendesha boda.';

  @override
  String get menuSignOut => 'Toka';

  @override
  String get riderHomeTitle => 'Hali ya mwendesha boda';

  @override
  String get homeWhatDoYouNeed => 'Unahitaji nini?';

  @override
  String get serviceDelivery => 'Kutuma mzigo';

  @override
  String get serviceDeliverySubtitle => 'Tuma kifurushi';

  @override
  String get serviceRide => 'Safari';

  @override
  String get serviceRideSubtitle => 'Pata safari ya boda';

  @override
  String get mapUnavailable => 'Ramani haipatikani kwa sasa';

  @override
  String get locationDeniedTitle => 'Mahali pamezimwa';

  @override
  String get locationDeniedBody =>
      'Ruhusu mahali ili tukuonyeshe ulipo. Bado unaweza kuagiza kwa kutafuta maeneo.';

  @override
  String get locationServiceOffBody =>
      'Washa mahali kwenye simu yako ili tukuonyeshe ulipo. Bado unaweza kuagiza kwa kutafuta maeneo.';

  @override
  String get locationUnavailableBody =>
      'Hatukuweza kupata mahali ulipo. Bado unaweza kuagiza kwa kutafuta maeneo.';

  @override
  String get locationAllow => 'Ruhusu mahali';

  @override
  String get locationOpenSettings => 'Fungua mipangilio';

  @override
  String get locationTurnOn => 'Washa mahali';

  @override
  String get newDeliveryTitle => 'Mzigo mpya';

  @override
  String get newRideTitle => 'Safari mpya';

  @override
  String get pickupLabel => 'Mahali pa kuchukua';

  @override
  String get dropoffLabel => 'Mahali pa kufikisha';

  @override
  String get choosePickup => 'Chagua mahali pa kuchukua';

  @override
  String get chooseDropoff => 'Chagua mahali pa kufikisha';

  @override
  String get itemSectionTitle => 'Mzigo';

  @override
  String get categoryLabel => 'Aina';

  @override
  String get descriptionLabel => 'Maelezo';

  @override
  String get weightLabel => 'Uzito kwa kg (si lazima)';

  @override
  String get valueBandLabel => 'Thamani ya mzigo';

  @override
  String get valueBandCapNote =>
      'Mizigo yenye thamani zaidi ya KES 10,000 haiwezi kuagizwa.';

  @override
  String get receiverSectionTitle => 'Mpokeaji';

  @override
  String get receiverNameLabel => 'Jina la mpokeaji';

  @override
  String get findRidersButton => 'Tafuta waendesha boda';

  @override
  String get errorPickupRequired => 'Chagua mahali pa kuchukua';

  @override
  String get errorDropoffRequired => 'Chagua mahali pa kufikisha';

  @override
  String get errorReceiverRequired => 'Weka jina la mpokeaji';

  @override
  String get errorCategoryRequired => 'Chagua aina';

  @override
  String get errorDescriptionRequired => 'Eleza mzigo';

  @override
  String get errorWeightInvalid => 'Weka uzito zaidi ya 0';

  @override
  String get errorValueBandRequired => 'Chagua thamani ya mzigo';

  @override
  String get createOrderFailed => 'Hatukuweza kuunda oda yako. Jaribu tena.';

  @override
  String get categoriesLoadFailed => 'Hatukuweza kupakia aina za mizigo.';

  @override
  String get valueBandUnder500 => 'Chini ya KES 500';

  @override
  String get valueBand500To2000 => 'KES 500–2,000';

  @override
  String get valueBand2000To5000 => 'KES 2,000–5,000';

  @override
  String get valueBand5000To10000 => 'KES 5,000–10,000';

  @override
  String get categoryDocuments => 'Nyaraka';

  @override
  String get categoryFood => 'Chakula';

  @override
  String get categoryElectronics => 'Vifaa vya elektroniki';

  @override
  String get categoryClothing => 'Nguo';

  @override
  String get categoryFragile => 'Vitu vinavyovunjika';

  @override
  String get categoryMedication => 'Dawa';

  @override
  String get categoryCash => 'Pesa taslimu';

  @override
  String get categoryAlcohol => 'Pombe';

  @override
  String get categoryOther => 'Nyingine';

  @override
  String get placeSearchHint => 'Tafuta mahali';

  @override
  String get placeSearchMinChars => 'Andika angalau herufi 2';

  @override
  String get placeSearchNoResults => 'Hakuna maeneo yaliyopatikana';

  @override
  String get placeSearchUnavailable =>
      'Utafutaji wa maeneo haupatikani kwa sasa. Jaribu tena baadaye.';

  @override
  String get placeSearchFailed => 'Hatukuweza kutafuta. Angalia mtandao wako.';

  @override
  String get clearSearch => 'Futa';

  @override
  String get riderListTitle => 'Chagua mwendesha boda';

  @override
  String get sortByPrice => 'Bei';

  @override
  String get sortByDistance => 'Umbali';

  @override
  String tripDistance(String distance) {
    return 'Safari $distance';
  }

  @override
  String get distanceEstimatedNote => 'Umbali ni wa makadirio';

  @override
  String get noRidersTitle => 'Hakuna waendesha boda karibu kwa sasa';

  @override
  String get noRidersBody => 'Jaribu tena baada ya muda mfupi.';

  @override
  String get ridersLoadFailed => 'Hatukuweza kupakia waendesha boda.';

  @override
  String get noRatingsYet => 'Bado hana ukadiriaji';

  @override
  String ratingCount(int count) {
    return 'Ukadiriaji $count';
  }

  @override
  String onTimePercent(int percent) {
    return '$percent% kwa wakati';
  }

  @override
  String completedJobs(int count) {
    return '$count zimekamilika';
  }

  @override
  String pickupDistanceAway(String distance) {
    return '$distance kutoka mahali pa kuchukua';
  }

  @override
  String arrivesWithin(int minutes) {
    return 'Atafika ndani ya dakika $minutes';
  }

  @override
  String get editRoute => 'Badilisha njia';

  @override
  String get offerDeclinedMessage =>
      'Mwendesha boda amekataa. Chagua mwingine.';

  @override
  String get offerExpiredMessage =>
      'Mwendesha boda hakujibu kwa wakati. Chagua mwingine.';

  @override
  String get riderProfileTitle => 'Wasifu wa mwendesha boda';

  @override
  String get statRating => 'Ukadiriaji';

  @override
  String get statOnTime => 'Kwa wakati';

  @override
  String get statCompleted => 'Kazi zilizokamilika';

  @override
  String get statPickup => 'Kuchukua';

  @override
  String get priceForThisTrip => 'Bei ya safari hii';

  @override
  String get breakdownBaseFare => 'Nauli ya msingi';

  @override
  String breakdownPlatform(String distance) {
    return 'Bei ya jukwaa kwa $distance';
  }

  @override
  String breakdownRider(String distance) {
    return 'Bei ya mwendesha boda zaidi ya $distance';
  }

  @override
  String breakdownRiderDetail(String distance, String rate) {
    return '$distance kwa $rate kwa kila km';
  }

  @override
  String get breakdownMinimumFare => 'Nauli ya chini inatumika kwa safari hii';

  @override
  String get breakdownTotal => 'Jumla';

  @override
  String get requestButton => 'Omba';

  @override
  String get quoteTitle => 'Bei ya safari';

  @override
  String get youPay => 'Utalipa';

  @override
  String get quoteFinalNote =>
      'Bei hii ni ya mwisho. Itafungwa mwendesha boda akikubali.';

  @override
  String get sendRequestButton => 'Tuma ombi';

  @override
  String get sendRequestFailed => 'Hatukuweza kutuma ombi. Jaribu tena.';

  @override
  String waitingTitle(String name) {
    return 'Tunamsubiri $name';
  }

  @override
  String get waitingBody =>
      'Mwendesha boda ana muda mfupi wa kukubali ombi lako.';

  @override
  String get waitingChecking => 'Tunaangalia jibu la mwendesha boda…';

  @override
  String get secondsLabel => 'sekunde';

  @override
  String get cancelRequestButton => 'Ghairi ombi';

  @override
  String get cancelConfirmTitle => 'Ghairi ombi hili?';

  @override
  String get cancelConfirmBody => 'Oda yako itaghairiwa.';

  @override
  String get cancelConfirmYes => 'Ghairi oda';

  @override
  String get cancelConfirmNo => 'Endelea kusubiri';

  @override
  String get cancelFailed =>
      'Hatukuweza kughairi. Huenda mwendesha boda amesha jibu.';

  @override
  String get orderCancelledMessage => 'Oda yako imeghairiwa.';

  @override
  String get backToHome => 'Rudi mwanzo';

  @override
  String get editRouteTitle => 'Badilisha njia';

  @override
  String get saveRouteButton => 'Hifadhi njia';

  @override
  String get routeUpdateFailed => 'Hatukuweza kubadilisha njia. Jaribu tena.';

  @override
  String get routeLocked => 'Njia hii haiwezi kubadilishwa tena.';

  @override
  String get closeTooltip => 'Funga';

  @override
  String get riderLoadFailed =>
      'Hatukuweza kupakia wasifu wako wa mwendesha boda.';

  @override
  String get registerIntro =>
      'Sajili boda boda yako ili uanze kupokea maombi ya kusafirisha mizigo na abiria. Kisha utapakia hati zako zikaguliwe.';

  @override
  String get vehicleLabel => 'Chombo';

  @override
  String get vehicleBodaBoda => 'Boda boda';

  @override
  String get vehicleOnlyBoda => 'Boda boda ndicho chombo pekee kwa sasa.';

  @override
  String get plateLabel => 'Nambari ya usajili';

  @override
  String get plateHint => 'mfano KMFA 123B';

  @override
  String get plateInvalid => 'Weka herufi, tarakimu au nafasi 3 hadi 12';

  @override
  String get registerButton => 'Jisajili';

  @override
  String get registerFailed => 'Hatukuweza kukusajili. Jaribu tena.';

  @override
  String get documentsTitle => 'Hati';

  @override
  String get documentsIntro =>
      'Wafanyakazi wa RideLink hukagua kila hati. Unaweza kuingia mtandaoni zote zikishaidhinishwa.';

  @override
  String documentsProgress(int done, int total) {
    return '$done kati ya $total zimepakiwa';
  }

  @override
  String get documentsContinue => 'Endelea';

  @override
  String get documentsUploadAll => 'Pakia kila hati ili uendelee.';

  @override
  String get documentsLoadFailed => 'Hatukuweza kupakia hati zako.';

  @override
  String get docRiderPhoto => 'Picha ya mwendesha boda';

  @override
  String get docRiderPhotoHint =>
      'Picha safi ya uso wako. Wateja huiona kabla na wakati wa kazi.';

  @override
  String get docNationalId => 'Kitambulisho cha taifa';

  @override
  String get docNationalIdHint => 'Upande wa mbele wa kitambulisho chako.';

  @override
  String get docDrivingLicence => 'Leseni ya udereva';

  @override
  String get docDrivingLicenceHint =>
      'Leseni ya pikipiki (Daraja A), pamoja na tarehe inapoisha.';

  @override
  String get docPoliceClearance => 'Cheti cha tabia njema';

  @override
  String get docPoliceClearanceHint =>
      'Cheti cha tabia njema cha DCI, pamoja na tarehe kilipotolewa. Ni halali kwa miezi 12.';

  @override
  String get docPsvInsurance => 'Bima ya PSV';

  @override
  String get docPsvInsuranceHint =>
      'Cheti cha bima yako ya PSV, pamoja na tarehe inapoisha.';

  @override
  String get docLogbook => 'Kitabu cha usajili au mkataba wa mauzo';

  @override
  String get docLogbookHint =>
      'Ushahidi kwamba unamiliki au unaruhusiwa kutumia pikipiki.';

  @override
  String get docBikeRearPhoto => 'Picha ya nyuma ya pikipiki';

  @override
  String get docBikeRearPhotoHint =>
      'Picha ya nyuma ya pikipiki yako ikionyesha nambari ya usajili.';

  @override
  String get docStatusMissing => 'Haijapakiwa';

  @override
  String get docStatusPending => 'Inakaguliwa';

  @override
  String get docStatusApproved => 'Imeidhinishwa';

  @override
  String get docStatusRejected => 'Imekataliwa';

  @override
  String docRejectedReason(String reason) {
    return 'Sababu: $reason';
  }

  @override
  String docExpiresOn(String date) {
    return 'Inaisha $date';
  }

  @override
  String docIssuedOn(String date) {
    return 'Ilitolewa $date';
  }

  @override
  String get docPendingStillValid =>
      'Hati yako iliyoidhinishwa inaendelea kutumika hii ikikaguliwa.';

  @override
  String get docUploadAction => 'Pakia';

  @override
  String get docReplaceAction => 'Badilisha';

  @override
  String docUploaded(String name) {
    return '$name imepakiwa';
  }

  @override
  String get docFormatsImage => 'Picha ya JPEG au PNG, hadi MB 10.';

  @override
  String get docFormatsAny => 'Picha ya JPEG au PNG, au PDF, hadi MB 10.';

  @override
  String get docChooseExpiry => 'Chagua tarehe ya kuisha';

  @override
  String get docChooseIssued => 'Chagua tarehe ya kutolewa';

  @override
  String get docTakePhoto => 'Piga picha';

  @override
  String get docChooseGallery => 'Chagua kutoka kwenye picha';

  @override
  String get docChooseFile => 'Chagua faili ya PDF au picha';

  @override
  String get docUploadButton => 'Pakia';

  @override
  String get docTooLarge => 'Faili lazima iwe MB 10 au chini.';

  @override
  String get docImageOnly => 'Hati hii lazima iwe picha (JPEG au PNG).';

  @override
  String get docDateRequired => 'Chagua tarehe kwanza.';

  @override
  String get docPickFailed => 'Hatukuweza kufungua faili. Jaribu tena.';

  @override
  String get docUploadFailed =>
      'Hatukuweza kupakia. Angalia mtandao wako kisha ujaribu tena.';

  @override
  String get verificationTitle => 'Uthibitisho';

  @override
  String get verificationPendingTitle => 'Hati zako zinakaguliwa';

  @override
  String get verificationPendingBody => 'Tutakujulisha ukaguzi ukikamilika.';

  @override
  String get verificationApprovedTitle => 'Umeidhinishwa';

  @override
  String get verificationApprovedBody =>
      'Unaweza kuingia mtandaoni na kuanza kupokea maombi.';

  @override
  String get verificationRejectedTitle =>
      'Baadhi ya hati zinahitaji kurekebishwa';

  @override
  String get verificationRejectedBody =>
      'Angalia sababu kisha upakie hati mpya.';

  @override
  String get verificationIncompleteTitle => 'Maliza kupakia hati zako';

  @override
  String get verificationIncompleteBody =>
      'Ukaguzi unaanza kila hati ikishapakiwa.';

  @override
  String get goToRiderHome => 'Nenda ukurasa wa mwendesha boda';

  @override
  String get fixDocumentsButton => 'Pakia hati';

  @override
  String get viewDocumentsButton => 'Tazama hati';

  @override
  String get refreshButton => 'Onyesha upya';

  @override
  String get riderNotRegisteredTitle => 'Bado hujajisajili kama mwendesha boda';

  @override
  String get riderOnline => 'Uko mtandaoni';

  @override
  String get riderOffline => 'Hauko mtandaoni';

  @override
  String riderOnlineBody(String distance) {
    return 'Unapokea maombi yenye kuchukua ndani ya $distance';
  }

  @override
  String get riderOfflineBody =>
      'Ingia mtandaoni ili upokee maombi ya mizigo na abiria.';

  @override
  String riderSettingsSummary(String radius, String delivery, String ride) {
    return 'Umbali wa kuchukua $radius · Mizigo $delivery/km · Abiria $ride/km';
  }

  @override
  String riderPlate(String plate) {
    return 'Boda boda $plate';
  }

  @override
  String get blockNotVerifiedTitle => 'Akaunti yako bado haijaidhinishwa';

  @override
  String get blockNotVerifiedBody =>
      'Utaweza kuingia mtandaoni RideLink ikishaidhinisha hati zako.';

  @override
  String get viewStatusButton => 'Tazama hali';

  @override
  String get blockDocumentsTitle => 'Hati zinahitaji kushughulikiwa';

  @override
  String blockDocumentsBody(String documents) {
    return 'Huisha au pakia: $documents';
  }

  @override
  String get blockDocumentsBodyGeneric =>
      'Hati moja au zaidi hazipo au zimeisha muda.';

  @override
  String get updateDocumentsButton => 'Sasisha hati';

  @override
  String blockPausedTitle(String time) {
    return 'Umesimamishwa hadi $time';
  }

  @override
  String blockPausedMissedPickups(int count) {
    return 'Baada ya kukosa kuchukua mara $count ndani ya saa 24, hutapokea maombi hadi wakati huo.';
  }

  @override
  String get blockPausedBody => 'Hutapokea maombi hadi wakati huo.';

  @override
  String get blockLocationTitle => 'Washa eneo ili uingie mtandaoni';

  @override
  String get blockLocationBody =>
      'RideLink hutumia eneo lako ukiwa mtandaoni ili wateja wakupate na kuchukua kurekodiwe.';

  @override
  String get blockErrorTitle => 'Hatukuweza kubadilisha hali yako';

  @override
  String get onlineNotificationTitle => 'Uko mtandaoni';

  @override
  String get onlineNotificationBody =>
      'RideLink inatumia eneo lako kwa maombi na kuchukua mizigo.';

  @override
  String get onlineNotificationChannel => 'Hali ya mtandaoni';

  @override
  String get riderOfferTitle => 'Ombi jipya';

  @override
  String get riderOfferChecking => 'Muda umeisha. Tunaangalia ombi…';

  @override
  String get youEarn => 'Utapata';

  @override
  String reachPickupWithin(int minutes) {
    return 'Fika mahali pa kuchukua ndani ya dakika $minutes';
  }

  @override
  String get acceptButton => 'Kubali';

  @override
  String get declineButton => 'Kataa';

  @override
  String get acceptNeedsLocation =>
      'Washa eneo ili ukubali. Eneo lako lazima liwe la sasa.';

  @override
  String get acceptFailed => 'Hatukuweza kukubali. Jaribu tena.';

  @override
  String get declineFailed => 'Hatukuweza kukataa. Jaribu tena.';

  @override
  String get riderOfferExpired => 'Ombi limeisha muda.';

  @override
  String get riderOfferDeclined => 'Umekataa ombi.';

  @override
  String get riderOfferTaken => 'Ombi hili halipatikani tena.';

  @override
  String get riderOfferCancelled => 'Mteja ameghairi ombi.';

  @override
  String get jobTitle => 'Kazi ya sasa';

  @override
  String get jobToPickup => 'Elekea mahali pa kuchukua';

  @override
  String get jobAtPickup => 'Uko mahali pa kuchukua';

  @override
  String get jobAtPickupNote =>
      'Kufika kumerekodiwa. Chukua kisha bonyeza Nimechukua.';

  @override
  String get jobPickedUp => 'Umechukua';

  @override
  String get jobInTransit => 'Njiani kwenda mahali pa kufikisha';

  @override
  String get jobAtDropoff => 'Uko mahali pa kufikisha';

  @override
  String get jobAtDropoffBody =>
      'Omba malipo kutoka kwa mteja kabla ya kukabidhi.';

  @override
  String get jobPayment => 'Malipo';

  @override
  String jobWaitingForSender(String amount) {
    return 'Unasubiri mteja alipe $amount taslimu.';
  }

  @override
  String jobSenderPaid(String amount) {
    return 'Mteja anasema amelipa $amount taslimu. Thibitisha ukishapokea.';
  }

  @override
  String get jobPaid => 'Malipo yamepokelewa';

  @override
  String get jobPaidBody =>
      'Malipo yamethibitishwa. Kabidhi, kisha weka alama hapa chini.';

  @override
  String get jobHandedOver => 'Imekabidhiwa';

  @override
  String get jobCompleted => 'Kazi imekamilika';

  @override
  String jobCompletedBody(String amount) {
    return 'Umepata $amount.';
  }

  @override
  String get jobCancelled => 'Kazi imeghairiwa';

  @override
  String get jobCancelledBySender => 'Mteja ameghairi oda hii.';

  @override
  String get jobCancelledTimeout =>
      'Muda wa kufika mahali pa kuchukua umepita, kwa hiyo oda imeghairiwa.';

  @override
  String get jobCancelledByYou => 'Umeghairi oda hii.';

  @override
  String get jobCancelledGeneric => 'Oda hii imeghairiwa.';

  @override
  String get agreedPrice => 'Bei iliyokubaliwa';

  @override
  String get reachPickupIn => 'Fika mahali pa kuchukua ndani ya';

  @override
  String pickupDeadlineAt(String time) {
    return 'Mwisho $time';
  }

  @override
  String get arrivalAutoNote =>
      'Kufika hurekodiwa moja kwa moja ukiwa ndani ya mita 150 kutoka mahali pa kuchukua.';

  @override
  String get headingToPickup => 'Unaelekea kuchukua';

  @override
  String get headingToDropoff => 'Unaelekea kufikisha';

  @override
  String receiverIs(String name) {
    return 'Mpokeaji: $name';
  }

  @override
  String get actionArrivedAtPickup => 'Nimefika';

  @override
  String get actionPickedUp => 'Nimechukua';

  @override
  String get actionStartTrip => 'Anza safari kwenda kufikisha';

  @override
  String get actionArrivedAtDropoff => 'Nimefika mahali pa kufikisha';

  @override
  String get actionRequestPayment => 'Omba malipo';

  @override
  String get actionHandOver => 'Weka alama imekabidhiwa';

  @override
  String get actionComplete => 'Kamilisha kazi';

  @override
  String get jobActionFailed => 'Hatukuweza kusasisha kazi. Jaribu tena.';

  @override
  String get paymentReceivedButton => 'Nimepokea malipo';

  @override
  String paymentReceivedConfirmTitle(String amount) {
    return 'Umepokea $amount taslimu?';
  }

  @override
  String get paymentReceivedConfirmBody =>
      'Thibitisha tu pesa zikiwa mkononi mwako. Hii inarekodiwa na haiwezi kubadilishwa.';

  @override
  String get paymentNotReceivedButton => 'Sijapokea';

  @override
  String get paymentNotReceivedConfirmTitle =>
      'Ripoti kwamba hujapokea malipo?';

  @override
  String get paymentNotReceivedConfirmBody =>
      'Oda itapelekwa RideLink ikaguliwe.';

  @override
  String get goBackButton => 'Rudi';

  @override
  String get riderCancelButton => 'Ghairi kazi';

  @override
  String get riderCancelTitle => 'Ghairi kazi hii?';

  @override
  String riderCancelWithinGrace(String time) {
    return 'Ulikubali chini ya dakika 2 zilizopita, kwa hiyo kughairi sasa hakutahesabiwa kwenye kusimamishwa (zimebaki $time). Bado kutaonekana kwenye rekodi yako ya kughairi.';
  }

  @override
  String get riderCancelAfterGrace =>
      'Zaidi ya dakika 2 zimepita tangu ukubali, kwa hiyo hii inahesabiwa kama kukosa kuchukua. Mara 3 ndani ya saa 24 hukusimamisha.';

  @override
  String get riderCancelConfirm => 'Ghairi kazi';

  @override
  String get riderCancelKeep => 'Endelea na kazi';

  @override
  String get doneButton => 'Sawa';

  @override
  String get paymentUnderReview => 'Tunakagua malipo haya';

  @override
  String get paymentUnderReviewRiderBody =>
      'Umeripoti kwamba hukupokea pesa. RideLink itakagua oda hii.';

  @override
  String get paymentUnderReviewSenderBody =>
      'Mwendesha boda wako ameripoti kwamba hakupokea pesa. RideLink itakagua oda hii.';

  @override
  String get trackingScreenTitle => 'Oda yako';

  @override
  String get trackingLoadFailed => 'Hatukuweza kupakia oda yako.';

  @override
  String get trackingActionFailed => 'Hatukuweza kusasisha oda. Jaribu tena.';

  @override
  String riderArrivesIn(int minutes) {
    return 'Mwendesha boda atafika baada ya dakika $minutes';
  }

  @override
  String get riderArrivedAtPickup => 'Mwendesha boda wako amefika';

  @override
  String get trackingOnTheWay => 'Njiani kwenda mahali pa kufikisha';

  @override
  String get riderAtDropoff => 'Mwendesha boda wako yuko mahali pa kufikisha';

  @override
  String get delivered => 'Imefikishwa';

  @override
  String get tripComplete => 'Safari imekamilika';

  @override
  String get orderCancelledTimeout =>
      'Mwendesha boda hakufika kwa wakati, kwa hiyo oda imeghairiwa.';

  @override
  String get orderCancelledByRider => 'Mwendesha boda ameghairi oda hii.';

  @override
  String get orderCancelledBySender => 'Umeghairi oda hii.';

  @override
  String get stepAccepted => 'Imekubaliwa';

  @override
  String get stepAtPickup => 'Mahali pa kuchukua';

  @override
  String get stepInTransit => 'Njiani';

  @override
  String get stepPayment => 'Malipo';

  @override
  String get stepDelivered => 'Imefikishwa';

  @override
  String get stepDroppedOff => 'Umefikishwa';

  @override
  String payInCash(String amount) {
    return 'Lipa $amount taslimu kwa mwendesha boda wako';
  }

  @override
  String get payInCashBody =>
      'Kisha bonyeza \"Nimelipa\". Mwendesha boda atathibitisha akipokea pesa.';

  @override
  String get ivePaidButton => 'Nimelipa';

  @override
  String ivePaidConfirmTitle(String amount) {
    return 'Umelipa $amount?';
  }

  @override
  String get ivePaidConfirmBody =>
      'Thibitisha tu baada ya kumpa mwendesha boda pesa. Hii inarekodiwa.';

  @override
  String get waitingForRiderConfirm =>
      'Unasubiri mwendesha boda athibitishe malipo';

  @override
  String paymentConfirmed(String amount) {
    return 'Malipo ya $amount yamethibitishwa';
  }

  @override
  String get viewTerms => 'Tazama masharti';

  @override
  String get termsTitle => 'Masharti yaliyokubaliwa';

  @override
  String get termsLockedNote =>
      'Masharti haya yalifungwa mwendesha boda alipokubali.';

  @override
  String get termsPickupWindow => 'Muda wa kufika kuchukua';

  @override
  String minutesShort(int minutes) {
    return 'Dakika $minutes';
  }

  @override
  String get senderCancelButton => 'Ghairi oda';

  @override
  String get senderCancelTitle => 'Ghairi oda hii?';

  @override
  String get senderCancelBody =>
      'Mwendesha boda amekubali na yuko njiani. Oda yako itaghairiwa.';

  @override
  String get senderCancelKeep => 'Endelea na oda';

  @override
  String get discardOrderTitle => 'Futa oda hii?';

  @override
  String get discardOrderBody => 'Oda yako itaghairiwa.';

  @override
  String get discardOrderConfirm => 'Futa';

  @override
  String get discardOrderKeep => 'Endelea na oda';

  @override
  String get discardOrderFailed => 'Hatukuweza kufuta oda. Jaribu tena.';

  @override
  String get activeOrderBanner => 'Una oda inayoendelea';

  @override
  String get viewButton => 'Tazama';

  @override
  String get settingsTitle => 'Bei na mipangilio';

  @override
  String get settingsDistanceSection => 'Umbali';

  @override
  String get settingsPickupRadius => 'Umbali wa kuchukua';

  @override
  String settingsPickupRadiusHelp(String max) {
    return 'Umbali utakaosafiri kuchukua. Hadi $max.';
  }

  @override
  String get settingsMaxDistance => 'Umbali wa bei ya jukwaa';

  @override
  String settingsMaxDistanceHelp(String min) {
    return 'Safari hadi umbali huu zinatumia bei ya jukwaa; bei yako inatumika zaidi ya hapo. Angalau $min.';
  }

  @override
  String get settingsRatesSection => 'Bei zako';

  @override
  String get settingsRatesNote =>
      'Hutozwa kwa kila km zaidi ya umbali wa bei ya jukwaa.';

  @override
  String get settingsDeliveryRate => 'Bei ya mizigo';

  @override
  String get settingsRideRate => 'Bei ya abiria';

  @override
  String settingsRateRange(String min, String max) {
    return 'Kati ya $min na $max kwa km';
  }

  @override
  String get settingsLoadSection => 'Mzigo';

  @override
  String get settingsMaxWeight => 'Uzito wa juu wa mzigo';

  @override
  String get settingsMaxWeightHelp => 'Mzigo mzito zaidi utakaobeba.';

  @override
  String get settingsSave => 'Hifadhi';

  @override
  String get settingsSaved => 'Mipangilio imehifadhiwa';

  @override
  String get settingsSaveFailed => 'Hatukuweza kuhifadhi. Jaribu tena.';

  @override
  String get settingsLoadFailed => 'Hatukuweza kupakia mipangilio yako.';

  @override
  String get settingsRequired => 'Weka thamani';

  @override
  String get settingsNotNumber => 'Weka nambari';

  @override
  String get settingsMustBePositive => 'Weka thamani zaidi ya 0';

  @override
  String get settingsTooHigh => 'Thamani hii ni kubwa mno';

  @override
  String settingsRadiusTooHigh(String max) {
    return 'Isizidi $max';
  }

  @override
  String settingsDistanceTooLow(String min) {
    return 'Angalau $min';
  }

  @override
  String get unitKm => 'km';

  @override
  String get unitPerKm => 'KES/km';

  @override
  String get unitKg => 'kg';

  @override
  String get errCodeInvalidRequest =>
      'Baadhi ya taarifa si sahihi. Ziangalie kisha ujaribu tena.';

  @override
  String get errCodeUnauthorized =>
      'Muda wako wa kuingia umeisha. Tafadhali ingia tena.';

  @override
  String get errCodeForbidden => 'Huna ruhusa ya kufanya hivi.';

  @override
  String get errCodeNotFound => 'Hatukupata hicho. Huenda kimeondolewa.';

  @override
  String get errCodeConflict =>
      'Hili limebadilika. Onyesha upya kisha ujaribu tena.';

  @override
  String get errCodeInvalidStatus =>
      'Oda hii imeshabadilika. Onyesha upya kisha ujaribu tena.';

  @override
  String get errCodeFileTooLarge =>
      'Faili ni kubwa mno. Tumia faili lililo chini ya MB 10.';

  @override
  String get errCodeInternalError =>
      'Kuna hitilafu upande wetu. Tafadhali jaribu tena.';

  @override
  String get errCodeUpstreamUnavailable =>
      'Huduma tunayoitegemea haijibu. Tafadhali jaribu tena.';

  @override
  String get errCodeServiceUnavailable =>
      'Hii haipatikani kwa sasa. Tafadhali jaribu tena baadaye.';

  @override
  String get errCodeInvalidName => 'Majina yawe na herufi 1 hadi 50.';

  @override
  String get errCodeMissingFields => 'Jaza sehemu zote zinazohitajika.';

  @override
  String get errCodePasswordBreached =>
      'Nenosiri hili limeonekana kwenye uvujaji wa data. Chagua jingine.';

  @override
  String get errCodePasswordReused =>
      'Nenosiri jipya lazima liwe tofauti na la sasa.';

  @override
  String get errCodeSessionExpired =>
      'Muda wako wa kuingia umeisha. Tafadhali ingia tena.';

  @override
  String get errCodeEmailNotConfirmed =>
      'Thibitisha barua pepe yako kwanza kwa nambari tuliyokutumia.';

  @override
  String get errCodeErrandUnavailable => 'Huduma ya kutumwa bado haipatikani.';

  @override
  String get errCodeUnknownCategory =>
      'Chagua aina ya mzigo kutoka kwenye orodha.';

  @override
  String get errCodeCategoryNotAllowed =>
      'Mzigo huu hauwezi kutumwa kupitia RideLink.';

  @override
  String get errCodeOrderNotEditable => 'Njia haiwezi kubadilishwa tena.';

  @override
  String get errCodeOrderNotCancellable => 'Oda hii haiwezi kughairiwa tena.';

  @override
  String get errCodeOrderUnavailable => 'Oda hii haipatikani tena.';

  @override
  String get errCodeNoActiveOffer => 'Hakuna ombi lililo wazi kwa oda hii.';

  @override
  String get errCodeOfferNotForYou =>
      'Ombi hili lilitumwa kwa mwendesha boda mwingine.';

  @override
  String get errCodeRiderNotAvailable =>
      'Mwendesha boda huyu hawezi kuchukua oda sasa. Chagua mwingine.';

  @override
  String get errCodeRiderNotFound => 'Mwendesha boda hakupatikana.';

  @override
  String get errCodeRiderAlreadyRegistered =>
      'Tayari umesajiliwa kama mwendesha boda.';

  @override
  String get errCodeRiderNotVerified =>
      'Ni waendesha boda waliothibitishwa pekee wanaoweza kuwa mtandaoni.';

  @override
  String get errCodeDocumentsMissing =>
      'Baadhi ya hati zinazohitajika hazipo au zimeisha muda.';

  @override
  String get errCodeRiderPaused =>
      'Umesimamishwa kwa muda baada ya kukosa kufika mahali pa kuchukua. Jaribu tena muda huo ukiisha.';

  @override
  String get errCodeLocationRequired =>
      'Tunahitaji mahali ulipo sasa. Washa eneo kisha ujaribu tena.';

  @override
  String get errCodeLocationStale =>
      'Mahali pako hapajasasishwa. Subiri kidogo kisha ujaribu tena.';

  @override
  String get errCodeTooFarFromPickup => 'Uko mbali sana na mahali pa kuchukua.';

  @override
  String get errCodePickupWindowPassed =>
      'Muda wa kufika mahali pa kuchukua umepita.';

  @override
  String get errCodeAlreadyArrived => 'Kufika kwako tayari kumerekodiwa.';

  @override
  String get errCodeValueOutOfRange =>
      'Thamani moja iko nje ya kiwango kinachoruhusiwa.';

  @override
  String get errCodeInvalidFileType => 'Aina hii ya faili haikubaliki.';

  @override
  String get errCodePhotoNotFound => 'Picha haipatikani.';

  @override
  String get errCodeAlreadyRated => 'Tayari umeitathmini oda hii.';

  @override
  String get errCodeNoAgreedPrice => 'Oda hii bado haina bei iliyokubaliwa.';

  @override
  String get errCodeReservedEventType =>
      'Ni RideLink pekee inayoweza kuongeza kipengele hiki kwenye rekodi.';

  @override
  String get errCodeInvalidMediaKind => 'Aina hii ya picha haikubaliki.';

  @override
  String get errCodeInvalidHash =>
      'Picha haikuweza kuthibitishwa. Tafadhali jaribu tena.';

  @override
  String get errCodeHashMismatch =>
      'Picha ilibadilika wakati wa kupakia. Tafadhali jaribu tena.';

  @override
  String get evidenceTitle => 'Rekodi ya ushahidi';

  @override
  String get evidenceIntro =>
      'Kila hatua ya oda hii inarekodiwa kwenye mnyororo usioweza kubadilishwa kwa siri. Unaweza kuhakikisha haujabadilishwa.';

  @override
  String get evidenceTimelineTitle => 'Mfuatano wa matukio';

  @override
  String get evidenceEmpty => 'Bado hakuna kilichorekodiwa.';

  @override
  String get evidenceLoadFailed => 'Imeshindikana kupakia rekodi ya ushahidi.';

  @override
  String get evidenceVerifyButton => 'Thibitisha rekodi';

  @override
  String get evidenceVerifyAgain => 'Thibitisha tena';

  @override
  String get evidenceVerifyFailed => 'Imeshindikana kukagua rekodi kwa sasa.';

  @override
  String get evidenceIntactTitle => 'Rekodi iko salama';

  @override
  String evidenceIntactBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Matukio $count yamekaguliwa. Hakuna kilichobadilishwa.',
      one: 'Tukio 1 limekaguliwa. Hakuna kilichobadilishwa.',
    );
    return '$_temp0';
  }

  @override
  String get evidenceTamperedTitle => 'Rekodi haijathibitishwa';

  @override
  String evidenceTamperedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Matukio $count yamekaguliwa. Mnyororo haulingani, hivyo huenda rekodi hii imebadilishwa.',
      one: 'Tukio 1 limekaguliwa. Mnyororo haulingani, hivyo huenda rekodi hii imebadilishwa.',
    );
    return '$_temp0';
  }

  @override
  String evidenceHash(String hash) {
    return 'Hashi $hash';
  }

  @override
  String get evidenceOpenPhoto => 'Fungua picha';

  @override
  String get evidenceActorYou => 'Wewe';

  @override
  String get evidenceActorRider => 'Mwendesha boda';

  @override
  String get evidenceActorSender => 'Mteja';

  @override
  String get evidenceActorPassenger => 'Abiria';

  @override
  String get evidenceActorOtherParty => 'Upande mwingine';

  @override
  String get evidenceActorRideLink => 'RideLink';

  @override
  String get evidencePickupPhoto => 'Picha ya kuchukua';

  @override
  String get evidenceHandoverPhoto => 'Picha ya kukabidhi';

  @override
  String get evidenceDropoffPhoto => 'Picha ya kufikisha';

  @override
  String get evidenceItemPhoto => 'Picha ya mzigo';

  @override
  String get evidencePickupPhotoHint => 'Piga picha ya mzigo unapouchukua.';

  @override
  String get evidencePickupPhotoHintRide => 'Piga picha mahali pa kuchukua.';

  @override
  String get evidenceHandoverPhotoHint => 'Piga picha ya mzigo unapoukabidhi.';

  @override
  String get evidenceHandoverPhotoHintRide => 'Piga picha mahali pa kufikisha.';

  @override
  String get evidenceItemPhotoHint =>
      'Ongeza picha ya mzigo kabla mwendesha boda hajauchukua.';

  @override
  String get evidenceTakePhoto => 'Piga picha';

  @override
  String get evidenceRetake => 'Piga upya';

  @override
  String get evidenceUploading => 'Inapakia picha...';

  @override
  String get evidenceUploadFailed =>
      'Imeshindikana kupakia picha. Angalia mtandao kisha ujaribu tena.';

  @override
  String get evidencePhotoAdded => 'Picha imeongezwa kwenye rekodi ya ushahidi';

  @override
  String get evidenceEventPaymentRequested => 'Malipo yameombwa';

  @override
  String get evidenceEventCashSent => 'Pesa taslimu imewekwa alama imelipwa';

  @override
  String get evidenceEventCashReceived => 'Pesa taslimu imepokelewa';

  @override
  String get evidenceEventCashDisputed =>
      'Imeripotiwa pesa taslimu haijapokelewa';

  @override
  String get optionalLabel => 'Si lazima';

  @override
  String get rateRiderTitle => 'Mtathmini mwendesha boda wako';

  @override
  String get rateSenderTitle => 'Mtathmini mteja';

  @override
  String get ratePassengerTitle => 'Mtathmini abiria wako';

  @override
  String get rateBody =>
      'Ilikuwaje? Tathmini yako inasaidia RideLink kuaminika.';

  @override
  String ratingStarsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nyota $count',
      one: 'Nyota 1',
    );
    return '$_temp0';
  }

  @override
  String get ratingCommentLabel => 'Maoni';

  @override
  String get ratingCommentHint => 'Si lazima';

  @override
  String get ratingSubmit => 'Tuma tathmini';

  @override
  String get ratingSkip => 'Ruka';

  @override
  String get ratingThanks => 'Asante kwa tathmini yako.';

  @override
  String get ratingFailed =>
      'Imeshindikana kuhifadhi tathmini yako. Tafadhali jaribu tena.';

  @override
  String get yourRating => 'Tathmini yako';

  @override
  String get notRatedYet => 'Bado hujaitathmini oda hii.';

  @override
  String get rateButton => 'Tathmini';

  @override
  String get notificationsTitle => 'Arifa';

  @override
  String get notificationsEmpty => 'Bado hakuna arifa.';

  @override
  String get notificationsLoadFailed => 'Imeshindikana kupakia arifa.';

  @override
  String get notifPaymentRequestedTitle => 'Malipo yameombwa';

  @override
  String notifPaymentRequestedBody(String amount) {
    return 'Mwendesha boda wako ameomba malipo. Lipa $amount taslimu.';
  }

  @override
  String get notifPaymentRequestedBodyNoAmount =>
      'Mwendesha boda wako ameomba malipo. Lipa kiasi kilichokubaliwa taslimu.';

  @override
  String get notifPaymentSentTitle => 'Malipo ya taslimu yametumwa';

  @override
  String notifPaymentSentBody(String amount) {
    return 'Mteja anasema amelipa $amount. Thibitisha ukishapokea pesa.';
  }

  @override
  String get notifPaymentSentBodyNoAmount =>
      'Mteja anasema amelipa. Thibitisha ukishapokea pesa.';

  @override
  String get notifPaymentConfirmedTitle => 'Malipo yamethibitishwa';

  @override
  String notifPaymentConfirmedBody(String amount) {
    return 'Mwendesha boda wako amethibitisha kupokea $amount taslimu.';
  }

  @override
  String get notifPaymentConfirmedBodyNoAmount =>
      'Mwendesha boda wako amethibitisha kupokea malipo yako ya taslimu.';

  @override
  String get notifPaymentUnresolvedTitle => 'Malipo hayajatatuliwa';

  @override
  String get notifPaymentUnresolvedBody =>
      'Mwendesha boda ameripoti kuwa pesa taslimu haijapokelewa. RideLink itakagua oda hii.';

  @override
  String get notifPickupArrivedTitle => 'Mwendesha boda wako amefika';

  @override
  String get notifPickupArrivedBody =>
      'Mwendesha boda wako yuko mahali pa kuchukua.';

  @override
  String get notifPickupTimeoutTitle =>
      'Mwendesha boda wako hakufika kwa wakati';

  @override
  String get notifPickupTimeoutBody =>
      'Oda imeghairiwa. Unaweza kuchagua mwendesha boda mwingine.';

  @override
  String get notifPickupTimeoutRiderTitle => 'Muda wa kuchukua umepita';

  @override
  String get notifPickupTimeoutRiderBody =>
      'Oda imeghairiwa kwa sababu hukufika mahali pa kuchukua kwa wakati. Kukosa kufika kunahesabiwa kuelekea kusimamishwa kwa muda.';

  @override
  String get notifReceiverLocationTitle => 'Mpokeaji ameshiriki mahali alipo';

  @override
  String get notifReceiverLocationBody =>
      'Mpokeaji ameweka alama mahali hasa pa kufikisha. Fungua oda kuiona.';

  @override
  String notifDocumentExpiringTitle(String doc, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$doc yako inaisha muda baada ya siku $days',
      one: '$doc yako inaisha muda kesho',
      zero: '$doc yako inaisha muda leo',
    );
    return '$_temp0';
  }

  @override
  String notifDocumentExpiringBody(String date) {
    return 'Pakia hati mpya kabla ya $date ili uendelee kupokea oda.';
  }

  @override
  String notifDocumentExpiredTitle(String doc) {
    return '$doc yako imeisha muda';
  }

  @override
  String get notifDocumentExpiredBody =>
      'Huwezi kuwa mtandaoni hadi hati mpya halali iidhinishwe.';

  @override
  String get menuHistory => 'Historia ya oda';

  @override
  String get menuProfile => 'Wasifu';

  @override
  String get profileTitle => 'Wasifu';

  @override
  String get profileLoadFailed => 'Imeshindikana kupakia wasifu wako.';

  @override
  String get profileSave => 'Hifadhi mabadiliko';

  @override
  String get profileSaved => 'Jina lako limesasishwa.';

  @override
  String get profileSaveFailed =>
      'Imeshindikana kuhifadhi jina lako. Tafadhali jaribu tena.';

  @override
  String get profileNameShownAs =>
      'Wengine wanaona jina lako la kwanza na herufi ya kwanza ya jina la mwisho, kama \"Moses O.\"';

  @override
  String get profileNameLocked =>
      'Jina lako linalingana na kitambulisho chako kilichothibitishwa, hivyo haliwezi kubadilishwa hapa. Ili kulibadilisha, wasiliana na huduma kwa wateja ya RideLink.';

  @override
  String get profileLanguage => 'Lugha';

  @override
  String get profileLanguageValue => 'Inafuata lugha ya simu yako';

  @override
  String get historyTitle => 'Historia ya oda';

  @override
  String get historyRiderTitle => 'Historia ya safari';

  @override
  String get historyEmpty => 'Bado hakuna oda.';

  @override
  String get historyLoadFailed => 'Imeshindikana kupakia oda zako.';

  @override
  String historyFrom(String place) {
    return 'Kutoka $place';
  }

  @override
  String get orderDetailTitle => 'Maelezo ya oda';

  @override
  String get orderLoadFailed => 'Imeshindikana kupakia oda hii.';

  @override
  String get openLiveOrder => 'Fungua oda inayoendelea';

  @override
  String get detailRider => 'Mwendesha boda';

  @override
  String get detailSender => 'Mteja';

  @override
  String get detailPassenger => 'Abiria';

  @override
  String get statusCreated => 'Rasimu';

  @override
  String get statusOffered => 'Inasubiri mwendesha boda';

  @override
  String get statusAccepted => 'Mwendesha boda yuko njiani';

  @override
  String get statusInTransit => 'Njiani';

  @override
  String get statusArrived => 'Mahali pa kufikisha';

  @override
  String get statusPayment => 'Malipo';

  @override
  String get statusPaid => 'Imelipwa';

  @override
  String get statusHandedOver => 'Imekabidhiwa';

  @override
  String get statusDroppedOff => 'Amefikishwa';

  @override
  String get statusCompleted => 'Imekamilika';

  @override
  String get statusCancelled => 'Imeghairiwa';

  @override
  String get statusExpired => 'Muda umeisha';

  @override
  String get statusPaymentFailed => 'Malipo yameshindikana';

  @override
  String get statusUnresolved => 'Inakaguliwa';

  @override
  String get shareWithReceiver => 'Shiriki na mpokeaji';

  @override
  String get shareWithReceiverNote =>
      'Mpokeaji anaweza kufuatilia mzigo na kuweka alama mahali hasa alipo kwa ajili ya mwendesha boda.';

  @override
  String receiverShareMessage(String url) {
    return 'Mzigo wako wa RideLink uko njiani. Ufuatilie na umwonyeshe mwendesha boda mahali hasa ulipo hapa: $url';
  }

  @override
  String get receiverLinkFailed =>
      'Imeshindikana kutengeneza kiungo cha mpokeaji. Tafadhali jaribu tena.';

  @override
  String get receiverSpotTitle => 'Mpokeaji ameweka alama mahali hasa alipo';

  @override
  String receiverSpotNote(String note) {
    return 'Maelezo: $note';
  }

  @override
  String get navigateToPickup => 'Elekezwa mahali pa kuchukua';

  @override
  String get navigateToDropoff => 'Elekezwa mahali pa kufikisha';

  @override
  String get navigateToReceiver => 'Elekezwa mahali pa mpokeaji';

  @override
  String get navigateFailed =>
      'Imeshindikana kufungua Google Maps kwenye simu hii.';

  @override
  String senderIs(String name) {
    return 'Mteja: $name';
  }

  @override
  String passengerIs(String name) {
    return 'Abiria: $name';
  }

  @override
  String get switchMidJobTitle => 'Maliza kazi yako kwanza';

  @override
  String get switchMidJobBody =>
      'Unaweza kubadili kutuma kazi hii ikishakamilika.';

  @override
  String get switchGoOfflineTitle => 'Uzime mtandao ili ubadili?';

  @override
  String get switchGoOfflineBody => 'Hutapokea maombi ukiwa unatuma.';

  @override
  String get switchGoOfflineConfirm => 'Zima mtandao';

  @override
  String get switchStayOnline => 'Baki mtandaoni';

  @override
  String get switchGoOfflineFailed =>
      'Imeshindikana kuzima mtandao. Tafadhali jaribu tena.';

  @override
  String get riderRunningLate => 'Mwendesha boda wako amechelewa';

  @override
  String get jobRunningLate => 'Umechelewa';

  @override
  String get jobRunningLateBody =>
      'Muda wa kuchukua umepita. RideLink itaghairi oda hii hivi karibuni.';

  @override
  String get jobPassengerPickedUp => 'Abiria amepanda';

  @override
  String get actionPassengerPickedUp => 'Abiria amepanda';

  @override
  String get jobAtPickupNoteRide =>
      'Kufika kumerekodiwa. Abiria akishapanda, bonyeza Abiria amepanda.';

  @override
  String get jobAtDropoffBodyRide =>
      'Omba malipo kutoka kwa abiria kabla hajashuka.';

  @override
  String jobWaitingForPassenger(String amount) {
    return 'Unasubiri abiria alipe $amount taslimu.';
  }

  @override
  String jobPassengerPaid(String amount) {
    return 'Abiria anasema amelipa $amount taslimu. Thibitisha ukishapokea.';
  }

  @override
  String get jobPaidBodyRide =>
      'Malipo yamethibitishwa. Weka alama abiria amefikishwa hapa chini.';

  @override
  String get jobPassengerDroppedOff => 'Abiria amefikishwa';

  @override
  String get actionPassengerDroppedOff => 'Abiria amefikishwa';

  @override
  String get jobRideComplete => 'Safari imekamilika';

  @override
  String get actionCompleteRide => 'Kamilisha safari';

  @override
  String get jobCancelledByPassenger => 'Abiria ameghairi safari hii.';

  @override
  String get errCodeEvidencePhotoRequired => 'Piga picha inayohitajika kwanza.';

  @override
  String get errCodeEvidencePickupPhotoRequired =>
      'Piga picha ya kuchukua kabla ya kuthibitisha kuwa umechukua mzigo.';

  @override
  String get errCodeEvidenceHandoverPhotoRequired =>
      'Piga picha ya kukabidhi kabla ya kuthibitisha kuwa umekabidhi mzigo.';

  @override
  String get jobPickupPhotoRequired => 'Piga picha ya kuchukua ili kuendelea.';

  @override
  String get jobHandoverPhotoRequired =>
      'Piga picha ya kukabidhi ili kuendelea.';
}
