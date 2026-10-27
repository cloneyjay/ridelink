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

  @override
  String get menuTooltip => 'Menu';

  @override
  String get menuSwitchToRiding => 'Switch to riding';

  @override
  String get menuSwitchToSending => 'Switch to sending';

  @override
  String get menuBecomeRider => 'Become a rider';

  @override
  String get menuRiderStatusError => 'Couldn\'t check your rider account.';

  @override
  String get menuSignOut => 'Sign out';

  @override
  String get riderHomeTitle => 'Rider mode';

  @override
  String get homeWhatDoYouNeed => 'What do you need?';

  @override
  String get serviceDelivery => 'Delivery';

  @override
  String get serviceDeliverySubtitle => 'Send a parcel';

  @override
  String get serviceRide => 'Ride';

  @override
  String get serviceRideSubtitle => 'Get a boda ride';

  @override
  String get mapUnavailable => 'Map preview unavailable';

  @override
  String get locationDeniedTitle => 'Location is off';

  @override
  String get locationDeniedBody =>
      'Allow location so we can show where you are. You can still book by searching for places.';

  @override
  String get locationServiceOffBody =>
      'Turn on your phone\'s location to show where you are. You can still book by searching for places.';

  @override
  String get locationUnavailableBody =>
      'We couldn\'t find your location. You can still book by searching for places.';

  @override
  String get locationAllow => 'Allow location';

  @override
  String get locationOpenSettings => 'Open settings';

  @override
  String get locationTurnOn => 'Turn on location';

  @override
  String get newDeliveryTitle => 'New delivery';

  @override
  String get newRideTitle => 'New ride';

  @override
  String get pickupLabel => 'Pickup';

  @override
  String get dropoffLabel => 'Drop-off';

  @override
  String get choosePickup => 'Choose pickup';

  @override
  String get chooseDropoff => 'Choose drop-off';

  @override
  String get itemSectionTitle => 'Item';

  @override
  String get categoryLabel => 'Category';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get weightLabel => 'Weight in kg (optional)';

  @override
  String get valueBandLabel => 'Item value';

  @override
  String get valueBandCapNote =>
      'Items worth more than KES 10,000 can\'t be booked.';

  @override
  String get receiverSectionTitle => 'Receiver';

  @override
  String get receiverNameLabel => 'Receiver\'s name';

  @override
  String get findRidersButton => 'Find riders';

  @override
  String get errorPickupRequired => 'Choose a pickup point';

  @override
  String get errorDropoffRequired => 'Choose a drop-off point';

  @override
  String get errorReceiverRequired => 'Enter the receiver\'s name';

  @override
  String get errorCategoryRequired => 'Choose a category';

  @override
  String get errorDescriptionRequired => 'Describe the item';

  @override
  String get errorWeightInvalid => 'Enter a weight above 0';

  @override
  String get errorValueBandRequired => 'Choose the item\'s value';

  @override
  String get createOrderFailed => 'Couldn\'t create your order. Try again.';

  @override
  String get categoriesLoadFailed => 'Couldn\'t load item categories.';

  @override
  String get valueBandUnder500 => 'Under KES 500';

  @override
  String get valueBand500To2000 => 'KES 500–2,000';

  @override
  String get valueBand2000To5000 => 'KES 2,000–5,000';

  @override
  String get valueBand5000To10000 => 'KES 5,000–10,000';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryFragile => 'Fragile items';

  @override
  String get categoryMedication => 'Medication';

  @override
  String get categoryCash => 'Cash';

  @override
  String get categoryAlcohol => 'Alcohol';

  @override
  String get categoryOther => 'Other';

  @override
  String get placeSearchHint => 'Search for a place';

  @override
  String get placeSearchMinChars => 'Type at least 2 letters';

  @override
  String get placeSearchNoResults => 'No places found';

  @override
  String get placeSearchUnavailable =>
      'Location search is unavailable right now. Try again later.';

  @override
  String get placeSearchFailed => 'Couldn\'t search. Check your connection.';

  @override
  String get clearSearch => 'Clear';

  @override
  String get riderListTitle => 'Choose a rider';

  @override
  String get sortByPrice => 'Price';

  @override
  String get sortByDistance => 'Distance';

  @override
  String tripDistance(String distance) {
    return 'Trip $distance';
  }

  @override
  String get distanceEstimatedNote => 'Distance is estimated';

  @override
  String get noRidersTitle => 'No riders nearby right now';

  @override
  String get noRidersBody => 'Try again in a moment.';

  @override
  String get ridersLoadFailed => 'Couldn\'t load riders.';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String ratingCount(int count) {
    return '$count ratings';
  }

  @override
  String onTimePercent(int percent) {
    return '$percent% on time';
  }

  @override
  String completedJobs(int count) {
    return '$count completed';
  }

  @override
  String pickupDistanceAway(String distance) {
    return '$distance from pickup';
  }

  @override
  String arrivesWithin(int minutes) {
    return 'Arrives within $minutes min';
  }

  @override
  String get editRoute => 'Edit route';

  @override
  String get offerDeclinedMessage =>
      'The rider declined. Choose another rider.';

  @override
  String get offerExpiredMessage =>
      'The rider didn\'t respond in time. Choose another rider.';

  @override
  String get riderProfileTitle => 'Rider profile';

  @override
  String get statRating => 'Rating';

  @override
  String get statOnTime => 'On time';

  @override
  String get statCompleted => 'Completed jobs';

  @override
  String get statPickup => 'Pickup';

  @override
  String get priceForThisTrip => 'Price for this trip';

  @override
  String get breakdownBaseFare => 'Base fare';

  @override
  String breakdownPlatform(String distance) {
    return 'Platform rate for $distance';
  }

  @override
  String breakdownRider(String distance) {
    return 'Rider rate beyond $distance';
  }

  @override
  String breakdownRiderDetail(String distance, String rate) {
    return '$distance at $rate per km';
  }

  @override
  String get breakdownMinimumFare => 'Minimum fare applies to this trip';

  @override
  String get breakdownTotal => 'Total';

  @override
  String get requestButton => 'Request';

  @override
  String get quoteTitle => 'Price quote';

  @override
  String get youPay => 'You pay';

  @override
  String get quoteFinalNote =>
      'This price is final. It is locked once the rider accepts.';

  @override
  String get sendRequestButton => 'Send request';

  @override
  String get sendRequestFailed => 'Couldn\'t send the request. Try again.';

  @override
  String waitingTitle(String name) {
    return 'Waiting for $name';
  }

  @override
  String get waitingBody =>
      'The rider has a short time to accept your request.';

  @override
  String get waitingChecking => 'Checking the rider\'s response…';

  @override
  String get secondsLabel => 'seconds';

  @override
  String get cancelRequestButton => 'Cancel request';

  @override
  String get cancelConfirmTitle => 'Cancel this request?';

  @override
  String get cancelConfirmBody => 'Your order will be cancelled.';

  @override
  String get cancelConfirmYes => 'Cancel order';

  @override
  String get cancelConfirmNo => 'Keep waiting';

  @override
  String get cancelFailed =>
      'Couldn\'t cancel. The rider may have already responded.';

  @override
  String get orderCancelledMessage => 'Your order was cancelled.';

  @override
  String get backToHome => 'Back to home';

  @override
  String get editRouteTitle => 'Edit route';

  @override
  String get saveRouteButton => 'Save route';

  @override
  String get routeUpdateFailed => 'Couldn\'t update the route. Try again.';

  @override
  String get routeLocked => 'This route can no longer be changed.';

  @override
  String get closeTooltip => 'Close';

  @override
  String get riderLoadFailed => 'Couldn\'t load your rider profile.';

  @override
  String get registerIntro =>
      'Register your boda boda to start receiving delivery and ride requests. Next you will upload your documents for review.';

  @override
  String get vehicleLabel => 'Vehicle';

  @override
  String get vehicleBodaBoda => 'Boda boda';

  @override
  String get vehicleOnlyBoda => 'Boda boda is the only vehicle at launch.';

  @override
  String get plateLabel => 'Number plate';

  @override
  String get plateHint => 'e.g. KMFA 123B';

  @override
  String get plateInvalid => 'Enter 3 to 12 letters, digits or spaces';

  @override
  String get registerButton => 'Register';

  @override
  String get registerFailed => 'Couldn\'t register. Try again.';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsIntro =>
      'RideLink staff review each document. You can go online once all of them are approved.';

  @override
  String documentsProgress(int done, int total) {
    return '$done of $total uploaded';
  }

  @override
  String get documentsContinue => 'Continue';

  @override
  String get documentsUploadAll => 'Upload every document to continue.';

  @override
  String get documentsLoadFailed => 'Couldn\'t load your documents.';

  @override
  String get docRiderPhoto => 'Rider photo';

  @override
  String get docRiderPhotoHint =>
      'A clear photo of your face. Senders see it before and during a job.';

  @override
  String get docNationalId => 'National ID';

  @override
  String get docNationalIdHint => 'Front of your national ID card.';

  @override
  String get docDrivingLicence => 'Driving licence';

  @override
  String get docDrivingLicenceHint =>
      'Motorcycle licence (Class A), with its expiry date.';

  @override
  String get docPoliceClearance => 'Police clearance certificate';

  @override
  String get docPoliceClearanceHint =>
      'DCI good conduct certificate, with its issue date. Valid for 12 months.';

  @override
  String get docPsvInsurance => 'PSV insurance';

  @override
  String get docPsvInsuranceHint =>
      'Your PSV insurance certificate, with its expiry date.';

  @override
  String get docLogbook => 'Logbook or sale agreement';

  @override
  String get docLogbookHint => 'Proof that you own or may use the bike.';

  @override
  String get docBikeRearPhoto => 'Bike rear photo';

  @override
  String get docBikeRearPhotoHint =>
      'A photo of the back of your bike with the number plate visible.';

  @override
  String get docStatusMissing => 'Not uploaded';

  @override
  String get docStatusPending => 'In review';

  @override
  String get docStatusApproved => 'Approved';

  @override
  String get docStatusRejected => 'Rejected';

  @override
  String docRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String docExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String docIssuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String get docPendingStillValid =>
      'Your approved document stays valid while this one is reviewed.';

  @override
  String get docUploadAction => 'Upload';

  @override
  String get docReplaceAction => 'Replace';

  @override
  String docUploaded(String name) {
    return '$name uploaded';
  }

  @override
  String get docFormatsImage => 'JPEG or PNG photo, up to 10 MB.';

  @override
  String get docFormatsAny => 'JPEG or PNG photo, or a PDF, up to 10 MB.';

  @override
  String get docChooseExpiry => 'Choose expiry date';

  @override
  String get docChooseIssued => 'Choose issue date';

  @override
  String get docTakePhoto => 'Take photo';

  @override
  String get docChooseGallery => 'Choose from gallery';

  @override
  String get docChooseFile => 'Choose PDF or image file';

  @override
  String get docUploadButton => 'Upload';

  @override
  String get docTooLarge => 'File must be 10 MB or smaller.';

  @override
  String get docImageOnly => 'This document must be a photo (JPEG or PNG).';

  @override
  String get docDateRequired => 'Choose the date first.';

  @override
  String get docPickFailed => 'Couldn\'t open the file. Try again.';

  @override
  String get docUploadFailed =>
      'Couldn\'t upload. Check your connection and try again.';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationPendingTitle => 'Your documents are being reviewed';

  @override
  String get verificationPendingBody =>
      'We\'ll notify you when the review is complete.';

  @override
  String get verificationApprovedTitle => 'You\'re approved';

  @override
  String get verificationApprovedBody =>
      'You can go online and start receiving requests.';

  @override
  String get verificationRejectedTitle => 'Some documents need attention';

  @override
  String get verificationRejectedBody =>
      'Check the reasons and upload new documents.';

  @override
  String get verificationIncompleteTitle => 'Finish uploading your documents';

  @override
  String get verificationIncompleteBody =>
      'Review starts once every document is uploaded.';

  @override
  String get goToRiderHome => 'Go to rider home';

  @override
  String get fixDocumentsButton => 'Upload documents';

  @override
  String get viewDocumentsButton => 'View documents';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get riderNotRegisteredTitle =>
      'You haven\'t registered as a rider yet';

  @override
  String get riderOnline => 'You\'re online';

  @override
  String get riderOffline => 'You\'re offline';

  @override
  String riderOnlineBody(String distance) {
    return 'Receiving requests with pickups within $distance';
  }

  @override
  String get riderOfflineBody =>
      'Go online to receive delivery and ride requests.';

  @override
  String riderSettingsSummary(String radius, String delivery, String ride) {
    return 'Pickup radius $radius · Delivery $delivery/km · Ride $ride/km';
  }

  @override
  String riderPlate(String plate) {
    return 'Boda boda $plate';
  }

  @override
  String get blockNotVerifiedTitle => 'Your account isn\'t approved yet';

  @override
  String get blockNotVerifiedBody =>
      'You can go online once RideLink approves your documents.';

  @override
  String get viewStatusButton => 'View status';

  @override
  String get blockDocumentsTitle => 'Documents need attention';

  @override
  String blockDocumentsBody(String documents) {
    return 'Renew or upload: $documents';
  }

  @override
  String get blockDocumentsBodyGeneric =>
      'One or more documents are missing or expired.';

  @override
  String get updateDocumentsButton => 'Update documents';

  @override
  String blockPausedTitle(String time) {
    return 'You\'re paused until $time';
  }

  @override
  String blockPausedMissedPickups(int count) {
    return 'After $count missed pickups in 24 hours you can\'t receive requests until then.';
  }

  @override
  String get blockPausedBody => 'You can\'t receive requests until then.';

  @override
  String get blockLocationTitle => 'Turn on location to go online';

  @override
  String get blockLocationBody =>
      'RideLink shares your location while you are online so senders can find you and pickups are recorded.';

  @override
  String get blockErrorTitle => 'Couldn\'t change your status';

  @override
  String get onlineNotificationTitle => 'You\'re online';

  @override
  String get onlineNotificationBody =>
      'RideLink is sharing your location for requests and pickups.';

  @override
  String get onlineNotificationChannel => 'Online status';

  @override
  String get riderOfferTitle => 'New request';

  @override
  String get riderOfferChecking => 'Time is up. Checking the request…';

  @override
  String get youEarn => 'You earn';

  @override
  String reachPickupWithin(int minutes) {
    return 'Reach pickup within $minutes min';
  }

  @override
  String get acceptButton => 'Accept';

  @override
  String get declineButton => 'Decline';

  @override
  String get acceptNeedsLocation =>
      'Turn on location to accept. Your location must be recent.';

  @override
  String get acceptFailed => 'Couldn\'t accept. Try again.';

  @override
  String get declineFailed => 'Couldn\'t decline. Try again.';

  @override
  String get riderOfferExpired => 'The request expired.';

  @override
  String get riderOfferDeclined => 'You declined the request.';

  @override
  String get riderOfferTaken => 'This request is no longer available.';

  @override
  String get riderOfferCancelled => 'The sender cancelled the request.';

  @override
  String get jobTitle => 'Current job';

  @override
  String get jobToPickup => 'Head to pickup';

  @override
  String get jobAtPickup => 'At pickup';

  @override
  String get jobAtPickupNote => 'Arrival recorded. Collect and tap Picked up.';

  @override
  String get jobPickedUp => 'Picked up';

  @override
  String get jobInTransit => 'On the way to drop-off';

  @override
  String get jobAtDropoff => 'At drop-off';

  @override
  String get jobAtDropoffBody =>
      'Request payment from the sender before handing over.';

  @override
  String get jobPayment => 'Payment';

  @override
  String get jobPaid => 'Payment received';

  @override
  String get jobPaidBody => 'Payment confirmed. Hand over, then mark it below.';

  @override
  String get jobHandedOver => 'Handed over';

  @override
  String get jobCompleted => 'Job complete';

  @override
  String jobCompletedBody(String amount) {
    return 'You earned $amount.';
  }

  @override
  String get jobCancelled => 'Job cancelled';

  @override
  String get jobCancelledBySender => 'The sender cancelled this order.';

  @override
  String get jobCancelledTimeout =>
      'The pickup window passed, so the order was cancelled.';

  @override
  String get jobCancelledByYou => 'You cancelled this order.';

  @override
  String get jobCancelledGeneric => 'This order was cancelled.';

  @override
  String get agreedPrice => 'Agreed price';

  @override
  String get reachPickupIn => 'Reach pickup in';

  @override
  String pickupDeadlineAt(String time) {
    return 'Deadline $time';
  }

  @override
  String get arrivalAutoNote =>
      'Arrival is recorded automatically when you are within 150 m of the pickup point.';

  @override
  String get headingToPickup => 'Heading to pickup';

  @override
  String get headingToDropoff => 'Heading to drop-off';

  @override
  String receiverIs(String name) {
    return 'Receiver: $name';
  }

  @override
  String get actionArrivedAtPickup => 'I\'ve arrived';

  @override
  String get actionPickedUp => 'Picked up';

  @override
  String get actionStartTrip => 'Start trip to drop-off';

  @override
  String get actionArrivedAtDropoff => 'Arrived at drop-off';

  @override
  String get actionRequestPayment => 'Request payment';

  @override
  String get actionHandOver => 'Mark handed over';

  @override
  String get actionComplete => 'Complete job';

  @override
  String get jobActionFailed => 'Couldn\'t update the job. Try again.';

  @override
  String get paymentReceivedButton => 'Payment received';

  @override
  String get paymentNotReceivedButton => 'Not paid';

  @override
  String get paymentNotReceivedConfirmTitle => 'Report this order as not paid?';

  @override
  String get paymentNotReceivedConfirmBody =>
      'The order goes to RideLink for review.';

  @override
  String get goBackButton => 'Go back';

  @override
  String get riderCancelButton => 'Cancel job';

  @override
  String get riderCancelTitle => 'Cancel this job?';

  @override
  String riderCancelWithinGrace(String time) {
    return 'You accepted less than 2 minutes ago, so cancelling now won\'t count toward a pause ($time left). It still shows in your cancellation record.';
  }

  @override
  String get riderCancelAfterGrace =>
      'More than 2 minutes have passed since you accepted, so this counts like a missed pickup. 3 in 24 hours pauses you.';

  @override
  String get riderCancelConfirm => 'Cancel job';

  @override
  String get riderCancelKeep => 'Keep job';

  @override
  String get doneButton => 'Done';

  @override
  String get paymentUnderReview => 'We\'re reviewing this payment';

  @override
  String get paymentUnderReviewRiderBody =>
      'You reported this order as not paid. RideLink will review this order.';

  @override
  String get trackingScreenTitle => 'Your order';

  @override
  String get trackingLoadFailed => 'Couldn\'t load your order.';

  @override
  String get trackingActionFailed => 'Couldn\'t update the order. Try again.';

  @override
  String riderArrivesIn(int minutes) {
    return 'Rider arrives in $minutes min';
  }

  @override
  String get riderArrivedAtPickup => 'Your rider has arrived';

  @override
  String get trackingOnTheWay => 'On the way to the drop-off';

  @override
  String get riderAtDropoff => 'Your rider is at the drop-off';

  @override
  String get delivered => 'Delivered';

  @override
  String get tripComplete => 'Trip complete';

  @override
  String get orderCancelledTimeout =>
      'The rider didn\'t reach pickup in time, so the order was cancelled.';

  @override
  String get orderCancelledByRider => 'The rider cancelled this order.';

  @override
  String get orderCancelledBySender => 'You cancelled this order.';

  @override
  String get stepAccepted => 'Accepted';

  @override
  String get stepAtPickup => 'At pickup';

  @override
  String get stepInTransit => 'In transit';

  @override
  String get stepPayment => 'Payment';

  @override
  String get stepDelivered => 'Delivered';

  @override
  String get stepDroppedOff => 'Dropped off';

  @override
  String get waitingForRiderConfirm =>
      'Waiting for your rider to confirm the payment';

  @override
  String paymentConfirmed(String amount) {
    return 'Payment of $amount confirmed';
  }

  @override
  String get viewTerms => 'View terms';

  @override
  String get termsTitle => 'Agreed terms';

  @override
  String get termsLockedNote =>
      'These terms were locked when the rider accepted.';

  @override
  String get termsPickupWindow => 'Pickup window';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String get senderCancelButton => 'Cancel order';

  @override
  String get senderCancelTitle => 'Cancel this order?';

  @override
  String get senderCancelBody =>
      'The rider has accepted and is on the way. Your order will be cancelled.';

  @override
  String get senderCancelKeep => 'Keep order';

  @override
  String get discardOrderTitle => 'Discard this order?';

  @override
  String get discardOrderBody => 'Your order will be cancelled.';

  @override
  String get discardOrderConfirm => 'Discard';

  @override
  String get discardOrderKeep => 'Keep order';

  @override
  String get discardOrderFailed => 'Couldn\'t discard the order. Try again.';

  @override
  String get activeOrderBanner => 'You have an order in progress';

  @override
  String get viewButton => 'View';

  @override
  String get settingsTitle => 'Pricing and settings';

  @override
  String get settingsDistanceSection => 'Distance';

  @override
  String get settingsPickupRadius => 'Pickup radius';

  @override
  String settingsPickupRadiusHelp(String max) {
    return 'How far you travel to collect. Up to $max.';
  }

  @override
  String get settingsMaxDistance => 'Platform-rate distance';

  @override
  String settingsMaxDistanceHelp(String min) {
    return 'Trips up to this distance use the platform price; your rate applies beyond it. At least $min.';
  }

  @override
  String get settingsRatesSection => 'Your rates';

  @override
  String get settingsRatesNote =>
      'Charged per km beyond your platform-rate distance.';

  @override
  String get settingsDeliveryRate => 'Delivery rate';

  @override
  String get settingsRideRate => 'Ride rate';

  @override
  String settingsRateRange(String min, String max) {
    return 'Between $min and $max per km';
  }

  @override
  String get settingsLoadSection => 'Load';

  @override
  String get settingsMaxWeight => 'Maximum parcel weight';

  @override
  String get settingsMaxWeightHelp => 'Heaviest parcel you will carry.';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsSaveFailed => 'Couldn\'t save. Try again.';

  @override
  String get settingsLoadFailed => 'Couldn\'t load your settings.';

  @override
  String get settingsRequired => 'Enter a value';

  @override
  String get settingsNotNumber => 'Enter a number';

  @override
  String get settingsMustBePositive => 'Enter a value above 0';

  @override
  String get settingsTooHigh => 'This value is too large';

  @override
  String settingsRadiusTooHigh(String max) {
    return 'At most $max';
  }

  @override
  String settingsDistanceTooLow(String min) {
    return 'At least $min';
  }

  @override
  String get unitKm => 'km';

  @override
  String get unitPerKm => 'KES/km';

  @override
  String get unitKg => 'kg';

  @override
  String get errCodeInvalidRequest =>
      'Some details aren\'t valid. Check them and try again.';

  @override
  String get errCodeUnauthorized =>
      'Your session has ended. Please sign in again.';

  @override
  String get errCodeForbidden => 'You don\'t have permission to do this.';

  @override
  String get errCodeNotFound =>
      'We couldn\'t find that. It may have been removed.';

  @override
  String get errCodeConflict =>
      'This was updated in the meantime. Showing the latest.';

  @override
  String get errCodeInvalidStatus =>
      'This order has moved on. Refresh and try again.';

  @override
  String get errCodeFileTooLarge =>
      'The file is too large. Use one under 10 MB.';

  @override
  String get errCodeInternalError =>
      'Something went wrong on our side. Please try again.';

  @override
  String get errCodeUpstreamUnavailable =>
      'A service we rely on isn\'t responding. Please try again.';

  @override
  String get errCodeServiceUnavailable =>
      'This isn\'t available right now. Please try again later.';

  @override
  String get errCodeInvalidName => 'Names must be 1 to 50 characters.';

  @override
  String get errCodeMissingFields => 'Fill in all required fields.';

  @override
  String get errCodePasswordBreached =>
      'This password has appeared in a data breach. Choose a different one.';

  @override
  String get errCodePasswordReused =>
      'Your new password must be different from the current one.';

  @override
  String get errCodeSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get errCodeEmailNotConfirmed =>
      'Confirm your email first with the code we sent you.';

  @override
  String get errCodeErrandUnavailable => 'Errands aren\'t available yet.';

  @override
  String get errCodeUnknownCategory => 'Choose an item category from the list.';

  @override
  String get errCodeCategoryNotAllowed =>
      'This item can\'t be sent with RideLink.';

  @override
  String get errCodeOrderNotEditable => 'The route can\'t be changed any more.';

  @override
  String get errCodeOrderNotCancellable =>
      'This order can no longer be cancelled.';

  @override
  String get errCodeOrderUnavailable => 'This order is no longer available.';

  @override
  String get errCodeNoActiveOffer => 'There\'s no open request on this order.';

  @override
  String get errCodeOfferNotForYou => 'This request was sent to another rider.';

  @override
  String get errCodeRiderNotAvailable =>
      'This rider can\'t take the order right now. Choose another rider.';

  @override
  String get errCodeRiderNotFound => 'Rider not found.';

  @override
  String get errCodeRiderAlreadyRegistered =>
      'You\'re already registered as a rider.';

  @override
  String get errCodeRiderNotVerified => 'Only verified riders can go online.';

  @override
  String get errCodeDocumentsMissing =>
      'Some required documents are missing or expired.';

  @override
  String get errCodeRiderPaused =>
      'You\'re paused after missed pickups. Try again after the pause ends.';

  @override
  String get errCodeLocationRequired =>
      'We need your current location. Turn on location and try again.';

  @override
  String get errCodeLocationStale =>
      'Your location is out of date. Wait a moment and try again.';

  @override
  String get errCodeTooFarFromPickup =>
      'You\'re too far from the pickup point.';

  @override
  String get errCodePickupWindowPassed => 'The pickup time has passed.';

  @override
  String get errCodeAlreadyArrived => 'Your arrival is already recorded.';

  @override
  String get errCodeValueOutOfRange => 'A value is outside the allowed range.';

  @override
  String get errCodeInvalidFileType => 'This file type isn\'t accepted.';

  @override
  String get errCodePhotoNotFound => 'Photo not available.';

  @override
  String get errCodeAlreadyRated => 'You\'ve already rated this order.';

  @override
  String get errCodeNoAgreedPrice => 'This order has no agreed price yet.';

  @override
  String get errCodeReservedEventType =>
      'Only RideLink can add this entry to the record.';

  @override
  String get errCodeInvalidMediaKind => 'This photo type isn\'t accepted.';

  @override
  String get errCodeInvalidHash =>
      'The photo couldn\'t be verified. Please try again.';

  @override
  String get errCodeHashMismatch =>
      'The photo changed during upload. Please try again.';

  @override
  String get evidenceTitle => 'Evidence record';

  @override
  String get evidenceIntro =>
      'Every step of this order is recorded in a tamper-evident chain. Anyone can check it has not been changed.';

  @override
  String get evidenceTimelineTitle => 'Timeline';

  @override
  String get evidenceEmpty => 'Nothing has been recorded yet.';

  @override
  String get evidenceLoadFailed => 'Couldn\'t load the evidence record.';

  @override
  String get evidenceVerifyButton => 'Verify record';

  @override
  String get evidenceVerifyAgain => 'Verify again';

  @override
  String get evidenceVerifyFailed => 'Couldn\'t check the record right now.';

  @override
  String get evidenceIntactTitle => 'Record intact';

  @override
  String evidenceIntactBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events checked. Nothing has been changed.',
      one: '1 event checked. Nothing has been changed.',
    );
    return '$_temp0';
  }

  @override
  String get evidenceTamperedTitle => 'Record does not verify';

  @override
  String evidenceTamperedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count events checked. The chain does not match, so this record may have been altered.',
      one: '1 event checked. The chain does not match, so this record may have been altered.',
    );
    return '$_temp0';
  }

  @override
  String evidenceHash(String hash) {
    return 'Hash $hash';
  }

  @override
  String get evidenceOpenPhoto => 'Open photo';

  @override
  String get evidenceActorYou => 'You';

  @override
  String get evidenceActorRider => 'Rider';

  @override
  String get evidenceActorSender => 'Sender';

  @override
  String get evidenceActorPassenger => 'Passenger';

  @override
  String get evidenceActorOtherParty => 'Other party';

  @override
  String get evidenceActorRideLink => 'RideLink';

  @override
  String get evidencePickupPhoto => 'Pickup photo';

  @override
  String get evidenceHandoverPhoto => 'Handover photo';

  @override
  String get evidenceDropoffPhoto => 'Drop-off photo';

  @override
  String get evidenceItemPhoto => 'Item photo';

  @override
  String get evidencePickupPhotoHint =>
      'Take a photo of the item as you collect it.';

  @override
  String get evidenceHandoverPhotoHint =>
      'Take a photo of the item as you hand it over.';

  @override
  String get evidenceItemPhotoHint =>
      'Add a photo of the item before the rider collects it.';

  @override
  String get evidenceTakePhoto => 'Take photo';

  @override
  String get evidenceRetake => 'Retake';

  @override
  String get evidenceUploading => 'Uploading photo...';

  @override
  String get evidenceUploadFailed =>
      'Couldn\'t upload the photo. Check your connection and try again.';

  @override
  String get evidencePhotoAdded => 'Photo added to the evidence record';

  @override
  String get evidenceEventPaymentRequested => 'Payment requested';

  @override
  String get evidenceEventCashSent => 'Cash marked as paid';

  @override
  String get evidenceEventCashReceived => 'Cash received';

  @override
  String get evidenceEventCashDisputed => 'Cash reported not received';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get rateRiderTitle => 'Rate your rider';

  @override
  String get rateSenderTitle => 'Rate the sender';

  @override
  String get ratePassengerTitle => 'Rate your passenger';

  @override
  String get rateBody =>
      'How did it go? Your rating helps keep RideLink trustworthy.';

  @override
  String ratingStarsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get ratingCommentLabel => 'Comment';

  @override
  String get ratingCommentHint => 'Optional';

  @override
  String get ratingSubmit => 'Submit rating';

  @override
  String get ratingSkip => 'Skip';

  @override
  String get ratingThanks => 'Thanks for your rating.';

  @override
  String get ratingFailed => 'Couldn\'t save your rating. Please try again.';

  @override
  String get yourRating => 'Your rating';

  @override
  String get notRatedYet => 'You haven\'t rated this order.';

  @override
  String get rateButton => 'Rate';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsLoadFailed => 'Couldn\'t load notifications.';

  @override
  String get notifPaymentRequestedTitle => 'Payment requested';

  @override
  String notifPaymentRequestedBody(String amount) {
    return 'Your rider has arrived. Pay $amount by cash or M-Pesa.';
  }

  @override
  String get notifPaymentRequestedBodyNoAmount =>
      'Your rider has arrived. Pay the agreed amount by cash or M-Pesa.';

  @override
  String get notifPaymentSentTitle => 'Cash payment sent';

  @override
  String notifPaymentSentBody(String amount) {
    return 'The sender says they have paid $amount. Confirm when you have the cash.';
  }

  @override
  String get notifPaymentSentBodyNoAmount =>
      'The sender says they have paid. Confirm when you have the cash.';

  @override
  String get notifPaymentConfirmedTitle => 'Payment confirmed';

  @override
  String get notifPaymentConfirmedBody =>
      'Payment confirmed. Your order is complete.';

  @override
  String get notifPaymentUnresolvedTitle => 'Payment unresolved';

  @override
  String get notifPaymentUnresolvedBody =>
      'You reported this order as not paid. RideLink will review this order.';

  @override
  String get notifPickupArrivedTitle => 'Your rider has arrived';

  @override
  String get notifPickupArrivedBody => 'Your rider is at the pickup point.';

  @override
  String get notifPickupTimeoutTitle =>
      'Your rider didn\'t reach pickup in time';

  @override
  String get notifPickupTimeoutBody =>
      'The order was cancelled. You can book another rider.';

  @override
  String get notifPickupTimeoutRiderTitle => 'Pickup window missed';

  @override
  String get notifPickupTimeoutRiderBody =>
      'The order was cancelled because you didn\'t reach the pickup in time. Missed pickups count toward a pause.';

  @override
  String get notifReceiverLocationTitle => 'Receiver shared their location';

  @override
  String get notifReceiverLocationBody =>
      'The receiver pinned their exact drop-off spot. Open the order to see it.';

  @override
  String notifDocumentExpiringTitle(String doc, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Your $doc expires in $days days',
      one: 'Your $doc expires tomorrow',
      zero: 'Your $doc expires today',
    );
    return '$_temp0';
  }

  @override
  String notifDocumentExpiringBody(String date) {
    return 'Upload a renewed document before $date to keep receiving orders.';
  }

  @override
  String notifDocumentExpiredTitle(String doc) {
    return 'Your $doc has expired';
  }

  @override
  String get notifDocumentExpiredBody =>
      'You can\'t go online until a valid replacement is approved.';

  @override
  String get menuHistory => 'Order history';

  @override
  String get menuProfile => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLoadFailed => 'Couldn\'t load your profile.';

  @override
  String get profileSave => 'Save changes';

  @override
  String get profileSaved => 'Your name was updated.';

  @override
  String get profileSaveFailed => 'Couldn\'t save your name. Please try again.';

  @override
  String get profileNameShownAs =>
      'Others see your first name and last initial, like \"Moses O.\"';

  @override
  String get profileNameLocked =>
      'Your name matches your verified ID, so it can\'t be changed here. To change it, contact RideLink support.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageValue => 'Follows your phone\'s language';

  @override
  String get historyTitle => 'Order history';

  @override
  String get historyRiderTitle => 'Trip history';

  @override
  String get historyEmpty => 'No orders yet.';

  @override
  String get historyLoadFailed => 'Couldn\'t load your orders.';

  @override
  String historyFrom(String place) {
    return 'From $place';
  }

  @override
  String get orderDetailTitle => 'Order details';

  @override
  String get orderLoadFailed => 'Couldn\'t load this order.';

  @override
  String get openLiveOrder => 'Open live order';

  @override
  String get detailRider => 'Rider';

  @override
  String get detailSender => 'Sender';

  @override
  String get detailPassenger => 'Passenger';

  @override
  String get statusCreated => 'Draft';

  @override
  String get statusOffered => 'Waiting for rider';

  @override
  String get statusAccepted => 'Rider on the way';

  @override
  String get statusInTransit => 'In transit';

  @override
  String get statusArrived => 'At drop-off';

  @override
  String get statusPayment => 'Payment';

  @override
  String get statusPaid => 'Paid';

  @override
  String get statusHandedOver => 'Handed over';

  @override
  String get statusDroppedOff => 'Dropped off';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusPaymentFailed => 'Payment failed';

  @override
  String get statusUnresolved => 'Under review';

  @override
  String get shareWithReceiver => 'Share with receiver';

  @override
  String get shareWithReceiverNote =>
      'The receiver can follow the delivery and pin their exact spot for the rider.';

  @override
  String receiverShareMessage(String url) {
    return 'Your RideLink delivery is on its way. Follow it and share your exact location with the rider here: $url';
  }

  @override
  String get receiverLinkFailed =>
      'Couldn\'t create the receiver link. Please try again.';

  @override
  String get receiverSpotTitle => 'The receiver pinned their exact spot';

  @override
  String receiverSpotNote(String note) {
    return 'Note: $note';
  }

  @override
  String get navigateToPickup => 'Navigate to pickup';

  @override
  String get navigateToDropoff => 'Navigate to drop-off';

  @override
  String get navigateToReceiver => 'Navigate to receiver\'s spot';

  @override
  String get navigateFailed => 'Couldn\'t open Google Maps on this phone.';

  @override
  String senderIs(String name) {
    return 'Sender: $name';
  }

  @override
  String passengerIs(String name) {
    return 'Passenger: $name';
  }

  @override
  String get switchMidJobTitle => 'Finish your job first';

  @override
  String get switchMidJobBody =>
      'You can switch to sending once this job is complete.';

  @override
  String get switchGoOfflineTitle => 'Go offline to switch?';

  @override
  String get switchGoOfflineBody =>
      'You\'ll stop getting requests while you send.';

  @override
  String get switchGoOfflineConfirm => 'Go offline';

  @override
  String get switchStayOnline => 'Stay online';

  @override
  String get switchGoOfflineFailed => 'Couldn\'t go offline. Please try again.';

  @override
  String get riderRunningLate => 'Your rider is running late';

  @override
  String get jobRunningLate => 'Running late';

  @override
  String get jobRunningLateBody =>
      'The pickup window has passed. RideLink will cancel this order shortly.';

  @override
  String get jobPassengerPickedUp => 'Passenger picked up';

  @override
  String get actionPassengerPickedUp => 'Passenger picked up';

  @override
  String get jobAtPickupNoteRide =>
      'Arrival recorded. Once your passenger is on, tap Passenger picked up.';

  @override
  String get jobAtDropoffBodyRide =>
      'Request payment from your passenger before they get off.';

  @override
  String get jobPaidBodyRide =>
      'Payment confirmed. Mark the passenger dropped off below.';

  @override
  String get jobPassengerDroppedOff => 'Passenger dropped off';

  @override
  String get actionPassengerDroppedOff => 'Passenger dropped off';

  @override
  String get jobRideComplete => 'Ride complete';

  @override
  String get actionCompleteRide => 'Complete ride';

  @override
  String get jobCancelledByPassenger => 'The passenger cancelled this ride.';

  @override
  String get errCodeEvidencePhotoRequired => 'Take the required photo first.';

  @override
  String get errCodeEvidencePickupPhotoRequired =>
      'Take the pickup photo before marking the item picked up.';

  @override
  String get errCodeEvidenceHandoverPhotoRequired =>
      'Take the handover photo before marking the item handed over.';

  @override
  String get jobPickupPhotoRequired => 'Take the pickup photo to continue.';

  @override
  String get jobHandoverPhotoRequired => 'Take the handover photo to continue.';

  @override
  String get currentLocationLabel => 'Current location';

  @override
  String get pinnedLocationLabel => 'Pinned location';

  @override
  String get changeButton => 'Change';

  @override
  String get confirmPickupButton => 'Confirm pickup';

  @override
  String get searchInsteadButton => 'Search instead';

  @override
  String get confirmPickupRideTitle => 'Confirm your pickup spot';

  @override
  String get confirmPickupDeliveryTitle =>
      'Confirm where the rider collects the item';

  @override
  String get confirmPickupHelper => 'Move the map to the exact spot';

  @override
  String get findingLocationLabel => 'Finding your location';

  @override
  String get pushChannelOffersName => 'New offers';

  @override
  String get pushChannelOffersDescription =>
      'Delivery and ride offers waiting for your answer';

  @override
  String get pushChannelUpdatesName => 'Order updates';

  @override
  String get pushChannelUpdatesDescription =>
      'Changes to your orders and account';

  @override
  String get pushOfferTitle => 'New offer';

  @override
  String get pushOfferBody => 'Open RideLink to see it before it expires.';

  @override
  String get pushDocumentTitle => 'Check your documents';

  @override
  String get pushDocumentBody => 'One of your rider documents needs attention.';

  @override
  String get pushGenericTitle => 'Order update';

  @override
  String get pushGenericBody => 'Open RideLink to see what changed.';

  @override
  String get notifPermissionTitle => 'Get offers as notifications';

  @override
  String get notifPermissionBody =>
      'New delivery and ride offers arrive as notifications, even when RideLink is closed. Each offer is open only for a short time.';

  @override
  String get notifPermissionContinue => 'Continue';

  @override
  String get notifPermissionNotNow => 'Not now';

  @override
  String get notifOffReminder =>
      'Notifications are off. You won\'t hear new offers while RideLink is closed.';

  @override
  String get notifOffTurnOn => 'Turn on';

  @override
  String get deleteAccountButton => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account';

  @override
  String get deleteAccountIntro =>
      'Deleting your account is permanent and signs you out.';

  @override
  String get deleteAccountDeletedHeading => 'What is deleted';

  @override
  String get deleteAccountDeletedBody =>
      'Your name, email address and rider documents.';

  @override
  String get deleteAccountKeptHeading => 'What is kept, without your name';

  @override
  String get deleteAccountKeptBody =>
      'Past orders and their evidence records, for disputes and tax.';

  @override
  String get deleteAccountContinue => 'Continue';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String deleteAccountConfirmBody(String word) {
    return 'Type $word to confirm.';
  }

  @override
  String get deleteAccountConfirmWord => 'DELETE';

  @override
  String get deleteAccountKeep => 'Keep my account';

  @override
  String get deleteAccountFailed => 'Couldn\'t delete your account. Try again.';

  @override
  String get accountDeletedNotice => 'Account deleted';

  @override
  String get errCodeAccountHasActiveOrder =>
      'Finish or cancel your active order first.';

  @override
  String get errCodeLegalAcceptanceRequired =>
      'Agree to the Terms of Service and Privacy Policy to continue.';

  @override
  String get legalAgreeLabel =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get legalTermsLink => 'Terms of Service';

  @override
  String get legalPrivacyLink => 'Privacy Policy';

  @override
  String get legalLoadFailed =>
      'Couldn\'t load the Terms of Service and Privacy Policy. Check your connection and try again.';

  @override
  String get linkOpenFailed => 'Couldn\'t open the link.';

  @override
  String get legalUpdateTitle => 'We\'ve updated our terms';

  @override
  String get legalUpdateBody =>
      'Read the updated Terms of Service and Privacy Policy. To keep using RideLink, accept them.';

  @override
  String get legalUpdateAccept => 'Accept';

  @override
  String get legalUpdateAcceptFailed =>
      'Couldn\'t save your answer. Try again.';

  @override
  String get documentsPrivacyNotice =>
      'Your documents are used only to verify you, stored privately, and deleted if you delete your account.';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredBody =>
      'This version of RideLink is no longer supported. Update the app to continue.';

  @override
  String get updateRequiredButton => 'Update';

  @override
  String get errCodeAccountDeleted => 'This account has been deleted.';

  @override
  String get payMethodCash => 'Cash';

  @override
  String get payMethodMpesaTill => 'M-Pesa Till';

  @override
  String get payMethodMpesaPochi => 'Pochi la Biashara';

  @override
  String get payMethodMpesaSendMoney => 'Send Money';

  @override
  String get mpesaCodeLabel => 'M-Pesa code (optional)';

  @override
  String get mpesaCodeHelp => 'The 10-character code from the M-Pesa message.';

  @override
  String get mpesaCodeInvalid =>
      'Enter the 10-character M-Pesa code, or leave it empty.';

  @override
  String get collectPaymentLabel => 'Amount to collect';

  @override
  String get paymentHowPaidLabel => 'How were you paid?';

  @override
  String get paymentMethodsLoadFailed =>
      'Couldn\'t load the M-Pesa details for this order. Cash is still available.';

  @override
  String get payYourRiderTitle => 'Pay your rider';

  @override
  String nameInMpesa(String name) {
    return 'Name in M-Pesa: $name';
  }

  @override
  String get copyNumber => 'Copy number';

  @override
  String get numberCopied => 'Number copied';

  @override
  String get paymentDetailsLoadFailed =>
      'Couldn\'t load your rider\'s payment details.';

  @override
  String get payerPromptTitle =>
      'Your rider says this order wasn\'t paid. Did you pay?';

  @override
  String get payerYes => 'Yes, I paid';

  @override
  String get payerNo => 'No, I didn\'t pay';

  @override
  String get payerHowPaidLabel => 'How did you pay?';

  @override
  String get payerSubmit => 'Send answer';

  @override
  String get payerThanks => 'Thanks, RideLink will review this order.';

  @override
  String get payerResponseFailed => 'Couldn\'t send your answer. Try again.';

  @override
  String get errCodePaymentDetailsHidden =>
      'Payment details are shown only while your rider is requesting payment.';

  @override
  String get evidenceEventPaymentDetailsViewed => 'Payment details viewed';

  @override
  String get evidenceEventPaymentReceived => 'Payment received';

  @override
  String get evidenceEventPaymentNotReceived => 'Reported not paid';

  @override
  String get evidenceEventPayerResponse => 'Payer answered about payment';

  @override
  String get paymentMethodsTitle => 'Payment methods';

  @override
  String get paymentMethodsNavSubtitle => 'Cash, and M-Pesa if you add it';

  @override
  String get paymentMethodsIntro =>
      'Customers see your M-Pesa details only when you request payment, and only for that order.';

  @override
  String get paymentMethodsFootnote =>
      'Changes apply to new orders. An accepted order keeps the details it was accepted with.';

  @override
  String get cashAlwaysAccepted => 'Always accepted';

  @override
  String get paymentMethodNotAdded => 'Not added';

  @override
  String get paymentMethodAdd => 'Add';

  @override
  String get paymentMethodEdit => 'Edit';

  @override
  String get paymentMethodRemove => 'Remove';

  @override
  String paymentMethodRemoveTitle(String method) {
    return 'Remove $method?';
  }

  @override
  String get paymentMethodRemoveBody =>
      'Customers won\'t see it on new orders.';

  @override
  String get paymentMethodSaved => 'Payment method saved';

  @override
  String get paymentMethodRemoved => 'Payment method removed';

  @override
  String get paymentMethodRemoveFailed => 'Couldn\'t remove. Try again.';

  @override
  String get paymentMethodsLoadError => 'Couldn\'t load your payment methods.';

  @override
  String get tillNumberLabel => 'Till number';

  @override
  String get mpesaPhoneLabel => 'M-Pesa phone number';

  @override
  String get mpesaNameLabel => 'Name shown in M-Pesa';

  @override
  String get mpesaNameHelp => 'The name customers see when they pay you.';

  @override
  String get tillNumberInvalid => 'Enter a till number of 5 to 8 digits.';

  @override
  String get mpesaPhoneInvalid =>
      'Enter a Kenyan mobile number, e.g. 0712345678.';

  @override
  String get mpesaNameInvalid => 'Enter 2 to 60 characters.';

  @override
  String get notifPayerResponseTitle => 'Payment answer received';

  @override
  String get notifPayerResponseBody =>
      'The customer answered whether they paid. RideLink will review this order.';

  @override
  String get notifPaymentNotPaidTitle => 'Payment not received';

  @override
  String get notifPaymentNotPaidBody =>
      'Your rider says this order was not paid. Tell us if you paid.';

  @override
  String get whoPaysTitle => 'Who pays?';

  @override
  String get payerSenderOption => 'I pay';

  @override
  String get payerReceiverOption => 'Receiver pays';

  @override
  String get riderSenderPays => 'Sender pays';

  @override
  String receiverIsPaying(String amount) {
    return 'Your receiver is paying $amount.';
  }

  @override
  String get receiverCantPayNote => 'If they can\'t pay, you can pay here.';

  @override
  String get statusCompletedUnconfirmed => 'Completed, payment not confirmed';

  @override
  String lateReportBody(String deadline) {
    return 'This order was closed because payment wasn\'t confirmed. If you weren\'t paid, tap Not paid by $deadline.';
  }

  @override
  String get notifPaymentReminderTitle => 'Confirm payment';

  @override
  String get notifPaymentReminderBody =>
      'Did you get paid for this order? Tap to confirm.';

  @override
  String get notifOrderCompleteTitle => 'Order complete';

  @override
  String get notifOrderCompleteBody => 'Your order is complete.';

  @override
  String get notifPaymentNotPaidReceiverBody =>
      'Your rider says the receiver didn\'t pay. Tell us if it was paid.';

  @override
  String get lateReportBodyNoDeadline =>
      'This order was closed because payment wasn\'t confirmed. If you weren\'t paid, tap Not paid.';

  @override
  String get notifOrderClosedTitle => 'Order closed';

  @override
  String get payerPromptTitleReceiver =>
      'Your rider says the receiver didn\'t pay. Was it paid?';

  @override
  String get notifDocumentApprovedTitle => 'Document approved';

  @override
  String notifDocumentApprovedBody(String doc) {
    return 'Your $doc was approved.';
  }

  @override
  String get notifDocumentRejectedTitle => 'Document not approved';

  @override
  String notifDocumentRejectedBody(String doc, String reason) {
    return 'Your $doc was not approved: $reason. Please upload a new one.';
  }

  @override
  String get notifRiderVerifiedTitle => 'You\'re verified';

  @override
  String get notifRiderVerifiedBody =>
      'You can now go online and accept Delivery and Ride orders.';

  @override
  String get docRejectionBlurry => 'The photo is blurry or hard to read';

  @override
  String get docRejectionWrongDocument => 'This is not the requested document';

  @override
  String get docRejectionExpired => 'This document has expired';

  @override
  String get docRejectionNameMismatch => 'The name doesn\'t match your ID';

  @override
  String get docRejectionDetailsMismatch =>
      'The details don\'t match your registration (for example the plate)';

  @override
  String get docRejectionBikePhoto =>
      'The bike photo must show the plate clearly and the bike in good condition';

  @override
  String get docRejectionSuspectedFake => 'We couldn\'t verify this document';

  @override
  String get docRejectionOther => 'See the message from RideLink';

  @override
  String docRejectionMessage(String message) {
    return 'Message from RideLink: $message';
  }

  @override
  String get statusClosedUnpaid => 'Closed, unpaid';

  @override
  String get suspensionReasonSafetyIncident => 'Safety incident';

  @override
  String get suspensionReasonFraud => 'Fraud or fake documents';

  @override
  String get suspensionReasonHarassment => 'Harassment or abuse';

  @override
  String get suspensionReasonNonPayment => 'Repeated non-payment';

  @override
  String get suspensionReasonNoShows => 'Repeated no-shows or cancellations';

  @override
  String get suspensionReasonStrikes => 'Repeated warnings';

  @override
  String get suspensionReasonOther => 'Other';

  @override
  String get accountSuspendedTitle => 'Account suspended';

  @override
  String accountSuspendedUntil(String date) {
    return 'Your account is suspended until $date.';
  }

  @override
  String get accountSuspendedPermanent =>
      'Your account is suspended permanently.';

  @override
  String get accountSuspendedAfterOrder =>
      'Your account will be suspended when your current order ends.';

  @override
  String accountSuspendedReason(String reason) {
    return 'Reason: $reason.';
  }

  @override
  String get accountSuspendedCanAppeal => 'You can appeal.';

  @override
  String get accountStatusTitle => 'Account status';

  @override
  String get accountNotSuspended => 'Your account is active.';

  @override
  String get accountStatusLoadFailed => 'Couldn\'t load your account status.';

  @override
  String get suspendedViewDetails => 'View details';

  @override
  String get appealTitle => 'Appeal';

  @override
  String get appealLabel => 'Tell us why the suspension should be lifted';

  @override
  String get appealOnceNote => 'You can send one appeal for this suspension.';

  @override
  String get appealSubmit => 'Send appeal';

  @override
  String get appealRequired => 'Write your appeal';

  @override
  String get appealFailed => 'Couldn\'t send your appeal. Try again.';

  @override
  String get appealPending =>
      'Your appeal has been sent and is being reviewed.';

  @override
  String get appealUpheld =>
      'Your appeal was reviewed. The suspension stays in place.';

  @override
  String get appealLifted =>
      'Your appeal was accepted and the suspension lifted.';

  @override
  String get settleBalanceTitle => 'Settle your balance';

  @override
  String get settleBalanceIntro =>
      'You can\'t book until your rider confirms they have received your payment.';

  @override
  String balanceOwedTo(String rider) {
    return 'You owe $rider for this order';
  }

  @override
  String get balanceOwedToRider => 'You owe your rider for this order';

  @override
  String get balanceViewOrder => 'View order';

  @override
  String get balanceSettledTitle => 'Balance settled';

  @override
  String get balanceSettledBody => 'You can book again.';

  @override
  String get balanceLoadFailed => 'Couldn\'t load your balance.';

  @override
  String get backToHomeButton => 'Back to home';

  @override
  String get homeBalanceBannerTitle => 'Unpaid balance';

  @override
  String homeBalanceBannerBody(String amount) {
    return 'You owe $amount. Pay your rider to book again.';
  }

  @override
  String get riderSettleTitle => 'Payment received?';

  @override
  String get riderSettleBodyUnresolved =>
      'If the payer has paid you since, confirm it here. This completes the order.';

  @override
  String riderSettleBodyBalance(String amount) {
    return 'The payer owes you $amount for this order. When you receive it, confirm it here.';
  }

  @override
  String get notifPaymentRuledTitle => 'Payment review complete';

  @override
  String get notifPaymentRuledBody => 'Open the order to see the decision.';

  @override
  String notifBalanceCreatedBody(String amount) {
    return 'You owe your rider $amount for this order.';
  }

  @override
  String get notifBalanceCreatedBodyNoAmount =>
      'You owe your rider for this order.';

  @override
  String get notifBalanceSettledBody =>
      'The payment for this order is confirmed.';

  @override
  String get notifStrikeIssuedTitle => 'Warning';

  @override
  String get notifStrikeIssuedBody => 'You received a warning on this order.';

  @override
  String get notifAccountSuspendedBody => 'Open RideLink to see the details.';

  @override
  String get notifSuspensionLiftedTitle => 'Suspension lifted';

  @override
  String get notifSuspensionLiftedBody => 'Your account is active again.';

  @override
  String get notifAppealDecidedTitle => 'Appeal decided';

  @override
  String get notifAppealDecidedBody => 'Your appeal has been reviewed.';

  @override
  String get errCodeOutstandingBalance =>
      'Settle your balance with your rider before booking again.';

  @override
  String get errCodeAccountSuspended => 'Your account is suspended.';

  @override
  String get strikeReasonUnpaidOrder => 'Unpaid order';

  @override
  String get strikeReasonFalseReport => 'Payment report not upheld';

  @override
  String get strikeReasonGeneric => 'Warning';

  @override
  String get suspensionIntendedTitle => 'Suspension notice';

  @override
  String get suspensionIntendedLead =>
      'RideLink intends to suspend your account.';

  @override
  String suspensionRespondUntil(String time) {
    return 'You can respond until $time.';
  }

  @override
  String get accountOnHoldTitle => 'Account on hold';

  @override
  String get accountOnHold => 'Your account is on hold pending review.';

  @override
  String get suspensionResponseLabel => 'Your response';

  @override
  String get suspensionResponseSubmit => 'Send response';

  @override
  String get suspensionResponseRequired => 'Write your response';

  @override
  String get suspensionResponseFailed =>
      'Couldn\'t send your response. Try again.';

  @override
  String get suspensionResponseSent =>
      'Your response has been sent. RideLink will review it before deciding.';

  @override
  String get standingTitle => 'Account standing';

  @override
  String get standingRule =>
      '3 warnings in 90 days can lead to a 7-day suspension.';

  @override
  String get standingNoWarnings => 'You have no warnings.';

  @override
  String strikeIssuedOn(String date) {
    return 'Issued $date';
  }

  @override
  String strikeExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get disputeButton => 'Dispute';

  @override
  String get disputeLabel => 'Tell us why this warning is wrong';

  @override
  String get disputeOnceNote =>
      'You can dispute each warning once, within 7 days.';

  @override
  String get disputeSubmit => 'Send dispute';

  @override
  String get disputeRequired => 'Write your dispute';

  @override
  String get disputeFailed => 'Couldn\'t send your dispute. Try again.';

  @override
  String get disputePending => 'Dispute sent. RideLink will review it.';

  @override
  String get disputeUpheld =>
      'Your dispute was accepted and the warning removed.';

  @override
  String get disputeRejected => 'Your dispute was reviewed. The warning stays.';

  @override
  String get iPaidButton => 'I\'ve paid';

  @override
  String get iPaidTitle => 'Tell us how you paid';

  @override
  String get cashNoteLabel => 'Note (optional)';

  @override
  String get cashNoteHelp => 'For example, when and where you paid';

  @override
  String get iPaidSubmit => 'Send';

  @override
  String get iPaidFailed => 'Couldn\'t send. Try again.';

  @override
  String get iPaidSent =>
      'We\'ve asked your rider to confirm. RideLink will review if they don\'t respond.';

  @override
  String get forgiveBalanceButton => 'Forgive balance';

  @override
  String get forgiveBalanceTitle => 'Forgive this balance?';

  @override
  String get forgiveBalanceBody =>
      'The payer will no longer owe you for this order. This can\'t be undone.';

  @override
  String get forgiveBalanceConfirm => 'Forgive';

  @override
  String get receiverPaysDisclosure =>
      'If your receiver doesn\'t pay, you will owe the rider.';

  @override
  String get notifBalanceClaimTitle => 'Customer says they paid';

  @override
  String get notifBalanceClaimBody =>
      'Your customer says they paid for this order. Please confirm.';

  @override
  String get notifDisputeDecidedTitle => 'Dispute decided';

  @override
  String get notifDisputeDecidedBody => 'Your dispute has been reviewed.';

  @override
  String get idNumberLabel => 'National ID number';

  @override
  String get idNumberHint => 'As printed on your ID';

  @override
  String get idNumberRequired => 'Enter your ID number';

  @override
  String get idNumberInvalid => 'Enter 4 to 20 letters or digits';

  @override
  String get idNumberReceived => 'ID number received';
}
