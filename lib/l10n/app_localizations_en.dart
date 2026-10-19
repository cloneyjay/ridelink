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
  String jobWaitingForSender(String amount) {
    return 'Waiting for the sender to pay $amount in cash.';
  }

  @override
  String jobSenderPaid(String amount) {
    return 'The sender says they paid $amount in cash. Confirm once you have it.';
  }

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
  String paymentReceivedConfirmTitle(String amount) {
    return 'Received $amount in cash?';
  }

  @override
  String get paymentReceivedConfirmBody =>
      'Only confirm once the cash is in your hand. This is recorded and cannot be undone.';

  @override
  String get paymentNotReceivedButton => 'Not received';

  @override
  String get paymentNotReceivedConfirmTitle => 'Report payment not received?';

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
      'You reported that the cash was not received. RideLink will review this order.';

  @override
  String get paymentUnderReviewSenderBody =>
      'Your rider reported that the cash was not received. RideLink will review this order.';

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
  String payInCash(String amount) {
    return 'Pay $amount in cash to your rider';
  }

  @override
  String get payInCashBody =>
      'Then tap \"I\'ve paid\". Your rider confirms when they have the cash.';

  @override
  String get ivePaidButton => 'I\'ve paid';

  @override
  String ivePaidConfirmTitle(String amount) {
    return 'Have you paid $amount?';
  }

  @override
  String get ivePaidConfirmBody =>
      'Only confirm after handing the cash to your rider. This is recorded.';

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
      'This changed in the meantime. Refresh and try again.';

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
  String get evidencePickupPhotoHintRide => 'Take a photo at the pickup point.';

  @override
  String get evidenceHandoverPhotoHint =>
      'Take a photo of the item as you hand it over.';

  @override
  String get evidenceHandoverPhotoHintRide =>
      'Take a photo at the drop-off point.';

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
    return 'Your rider has requested payment. Pay $amount in cash.';
  }

  @override
  String get notifPaymentRequestedBodyNoAmount =>
      'Your rider has requested payment. Pay the agreed amount in cash.';

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
  String notifPaymentConfirmedBody(String amount) {
    return 'Your rider confirmed receiving $amount in cash.';
  }

  @override
  String get notifPaymentConfirmedBodyNoAmount =>
      'Your rider confirmed receiving your cash payment.';

  @override
  String get notifPaymentUnresolvedTitle => 'Payment unresolved';

  @override
  String get notifPaymentUnresolvedBody =>
      'The rider reported the cash as not received. RideLink will review this order.';

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
  String jobWaitingForPassenger(String amount) {
    return 'Waiting for the passenger to pay $amount in cash.';
  }

  @override
  String jobPassengerPaid(String amount) {
    return 'The passenger says they paid $amount in cash. Confirm once you have it.';
  }

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
}
