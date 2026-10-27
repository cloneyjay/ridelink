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

  /// Opens the side menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuTooltip;

  /// Menu entry for registered riders: opens the rider side.
  ///
  /// In en, this message translates to:
  /// **'Switch to riding'**
  String get menuSwitchToRiding;

  /// Menu entry on the rider side: back to the sender home.
  ///
  /// In en, this message translates to:
  /// **'Switch to sending'**
  String get menuSwitchToSending;

  /// Menu entry for users without a rider profile.
  ///
  /// In en, this message translates to:
  /// **'Become a rider'**
  String get menuBecomeRider;

  /// Shown in the menu when GET /riders/me fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your rider account.'**
  String get menuRiderStatusError;

  /// Menu entry.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get menuSignOut;

  /// Title of the rider side placeholder.
  ///
  /// In en, this message translates to:
  /// **'Rider mode'**
  String get riderHomeTitle;

  /// Heading of the home bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'What do you need?'**
  String get homeWhatDoYouNeed;

  /// Service name.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get serviceDelivery;

  /// Delivery tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a parcel'**
  String get serviceDeliverySubtitle;

  /// Service name.
  ///
  /// In en, this message translates to:
  /// **'Ride'**
  String get serviceRide;

  /// Ride tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a boda ride'**
  String get serviceRideSubtitle;

  /// Placeholder when the app has no Maps key.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get mapUnavailable;

  /// Location permission card title.
  ///
  /// In en, this message translates to:
  /// **'Location is off'**
  String get locationDeniedTitle;

  /// Location permission card body.
  ///
  /// In en, this message translates to:
  /// **'Allow location so we can show where you are. You can still book by searching for places.'**
  String get locationDeniedBody;

  /// Card body when device location is switched off.
  ///
  /// In en, this message translates to:
  /// **'Turn on your phone\'s location to show where you are. You can still book by searching for places.'**
  String get locationServiceOffBody;

  /// Card body when location can't be read.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your location. You can still book by searching for places.'**
  String get locationUnavailableBody;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Allow location'**
  String get locationAllow;

  /// Button: opens app settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get locationOpenSettings;

  /// Button: opens device location settings.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get locationTurnOn;

  /// Screen 4 title for deliveries.
  ///
  /// In en, this message translates to:
  /// **'New delivery'**
  String get newDeliveryTitle;

  /// Screen 4 title for rides.
  ///
  /// In en, this message translates to:
  /// **'New ride'**
  String get newRideTitle;

  /// Route field label.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupLabel;

  /// Route field label.
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropoffLabel;

  /// Empty pickup field.
  ///
  /// In en, this message translates to:
  /// **'Choose pickup'**
  String get choosePickup;

  /// Empty drop-off field.
  ///
  /// In en, this message translates to:
  /// **'Choose drop-off'**
  String get chooseDropoff;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemSectionTitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Weight in kg (optional)'**
  String get weightLabel;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Item value'**
  String get valueBandLabel;

  /// Helper under the value choices (decision 6).
  ///
  /// In en, this message translates to:
  /// **'Items worth more than KES 10,000 can\'t be booked.'**
  String get valueBandCapNote;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiverSectionTitle;

  /// Field label.
  ///
  /// In en, this message translates to:
  /// **'Receiver\'s name'**
  String get receiverNameLabel;

  /// Screen 4 primary button.
  ///
  /// In en, this message translates to:
  /// **'Find riders'**
  String get findRidersButton;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a pickup point'**
  String get errorPickupRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a drop-off point'**
  String get errorDropoffRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Enter the receiver\'s name'**
  String get errorReceiverRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get errorCategoryRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Describe the item'**
  String get errorDescriptionRequired;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight above 0'**
  String get errorWeightInvalid;

  /// Validation.
  ///
  /// In en, this message translates to:
  /// **'Choose the item\'s value'**
  String get errorValueBandRequired;

  /// Order creation error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create your order. Try again.'**
  String get createOrderFailed;

  /// Category load error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load item categories.'**
  String get categoriesLoadFailed;

  /// Value band.
  ///
  /// In en, this message translates to:
  /// **'Under KES 500'**
  String get valueBandUnder500;

  /// Value band.
  ///
  /// In en, this message translates to:
  /// **'KES 500–2,000'**
  String get valueBand500To2000;

  /// Value band.
  ///
  /// In en, this message translates to:
  /// **'KES 2,000–5,000'**
  String get valueBand2000To5000;

  /// Value band.
  ///
  /// In en, this message translates to:
  /// **'KES 5,000–10,000'**
  String get valueBand5000To10000;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Fragile items'**
  String get categoryFragile;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get categoryMedication;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get categoryCash;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get categoryAlcohol;

  /// Item category.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get placeSearchHint;

  /// Shown under 2 characters.
  ///
  /// In en, this message translates to:
  /// **'Type at least 2 letters'**
  String get placeSearchMinChars;

  /// Empty results.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get placeSearchNoResults;

  /// Server returned 503 maps not configured.
  ///
  /// In en, this message translates to:
  /// **'Location search is unavailable right now. Try again later.'**
  String get placeSearchUnavailable;

  /// Search error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search. Check your connection.'**
  String get placeSearchFailed;

  /// Tooltip of the clear button.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSearch;

  /// Rider list title.
  ///
  /// In en, this message translates to:
  /// **'Choose a rider'**
  String get riderListTitle;

  /// Sort option.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get sortByPrice;

  /// Sort option.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get sortByDistance;

  /// Trip distance chip, e.g. 'Trip 4.8 km'.
  ///
  /// In en, this message translates to:
  /// **'Trip {distance}'**
  String tripDistance(String distance);

  /// Shown when distance_estimated is true.
  ///
  /// In en, this message translates to:
  /// **'Distance is estimated'**
  String get distanceEstimatedNote;

  /// Empty rider list.
  ///
  /// In en, this message translates to:
  /// **'No riders nearby right now'**
  String get noRidersTitle;

  /// Empty rider list body.
  ///
  /// In en, this message translates to:
  /// **'Try again in a moment.'**
  String get noRidersBody;

  /// Rider list error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load riders.'**
  String get ridersLoadFailed;

  /// Rider with zero ratings.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// Rating count next to the average.
  ///
  /// In en, this message translates to:
  /// **'{count} ratings'**
  String ratingCount(int count);

  /// On-time rate.
  ///
  /// In en, this message translates to:
  /// **'{percent}% on time'**
  String onTimePercent(int percent);

  /// Completed jobs.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completedJobs(int count);

  /// Rider's distance to the pickup point.
  ///
  /// In en, this message translates to:
  /// **'{distance} from pickup'**
  String pickupDistanceAway(String distance);

  /// Pickup window.
  ///
  /// In en, this message translates to:
  /// **'Arrives within {minutes} min'**
  String arrivesWithin(int minutes);

  /// Button on the rider list.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get editRoute;

  /// After offer.resolved declined.
  ///
  /// In en, this message translates to:
  /// **'The rider declined. Choose another rider.'**
  String get offerDeclinedMessage;

  /// After offer.resolved expired.
  ///
  /// In en, this message translates to:
  /// **'The rider didn\'t respond in time. Choose another rider.'**
  String get offerExpiredMessage;

  /// Screen 3 title.
  ///
  /// In en, this message translates to:
  /// **'Rider profile'**
  String get riderProfileTitle;

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get statOnTime;

  /// Stat label.
  ///
  /// In en, this message translates to:
  /// **'Completed jobs'**
  String get statCompleted;

  /// Stat label: distance to pickup and window.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get statPickup;

  /// Breakdown card heading.
  ///
  /// In en, this message translates to:
  /// **'Price for this trip'**
  String get priceForThisTrip;

  /// Breakdown row.
  ///
  /// In en, this message translates to:
  /// **'Base fare'**
  String get breakdownBaseFare;

  /// Breakdown row, e.g. 'Platform rate for 10 km'.
  ///
  /// In en, this message translates to:
  /// **'Platform rate for {distance}'**
  String breakdownPlatform(String distance);

  /// Breakdown row, e.g. 'Rider rate beyond 10 km'.
  ///
  /// In en, this message translates to:
  /// **'Rider rate beyond {distance}'**
  String breakdownRider(String distance);

  /// Detail under the rider rate row.
  ///
  /// In en, this message translates to:
  /// **'{distance} at {rate} per km'**
  String breakdownRiderDetail(String distance, String rate);

  /// Shown when minimum_fare_applied is true.
  ///
  /// In en, this message translates to:
  /// **'Minimum fare applies to this trip'**
  String get breakdownMinimumFare;

  /// Breakdown total row.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get breakdownTotal;

  /// Screen 3 primary button.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get requestButton;

  /// Screen 5 title.
  ///
  /// In en, this message translates to:
  /// **'Price quote'**
  String get quoteTitle;

  /// Above the total.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get youPay;

  /// Screen 5 note.
  ///
  /// In en, this message translates to:
  /// **'This price is final. It is locked once the rider accepts.'**
  String get quoteFinalNote;

  /// Screen 5 primary button.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequestButton;

  /// Offer error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the request. Try again.'**
  String get sendRequestFailed;

  /// Waiting screen title.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name}'**
  String waitingTitle(String name);

  /// Waiting screen body.
  ///
  /// In en, this message translates to:
  /// **'The rider has a short time to accept your request.'**
  String get waitingBody;

  /// After the countdown reaches zero.
  ///
  /// In en, this message translates to:
  /// **'Checking the rider\'s response…'**
  String get waitingChecking;

  /// Under the countdown number.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get secondsLabel;

  /// Waiting screen button.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequestButton;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get cancelConfirmTitle;

  /// Confirm dialog body.
  ///
  /// In en, this message translates to:
  /// **'Your order will be cancelled.'**
  String get cancelConfirmBody;

  /// Confirm dialog action.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelConfirmYes;

  /// Confirm dialog dismiss.
  ///
  /// In en, this message translates to:
  /// **'Keep waiting'**
  String get cancelConfirmNo;

  /// Cancel error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cancel. The rider may have already responded.'**
  String get cancelFailed;

  /// Snackbar after cancelling.
  ///
  /// In en, this message translates to:
  /// **'Your order was cancelled.'**
  String get orderCancelledMessage;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHome;

  /// Edit route screen title.
  ///
  /// In en, this message translates to:
  /// **'Edit route'**
  String get editRouteTitle;

  /// Edit route button.
  ///
  /// In en, this message translates to:
  /// **'Save route'**
  String get saveRouteButton;

  /// PATCH route error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the route. Try again.'**
  String get routeUpdateFailed;

  /// PATCH route 422.
  ///
  /// In en, this message translates to:
  /// **'This route can no longer be changed.'**
  String get routeLocked;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeTooltip;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your rider profile.'**
  String get riderLoadFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Register your boda boda to start receiving delivery and ride requests. Next you will upload your documents for review.'**
  String get registerIntro;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleLabel;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Boda boda'**
  String get vehicleBodaBoda;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Boda boda is the only vehicle at launch.'**
  String get vehicleOnlyBoda;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Number plate'**
  String get plateLabel;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'e.g. KMFA 123B'**
  String get plateHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Enter 3 to 12 letters, digits or spaces'**
  String get plateInvalid;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t register. Try again.'**
  String get registerFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'RideLink staff review each document. You can go online once all of them are approved.'**
  String get documentsIntro;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} uploaded'**
  String documentsProgress(int done, int total);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get documentsContinue;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Upload every document to continue.'**
  String get documentsUploadAll;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your documents.'**
  String get documentsLoadFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Rider photo'**
  String get docRiderPhoto;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'A clear photo of your face. Senders see it before and during a job.'**
  String get docRiderPhotoHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get docNationalId;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Front of your national ID card.'**
  String get docNationalIdHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get docDrivingLicence;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle licence (Class A), with its expiry date.'**
  String get docDrivingLicenceHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Police clearance certificate'**
  String get docPoliceClearance;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'DCI good conduct certificate, with its issue date. Valid for 12 months.'**
  String get docPoliceClearanceHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'PSV insurance'**
  String get docPsvInsurance;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your PSV insurance certificate, with its expiry date.'**
  String get docPsvInsuranceHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Logbook or sale agreement'**
  String get docLogbook;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Proof that you own or may use the bike.'**
  String get docLogbookHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Bike rear photo'**
  String get docBikeRearPhoto;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'A photo of the back of your bike with the number plate visible.'**
  String get docBikeRearPhotoHint;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get docStatusMissing;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get docStatusPending;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get docStatusApproved;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get docStatusRejected;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String docRejectedReason(String reason);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String docExpiresOn(String date);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String docIssuedOn(String date);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your approved document stays valid while this one is reviewed.'**
  String get docPendingStillValid;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get docUploadAction;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get docReplaceAction;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'{name} uploaded'**
  String docUploaded(String name);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'JPEG or PNG photo, up to 10 MB.'**
  String get docFormatsImage;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'JPEG or PNG photo, or a PDF, up to 10 MB.'**
  String get docFormatsAny;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Choose expiry date'**
  String get docChooseExpiry;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Choose issue date'**
  String get docChooseIssued;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get docTakePhoto;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get docChooseGallery;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF or image file'**
  String get docChooseFile;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get docUploadButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'File must be 10 MB or smaller.'**
  String get docTooLarge;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'This document must be a photo (JPEG or PNG).'**
  String get docImageOnly;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Choose the date first.'**
  String get docDateRequired;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file. Try again.'**
  String get docPickFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload. Check your connection and try again.'**
  String get docUploadFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your documents are being reviewed'**
  String get verificationPendingTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you when the review is complete.'**
  String get verificationPendingBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You\'re approved'**
  String get verificationApprovedTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You can go online and start receiving requests.'**
  String get verificationApprovedBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Some documents need attention'**
  String get verificationRejectedTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Check the reasons and upload new documents.'**
  String get verificationRejectedBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Finish uploading your documents'**
  String get verificationIncompleteTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Review starts once every document is uploaded.'**
  String get verificationIncompleteBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Go to rider home'**
  String get goToRiderHome;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get fixDocumentsButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'View documents'**
  String get viewDocumentsButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t registered as a rider yet'**
  String get riderNotRegisteredTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You\'re online'**
  String get riderOnline;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get riderOffline;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Receiving requests with pickups within {distance}'**
  String riderOnlineBody(String distance);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Go online to receive delivery and ride requests.'**
  String get riderOfflineBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Pickup radius {radius} · Delivery {delivery}/km · Ride {ride}/km'**
  String riderSettingsSummary(String radius, String delivery, String ride);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Boda boda {plate}'**
  String riderPlate(String plate);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t approved yet'**
  String get blockNotVerifiedTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You can go online once RideLink approves your documents.'**
  String get blockNotVerifiedBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'View status'**
  String get viewStatusButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Documents need attention'**
  String get blockDocumentsTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Renew or upload: {documents}'**
  String blockDocumentsBody(String documents);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'One or more documents are missing or expired.'**
  String get blockDocumentsBodyGeneric;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Update documents'**
  String get updateDocumentsButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You\'re paused until {time}'**
  String blockPausedTitle(String time);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'After {count} missed pickups in 24 hours you can\'t receive requests until then.'**
  String blockPausedMissedPickups(int count);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You can\'t receive requests until then.'**
  String get blockPausedBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to go online'**
  String get blockLocationTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'RideLink shares your location while you are online so senders can find you and pickups are recorded.'**
  String get blockLocationBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t change your status'**
  String get blockErrorTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You\'re online'**
  String get onlineNotificationTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'RideLink is sharing your location for requests and pickups.'**
  String get onlineNotificationBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Online status'**
  String get onlineNotificationChannel;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get riderOfferTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Time is up. Checking the request…'**
  String get riderOfferChecking;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You earn'**
  String get youEarn;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Reach pickup within {minutes} min'**
  String reachPickupWithin(int minutes);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to accept. Your location must be recent.'**
  String get acceptNeedsLocation;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t accept. Try again.'**
  String get acceptFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t decline. Try again.'**
  String get declineFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The request expired.'**
  String get riderOfferExpired;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You declined the request.'**
  String get riderOfferDeclined;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get riderOfferTaken;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The sender cancelled the request.'**
  String get riderOfferCancelled;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Current job'**
  String get jobTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get jobToPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'At pickup'**
  String get jobAtPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Arrival recorded. Collect and tap Picked up.'**
  String get jobAtPickupNote;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get jobPickedUp;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'On the way to drop-off'**
  String get jobInTransit;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'At drop-off'**
  String get jobAtDropoff;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Request payment from the sender before handing over.'**
  String get jobAtDropoffBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get jobPayment;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get jobPaid;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Hand over, then mark it below.'**
  String get jobPaidBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get jobHandedOver;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Job complete'**
  String get jobCompleted;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You earned {amount}.'**
  String jobCompletedBody(String amount);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Job cancelled'**
  String get jobCancelled;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The sender cancelled this order.'**
  String get jobCancelledBySender;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The pickup window passed, so the order was cancelled.'**
  String get jobCancelledTimeout;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this order.'**
  String get jobCancelledByYou;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'This order was cancelled.'**
  String get jobCancelledGeneric;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Agreed price'**
  String get agreedPrice;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Reach pickup in'**
  String get reachPickupIn;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Deadline {time}'**
  String pickupDeadlineAt(String time);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Arrival is recorded automatically when you are within 150 m of the pickup point.'**
  String get arrivalAutoNote;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Heading to pickup'**
  String get headingToPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Heading to drop-off'**
  String get headingToDropoff;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Receiver: {name}'**
  String receiverIs(String name);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'I\'ve arrived'**
  String get actionArrivedAtPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get actionPickedUp;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Start trip to drop-off'**
  String get actionStartTrip;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Arrived at drop-off'**
  String get actionArrivedAtDropoff;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Request payment'**
  String get actionRequestPayment;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Mark handed over'**
  String get actionHandOver;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Complete job'**
  String get actionComplete;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the job. Try again.'**
  String get jobActionFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceivedButton;

  /// Rider job: secondary action when the payer did not pay.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get paymentNotReceivedButton;

  /// Rider job: confirm dialog title for Not paid.
  ///
  /// In en, this message translates to:
  /// **'Report this order as not paid?'**
  String get paymentNotReceivedConfirmTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The order goes to RideLink for review.'**
  String get paymentNotReceivedConfirmBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBackButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get riderCancelButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Cancel this job?'**
  String get riderCancelTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You accepted less than 2 minutes ago, so cancelling now won\'t count toward a pause ({time} left). It still shows in your cancellation record.'**
  String riderCancelWithinGrace(String time);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'More than 2 minutes have passed since you accepted, so this counts like a missed pickup. 3 in 24 hours pauses you.'**
  String get riderCancelAfterGrace;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get riderCancelConfirm;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Keep job'**
  String get riderCancelKeep;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing this payment'**
  String get paymentUnderReview;

  /// Rider job, unresolved.
  ///
  /// In en, this message translates to:
  /// **'You reported this order as not paid. RideLink will review this order.'**
  String get paymentUnderReviewRiderBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your order'**
  String get trackingScreenTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your order.'**
  String get trackingLoadFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the order. Try again.'**
  String get trackingActionFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Rider arrives in {minutes} min'**
  String riderArrivesIn(int minutes);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your rider has arrived'**
  String get riderArrivedAtPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'On the way to the drop-off'**
  String get trackingOnTheWay;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your rider is at the drop-off'**
  String get riderAtDropoff;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Trip complete'**
  String get tripComplete;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The rider didn\'t reach pickup in time, so the order was cancelled.'**
  String get orderCancelledTimeout;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The rider cancelled this order.'**
  String get orderCancelledByRider;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this order.'**
  String get orderCancelledBySender;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stepAccepted;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'At pickup'**
  String get stepAtPickup;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get stepInTransit;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get stepPayment;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Dropped off'**
  String get stepDroppedOff;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your rider to confirm the payment'**
  String get waitingForRiderConfirm;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} confirmed'**
  String paymentConfirmed(String amount);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'View terms'**
  String get viewTerms;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Agreed terms'**
  String get termsTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'These terms were locked when the rider accepted.'**
  String get termsLockedNote;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Pickup window'**
  String get termsPickupWindow;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesShort(int minutes);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get senderCancelButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get senderCancelTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'The rider has accepted and is on the way. Your order will be cancelled.'**
  String get senderCancelBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get senderCancelKeep;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Discard this order?'**
  String get discardOrderTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your order will be cancelled.'**
  String get discardOrderBody;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardOrderConfirm;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Keep order'**
  String get discardOrderKeep;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t discard the order. Try again.'**
  String get discardOrderFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'You have an order in progress'**
  String get activeOrderBanner;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewButton;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Pricing and settings'**
  String get settingsTitle;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get settingsDistanceSection;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Pickup radius'**
  String get settingsPickupRadius;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'How far you travel to collect. Up to {max}.'**
  String settingsPickupRadiusHelp(String max);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Platform-rate distance'**
  String get settingsMaxDistance;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Trips up to this distance use the platform price; your rate applies beyond it. At least {min}.'**
  String settingsMaxDistanceHelp(String min);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Your rates'**
  String get settingsRatesSection;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Charged per km beyond your platform-rate distance.'**
  String get settingsRatesNote;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Delivery rate'**
  String get settingsDeliveryRate;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Ride rate'**
  String get settingsRideRate;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max} per km'**
  String settingsRateRange(String min, String max);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get settingsLoadSection;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Maximum parcel weight'**
  String get settingsMaxWeight;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Heaviest parcel you will carry.'**
  String get settingsMaxWeightHelp;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Try again.'**
  String get settingsSaveFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your settings.'**
  String get settingsLoadFailed;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get settingsRequired;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get settingsNotNumber;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'Enter a value above 0'**
  String get settingsMustBePositive;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'This value is too large'**
  String get settingsTooHigh;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'At most {max}'**
  String settingsRadiusTooHigh(String max);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'At least {min}'**
  String settingsDistanceTooLow(String min);

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'KES/km'**
  String get unitPerKm;

  /// Phase 2 rider side / tracking.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// Server error code invalid_request (400 fallback).
  ///
  /// In en, this message translates to:
  /// **'Some details aren\'t valid. Check them and try again.'**
  String get errCodeInvalidRequest;

  /// Server error code unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please sign in again.'**
  String get errCodeUnauthorized;

  /// Server error code forbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get errCodeForbidden;

  /// Server error code not_found.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find that. It may have been removed.'**
  String get errCodeNotFound;

  /// Server error code conflict: an order action lost a race; the app has already re-read and is showing the current state.
  ///
  /// In en, this message translates to:
  /// **'This was updated in the meantime. Showing the latest.'**
  String get errCodeConflict;

  /// Server error code invalid_status: the order is not in a status that allows this action.
  ///
  /// In en, this message translates to:
  /// **'This order has moved on. Refresh and try again.'**
  String get errCodeInvalidStatus;

  /// Server error code file_too_large.
  ///
  /// In en, this message translates to:
  /// **'The file is too large. Use one under 10 MB.'**
  String get errCodeFileTooLarge;

  /// Server error code internal_error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Please try again.'**
  String get errCodeInternalError;

  /// Server error code upstream_unavailable.
  ///
  /// In en, this message translates to:
  /// **'A service we rely on isn\'t responding. Please try again.'**
  String get errCodeUpstreamUnavailable;

  /// Server error code service_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t available right now. Please try again later.'**
  String get errCodeServiceUnavailable;

  /// Server error code invalid_name.
  ///
  /// In en, this message translates to:
  /// **'Names must be 1 to 50 characters.'**
  String get errCodeInvalidName;

  /// Server error code missing_fields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all required fields.'**
  String get errCodeMissingFields;

  /// Server error code password_breached.
  ///
  /// In en, this message translates to:
  /// **'This password has appeared in a data breach. Choose a different one.'**
  String get errCodePasswordBreached;

  /// Server error code password_reused.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from the current one.'**
  String get errCodePasswordReused;

  /// Server error code session_expired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errCodeSessionExpired;

  /// Server error code email_not_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email first with the code we sent you.'**
  String get errCodeEmailNotConfirmed;

  /// Server error code errand_unavailable (errands are post-beta).
  ///
  /// In en, this message translates to:
  /// **'Errands aren\'t available yet.'**
  String get errCodeErrandUnavailable;

  /// Server error code unknown_category.
  ///
  /// In en, this message translates to:
  /// **'Choose an item category from the list.'**
  String get errCodeUnknownCategory;

  /// Server error code category_not_allowed (e.g. prohibited at beta).
  ///
  /// In en, this message translates to:
  /// **'This item can\'t be sent with RideLink.'**
  String get errCodeCategoryNotAllowed;

  /// Server error code order_not_editable.
  ///
  /// In en, this message translates to:
  /// **'The route can\'t be changed any more.'**
  String get errCodeOrderNotEditable;

  /// Server error code order_not_cancellable.
  ///
  /// In en, this message translates to:
  /// **'This order can no longer be cancelled.'**
  String get errCodeOrderNotCancellable;

  /// Server error code order_unavailable (taken or withdrawn).
  ///
  /// In en, this message translates to:
  /// **'This order is no longer available.'**
  String get errCodeOrderUnavailable;

  /// Server error code no_active_offer.
  ///
  /// In en, this message translates to:
  /// **'There\'s no open request on this order.'**
  String get errCodeNoActiveOffer;

  /// Server error code offer_not_for_you.
  ///
  /// In en, this message translates to:
  /// **'This request was sent to another rider.'**
  String get errCodeOfferNotForYou;

  /// Server error code rider_not_available.
  ///
  /// In en, this message translates to:
  /// **'This rider can\'t take the order right now. Choose another rider.'**
  String get errCodeRiderNotAvailable;

  /// Server error code rider_not_found.
  ///
  /// In en, this message translates to:
  /// **'Rider not found.'**
  String get errCodeRiderNotFound;

  /// Server error code rider_already_registered.
  ///
  /// In en, this message translates to:
  /// **'You\'re already registered as a rider.'**
  String get errCodeRiderAlreadyRegistered;

  /// Server error code rider_not_verified.
  ///
  /// In en, this message translates to:
  /// **'Only verified riders can go online.'**
  String get errCodeRiderNotVerified;

  /// Server error code documents_missing.
  ///
  /// In en, this message translates to:
  /// **'Some required documents are missing or expired.'**
  String get errCodeDocumentsMissing;

  /// Server error code rider_paused.
  ///
  /// In en, this message translates to:
  /// **'You\'re paused after missed pickups. Try again after the pause ends.'**
  String get errCodeRiderPaused;

  /// Server error code location_required.
  ///
  /// In en, this message translates to:
  /// **'We need your current location. Turn on location and try again.'**
  String get errCodeLocationRequired;

  /// Server error code location_stale.
  ///
  /// In en, this message translates to:
  /// **'Your location is out of date. Wait a moment and try again.'**
  String get errCodeLocationStale;

  /// Server error code too_far_from_pickup.
  ///
  /// In en, this message translates to:
  /// **'You\'re too far from the pickup point.'**
  String get errCodeTooFarFromPickup;

  /// Server error code pickup_window_passed.
  ///
  /// In en, this message translates to:
  /// **'The pickup time has passed.'**
  String get errCodePickupWindowPassed;

  /// Server error code already_arrived.
  ///
  /// In en, this message translates to:
  /// **'Your arrival is already recorded.'**
  String get errCodeAlreadyArrived;

  /// Server error code value_out_of_range.
  ///
  /// In en, this message translates to:
  /// **'A value is outside the allowed range.'**
  String get errCodeValueOutOfRange;

  /// Server error code invalid_file_type.
  ///
  /// In en, this message translates to:
  /// **'This file type isn\'t accepted.'**
  String get errCodeInvalidFileType;

  /// Server error code photo_not_found.
  ///
  /// In en, this message translates to:
  /// **'Photo not available.'**
  String get errCodePhotoNotFound;

  /// Server error code already_rated.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already rated this order.'**
  String get errCodeAlreadyRated;

  /// Server error code no_agreed_price.
  ///
  /// In en, this message translates to:
  /// **'This order has no agreed price yet.'**
  String get errCodeNoAgreedPrice;

  /// Server error code reserved_event_type.
  ///
  /// In en, this message translates to:
  /// **'Only RideLink can add this entry to the record.'**
  String get errCodeReservedEventType;

  /// Server error code invalid_media_kind.
  ///
  /// In en, this message translates to:
  /// **'This photo type isn\'t accepted.'**
  String get errCodeInvalidMediaKind;

  /// Server error code invalid_hash.
  ///
  /// In en, this message translates to:
  /// **'The photo couldn\'t be verified. Please try again.'**
  String get errCodeInvalidHash;

  /// Server error code hash_mismatch: the server's SHA-256 of the photo differs from the device's.
  ///
  /// In en, this message translates to:
  /// **'The photo changed during upload. Please try again.'**
  String get errCodeHashMismatch;

  /// Screen 10 title and the link to it from tracking, the job and history.
  ///
  /// In en, this message translates to:
  /// **'Evidence record'**
  String get evidenceTitle;

  /// Short explanation at the top of the evidence record.
  ///
  /// In en, this message translates to:
  /// **'Every step of this order is recorded in a tamper-evident chain. Anyone can check it has not been changed.'**
  String get evidenceIntro;

  /// Heading above the list of evidence events.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get evidenceTimelineTitle;

  /// Evidence record with no events.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been recorded yet.'**
  String get evidenceEmpty;

  /// Evidence record failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the evidence record.'**
  String get evidenceLoadFailed;

  /// Button that asks the server to recompute every hash in the chain.
  ///
  /// In en, this message translates to:
  /// **'Verify record'**
  String get evidenceVerifyButton;

  /// Verify button after a result is shown.
  ///
  /// In en, this message translates to:
  /// **'Verify again'**
  String get evidenceVerifyAgain;

  /// The verify call itself failed (network or server).
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the record right now.'**
  String get evidenceVerifyFailed;

  /// Verification result: the chain is unchanged.
  ///
  /// In en, this message translates to:
  /// **'Record intact'**
  String get evidenceIntactTitle;

  /// Verification result body with the number of events.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event checked. Nothing has been changed.} other{{count} events checked. Nothing has been changed.}}'**
  String evidenceIntactBody(int count);

  /// Verification result: the chain does not match.
  ///
  /// In en, this message translates to:
  /// **'Record does not verify'**
  String get evidenceTamperedTitle;

  /// Verification failed: tampered or damaged chain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event checked. The chain does not match, so this record may have been altered.} other{{count} events checked. The chain does not match, so this record may have been altered.}}'**
  String evidenceTamperedBody(int count);

  /// Short preview of an event hash, shown in mono.
  ///
  /// In en, this message translates to:
  /// **'Hash {hash}'**
  String evidenceHash(String hash);

  /// Accessibility label for an evidence photo thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Open photo'**
  String get evidenceOpenPhoto;

  /// Who recorded an evidence event: the current user.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get evidenceActorYou;

  /// Who recorded an evidence event: the rider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get evidenceActorRider;

  /// Who recorded an evidence event: the sender (deliveries).
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get evidenceActorSender;

  /// Who recorded an evidence event: the passenger (rides).
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get evidenceActorPassenger;

  /// Who recorded an evidence event when the role is unknown.
  ///
  /// In en, this message translates to:
  /// **'Other party'**
  String get evidenceActorOtherParty;

  /// Event recorded by the system.
  ///
  /// In en, this message translates to:
  /// **'RideLink'**
  String get evidenceActorRideLink;

  /// Evidence photo kind pickup_photo.
  ///
  /// In en, this message translates to:
  /// **'Pickup photo'**
  String get evidencePickupPhoto;

  /// Evidence photo kind handover_photo (deliveries).
  ///
  /// In en, this message translates to:
  /// **'Handover photo'**
  String get evidenceHandoverPhoto;

  /// Evidence photo kind handover_photo on a ride.
  ///
  /// In en, this message translates to:
  /// **'Drop-off photo'**
  String get evidenceDropoffPhoto;

  /// Evidence photo kind item_photo (sender, before pickup).
  ///
  /// In en, this message translates to:
  /// **'Item photo'**
  String get evidenceItemPhoto;

  /// Rider, delivery pickup.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the item as you collect it.'**
  String get evidencePickupPhotoHint;

  /// Rider, delivery handover.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the item as you hand it over.'**
  String get evidenceHandoverPhotoHint;

  /// Sender, optional item photo before pickup.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the item before the rider collects it.'**
  String get evidenceItemPhotoHint;

  /// Opens the camera for an evidence photo.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get evidenceTakePhoto;

  /// Take a new evidence photo after a failed upload.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get evidenceRetake;

  /// Shown with the upload progress bar.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get evidenceUploading;

  /// Evidence photo upload failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t upload the photo. Check your connection and try again.'**
  String get evidenceUploadFailed;

  /// Evidence photo uploaded and chained.
  ///
  /// In en, this message translates to:
  /// **'Photo added to the evidence record'**
  String get evidencePhotoAdded;

  /// Evidence event payment_requested.
  ///
  /// In en, this message translates to:
  /// **'Payment requested'**
  String get evidenceEventPaymentRequested;

  /// Evidence event cash_payment_sent.
  ///
  /// In en, this message translates to:
  /// **'Cash marked as paid'**
  String get evidenceEventCashSent;

  /// Evidence event cash_payment_received.
  ///
  /// In en, this message translates to:
  /// **'Cash received'**
  String get evidenceEventCashReceived;

  /// Evidence event cash_payment_disputed.
  ///
  /// In en, this message translates to:
  /// **'Cash reported not received'**
  String get evidenceEventCashDisputed;

  /// Marks an optional step.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// Rating sheet title for the sender.
  ///
  /// In en, this message translates to:
  /// **'Rate your rider'**
  String get rateRiderTitle;

  /// Rating sheet title for the rider on a delivery.
  ///
  /// In en, this message translates to:
  /// **'Rate the sender'**
  String get rateSenderTitle;

  /// Rating sheet title for the rider on a ride.
  ///
  /// In en, this message translates to:
  /// **'Rate your passenger'**
  String get ratePassengerTitle;

  /// Rating sheet subtitle.
  ///
  /// In en, this message translates to:
  /// **'How did it go? Your rating helps keep RideLink trustworthy.'**
  String get rateBody;

  /// Accessibility label for a star score.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String ratingStarsLabel(int count);

  /// Optional rating comment field label.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get ratingCommentLabel;

  /// Rating comment field hint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get ratingCommentHint;

  /// Submit the rating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get ratingSubmit;

  /// Close the rating sheet without rating.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ratingSkip;

  /// Shown after a rating is saved.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your rating.'**
  String get ratingThanks;

  /// Rating submit failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your rating. Please try again.'**
  String get ratingFailed;

  /// Order detail: the rating you gave.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// Order detail: no rating given yet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t rated this order.'**
  String get notRatedYet;

  /// Order detail: open the rating sheet.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateButton;

  /// Notifications screen title and bell tooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Empty notifications list.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// Notifications failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load notifications.'**
  String get notificationsLoadFailed;

  /// Notification payment_requested (to the sender).
  ///
  /// In en, this message translates to:
  /// **'Payment requested'**
  String get notifPaymentRequestedTitle;

  /// Notification payment_requested body.
  ///
  /// In en, this message translates to:
  /// **'Your rider has arrived. Pay {amount} by cash or M-Pesa.'**
  String notifPaymentRequestedBody(String amount);

  /// Notification payment_requested body without an amount.
  ///
  /// In en, this message translates to:
  /// **'Your rider has arrived. Pay the agreed amount by cash or M-Pesa.'**
  String get notifPaymentRequestedBodyNoAmount;

  /// Notification payment_sent (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Cash payment sent'**
  String get notifPaymentSentTitle;

  /// Notification payment_sent body.
  ///
  /// In en, this message translates to:
  /// **'The sender says they have paid {amount}. Confirm when you have the cash.'**
  String notifPaymentSentBody(String amount);

  /// Notification payment_sent body without an amount.
  ///
  /// In en, this message translates to:
  /// **'The sender says they have paid. Confirm when you have the cash.'**
  String get notifPaymentSentBodyNoAmount;

  /// Notification payment_confirmed (to the sender).
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get notifPaymentConfirmedTitle;

  /// Notification payment_confirmed body (to the sender; the order is complete).
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Your order is complete.'**
  String get notifPaymentConfirmedBody;

  /// Notification payment_unresolved (to the rider only).
  ///
  /// In en, this message translates to:
  /// **'Payment unresolved'**
  String get notifPaymentUnresolvedTitle;

  /// Notification payment_unresolved body (to the rider).
  ///
  /// In en, this message translates to:
  /// **'You reported this order as not paid. RideLink will review this order.'**
  String get notifPaymentUnresolvedBody;

  /// Notification pickup_arrived (to the sender).
  ///
  /// In en, this message translates to:
  /// **'Your rider has arrived'**
  String get notifPickupArrivedTitle;

  /// Notification pickup_arrived body.
  ///
  /// In en, this message translates to:
  /// **'Your rider is at the pickup point.'**
  String get notifPickupArrivedBody;

  /// Notification pickup_timeout (to the sender).
  ///
  /// In en, this message translates to:
  /// **'Your rider didn\'t reach pickup in time'**
  String get notifPickupTimeoutTitle;

  /// Notification pickup_timeout body.
  ///
  /// In en, this message translates to:
  /// **'The order was cancelled. You can book another rider.'**
  String get notifPickupTimeoutBody;

  /// Notification pickup_timeout_rider (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Pickup window missed'**
  String get notifPickupTimeoutRiderTitle;

  /// Notification pickup_timeout_rider body.
  ///
  /// In en, this message translates to:
  /// **'The order was cancelled because you didn\'t reach the pickup in time. Missed pickups count toward a pause.'**
  String get notifPickupTimeoutRiderBody;

  /// Notification receiver_location_shared (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Receiver shared their location'**
  String get notifReceiverLocationTitle;

  /// Notification receiver_location_shared body.
  ///
  /// In en, this message translates to:
  /// **'The receiver pinned their exact drop-off spot. Open the order to see it.'**
  String get notifReceiverLocationBody;

  /// Notification document_expiring title; doc is the localized document name.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Your {doc} expires today} =1{Your {doc} expires tomorrow} other{Your {doc} expires in {days} days}}'**
  String notifDocumentExpiringTitle(String doc, int days);

  /// Notification document_expiring body.
  ///
  /// In en, this message translates to:
  /// **'Upload a renewed document before {date} to keep receiving orders.'**
  String notifDocumentExpiringBody(String date);

  /// Notification document_expired title.
  ///
  /// In en, this message translates to:
  /// **'Your {doc} has expired'**
  String notifDocumentExpiredTitle(String doc);

  /// Notification document_expired body.
  ///
  /// In en, this message translates to:
  /// **'You can\'t go online until a valid replacement is approved.'**
  String get notifDocumentExpiredBody;

  /// Drawer entry to order history.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get menuHistory;

  /// Drawer entry to the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get menuProfile;

  /// Profile screen title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile.'**
  String get profileLoadFailed;

  /// Save the edited names.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSave;

  /// Names saved.
  ///
  /// In en, this message translates to:
  /// **'Your name was updated.'**
  String get profileSaved;

  /// Names save failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your name. Please try again.'**
  String get profileSaveFailed;

  /// Note under the name fields.
  ///
  /// In en, this message translates to:
  /// **'Others see your first name and last initial, like \"Moses O.\"'**
  String get profileNameShownAs;

  /// Verified riders cannot rename themselves (auth-onboarding decision 15).
  ///
  /// In en, this message translates to:
  /// **'Your name matches your verified ID, so it can\'t be changed here. To change it, contact RideLink support.'**
  String get profileNameLocked;

  /// Profile row label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// The app has no language switch; it follows the device.
  ///
  /// In en, this message translates to:
  /// **'Follows your phone\'s language'**
  String get profileLanguageValue;

  /// History screen title (sender side).
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get historyTitle;

  /// History screen title (rider side).
  ///
  /// In en, this message translates to:
  /// **'Trip history'**
  String get historyRiderTitle;

  /// Empty history.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get historyEmpty;

  /// History failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your orders.'**
  String get historyLoadFailed;

  /// History row: the pickup address.
  ///
  /// In en, this message translates to:
  /// **'From {place}'**
  String historyFrom(String place);

  /// Order detail screen title.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetailTitle;

  /// Order detail failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this order.'**
  String get orderLoadFailed;

  /// Order detail: jump to tracking or the rider job while it runs.
  ///
  /// In en, this message translates to:
  /// **'Open live order'**
  String get openLiveOrder;

  /// Order detail: label above the rider name.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get detailRider;

  /// Order detail: label above the sender name.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get detailSender;

  /// Order detail: label above the passenger name.
  ///
  /// In en, this message translates to:
  /// **'Passenger'**
  String get detailPassenger;

  /// Order status created.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusCreated;

  /// Order status offered.
  ///
  /// In en, this message translates to:
  /// **'Waiting for rider'**
  String get statusOffered;

  /// Order status accepted.
  ///
  /// In en, this message translates to:
  /// **'Rider on the way'**
  String get statusAccepted;

  /// Order status started / in_transit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get statusInTransit;

  /// Order status arrived.
  ///
  /// In en, this message translates to:
  /// **'At drop-off'**
  String get statusArrived;

  /// Order status payment_requested / cash_pending.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get statusPayment;

  /// Order status paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get statusPaid;

  /// Order status handed_over (delivery).
  ///
  /// In en, this message translates to:
  /// **'Handed over'**
  String get statusHandedOver;

  /// Order status handed_over (ride).
  ///
  /// In en, this message translates to:
  /// **'Dropped off'**
  String get statusDroppedOff;

  /// Order status completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// Order status cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// Order status expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// Order status payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get statusPaymentFailed;

  /// Order status unresolved.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get statusUnresolved;

  /// Sender tracking: create the receiver link and open the share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share with receiver'**
  String get shareWithReceiver;

  /// Note under the share button.
  ///
  /// In en, this message translates to:
  /// **'The receiver can follow the delivery and pin their exact spot for the rider.'**
  String get shareWithReceiverNote;

  /// Message sent through the Android share sheet with the receiver link.
  ///
  /// In en, this message translates to:
  /// **'Your RideLink delivery is on its way. Follow it and share your exact location with the rider here: {url}'**
  String receiverShareMessage(String url);

  /// Receiver link creation failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the receiver link. Please try again.'**
  String get receiverLinkFailed;

  /// Rider job: the receiver shared their location.
  ///
  /// In en, this message translates to:
  /// **'The receiver pinned their exact spot'**
  String get receiverSpotTitle;

  /// Rider job: the receiver's landmark note.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String receiverSpotNote(String note);

  /// Rider job: open Google Maps navigation to the pickup.
  ///
  /// In en, this message translates to:
  /// **'Navigate to pickup'**
  String get navigateToPickup;

  /// Rider job: open Google Maps navigation to the drop-off.
  ///
  /// In en, this message translates to:
  /// **'Navigate to drop-off'**
  String get navigateToDropoff;

  /// Rider job: navigate to the receiver's pinned spot.
  ///
  /// In en, this message translates to:
  /// **'Navigate to receiver\'s spot'**
  String get navigateToReceiver;

  /// No app could handle the navigation hand-off.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Google Maps on this phone.'**
  String get navigateFailed;

  /// Rider job: the sender display name.
  ///
  /// In en, this message translates to:
  /// **'Sender: {name}'**
  String senderIs(String name);

  /// Rider job: the passenger display name.
  ///
  /// In en, this message translates to:
  /// **'Passenger: {name}'**
  String passengerIs(String name);

  /// Rider tried to switch to sending during a job.
  ///
  /// In en, this message translates to:
  /// **'Finish your job first'**
  String get switchMidJobTitle;

  /// Body of the mid-job switch dialog.
  ///
  /// In en, this message translates to:
  /// **'You can switch to sending once this job is complete.'**
  String get switchMidJobBody;

  /// Online rider tries to switch to sending.
  ///
  /// In en, this message translates to:
  /// **'Go offline to switch?'**
  String get switchGoOfflineTitle;

  /// Body of the go-offline dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop getting requests while you send.'**
  String get switchGoOfflineBody;

  /// Confirm going offline and switching.
  ///
  /// In en, this message translates to:
  /// **'Go offline'**
  String get switchGoOfflineConfirm;

  /// Cancel the switch.
  ///
  /// In en, this message translates to:
  /// **'Stay online'**
  String get switchStayOnline;

  /// Going offline failed, so the switch was stopped.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t go offline. Please try again.'**
  String get switchGoOfflineFailed;

  /// Sender tracking after the pickup deadline, until the server cancels.
  ///
  /// In en, this message translates to:
  /// **'Your rider is running late'**
  String get riderRunningLate;

  /// Rider job after the pickup deadline.
  ///
  /// In en, this message translates to:
  /// **'Running late'**
  String get jobRunningLate;

  /// Rider job after the pickup deadline.
  ///
  /// In en, this message translates to:
  /// **'The pickup window has passed. RideLink will cancel this order shortly.'**
  String get jobRunningLateBody;

  /// Rider job title after pickup on a ride.
  ///
  /// In en, this message translates to:
  /// **'Passenger picked up'**
  String get jobPassengerPickedUp;

  /// Rider job action at pickup on a ride.
  ///
  /// In en, this message translates to:
  /// **'Passenger picked up'**
  String get actionPassengerPickedUp;

  /// Rider job at pickup on a ride.
  ///
  /// In en, this message translates to:
  /// **'Arrival recorded. Once your passenger is on, tap Passenger picked up.'**
  String get jobAtPickupNoteRide;

  /// Rider job at drop-off on a ride.
  ///
  /// In en, this message translates to:
  /// **'Request payment from your passenger before they get off.'**
  String get jobAtDropoffBodyRide;

  /// Rider job, ride paid.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed. Mark the passenger dropped off below.'**
  String get jobPaidBodyRide;

  /// Rider job title after drop-off on a ride.
  ///
  /// In en, this message translates to:
  /// **'Passenger dropped off'**
  String get jobPassengerDroppedOff;

  /// Rider job action at drop-off on a ride.
  ///
  /// In en, this message translates to:
  /// **'Passenger dropped off'**
  String get actionPassengerDroppedOff;

  /// Rider job title when a ride is complete.
  ///
  /// In en, this message translates to:
  /// **'Ride complete'**
  String get jobRideComplete;

  /// Rider job action to complete a ride.
  ///
  /// In en, this message translates to:
  /// **'Complete ride'**
  String get actionCompleteRide;

  /// Rider job, ride cancelled by the passenger.
  ///
  /// In en, this message translates to:
  /// **'The passenger cancelled this ride.'**
  String get jobCancelledByPassenger;

  /// Server error code evidence_photo_required without a known kind: a delivery step needs its evidence photo first.
  ///
  /// In en, this message translates to:
  /// **'Take the required photo first.'**
  String get errCodeEvidencePhotoRequired;

  /// Server error code evidence_photo_required, kind pickup_photo.
  ///
  /// In en, this message translates to:
  /// **'Take the pickup photo before marking the item picked up.'**
  String get errCodeEvidencePickupPhotoRequired;

  /// Server error code evidence_photo_required, kind handover_photo.
  ///
  /// In en, this message translates to:
  /// **'Take the handover photo before marking the item handed over.'**
  String get errCodeEvidenceHandoverPhotoRequired;

  /// Rider delivery job: shown above the disabled Picked up button until the pickup photo is uploaded.
  ///
  /// In en, this message translates to:
  /// **'Take the pickup photo to continue.'**
  String get jobPickupPhotoRequired;

  /// Rider delivery job: shown above the disabled Hand over button until the handover photo is uploaded.
  ///
  /// In en, this message translates to:
  /// **'Take the handover photo to continue.'**
  String get jobHandoverPhotoRequired;

  /// Pickup label for the sender's GPS position when no address could be found. Shown on this device only; the order stores coordinates.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocationLabel;

  /// Pickup label on Confirm pickup when the map pin's address could not be found.
  ///
  /// In en, this message translates to:
  /// **'Pinned location'**
  String get pinnedLocationLabel;

  /// Action on the pickup row: opens place search to change the pickup.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeButton;

  /// Primary button on the Confirm pickup screen.
  ///
  /// In en, this message translates to:
  /// **'Confirm pickup'**
  String get confirmPickupButton;

  /// Secondary button on the Confirm pickup screen: opens place search.
  ///
  /// In en, this message translates to:
  /// **'Search instead'**
  String get searchInsteadButton;

  /// Confirm pickup screen heading for rides.
  ///
  /// In en, this message translates to:
  /// **'Confirm your pickup spot'**
  String get confirmPickupRideTitle;

  /// Confirm pickup screen heading for deliveries.
  ///
  /// In en, this message translates to:
  /// **'Confirm where the rider collects the item'**
  String get confirmPickupDeliveryTitle;

  /// Confirm pickup helper line; shown only when the map can be panned.
  ///
  /// In en, this message translates to:
  /// **'Move the map to the exact spot'**
  String get confirmPickupHelper;

  /// Pickup row while the current location is being read for the default pickup.
  ///
  /// In en, this message translates to:
  /// **'Finding your location'**
  String get findingLocationLabel;

  /// Android notification channel name for rider offers (shown in system settings).
  ///
  /// In en, this message translates to:
  /// **'New offers'**
  String get pushChannelOffersName;

  /// Android notification channel description for rider offers.
  ///
  /// In en, this message translates to:
  /// **'Delivery and ride offers waiting for your answer'**
  String get pushChannelOffersDescription;

  /// Android notification channel name for all other pushes.
  ///
  /// In en, this message translates to:
  /// **'Order updates'**
  String get pushChannelUpdatesName;

  /// Android notification channel description for other pushes.
  ///
  /// In en, this message translates to:
  /// **'Changes to your orders and account'**
  String get pushChannelUpdatesDescription;

  /// System notification title for a rider offer (push type offer.received).
  ///
  /// In en, this message translates to:
  /// **'New offer'**
  String get pushOfferTitle;

  /// System notification body for a rider offer.
  ///
  /// In en, this message translates to:
  /// **'Open RideLink to see it before it expires.'**
  String get pushOfferBody;

  /// System notification title for document expiring/expired pushes (no document details in the push).
  ///
  /// In en, this message translates to:
  /// **'Check your documents'**
  String get pushDocumentTitle;

  /// System notification body for document pushes.
  ///
  /// In en, this message translates to:
  /// **'One of your rider documents needs attention.'**
  String get pushDocumentBody;

  /// System notification title for a push type this build doesn't know.
  ///
  /// In en, this message translates to:
  /// **'Order update'**
  String get pushGenericTitle;

  /// System notification body for an unknown push type.
  ///
  /// In en, this message translates to:
  /// **'Open RideLink to see what changed.'**
  String get pushGenericBody;

  /// Dialog title before asking riders for the notification permission.
  ///
  /// In en, this message translates to:
  /// **'Get offers as notifications'**
  String get notifPermissionTitle;

  /// Dialog body explaining why riders should allow notifications.
  ///
  /// In en, this message translates to:
  /// **'New delivery and ride offers arrive as notifications, even when RideLink is closed. Each offer is open only for a short time.'**
  String get notifPermissionBody;

  /// Dialog button that shows the system notification permission prompt.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get notifPermissionContinue;

  /// Dialog button that skips the notification permission prompt.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notifPermissionNotNow;

  /// Reminder under the rider's online toggle when notifications are not allowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off. You won\'t hear new offers while RideLink is closed.'**
  String get notifOffReminder;

  /// Button in the notifications-off reminder.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get notifOffTurnOn;

  /// Destructive button on the profile screen and in the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountButton;

  /// Delete account explanation screen title.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get deleteAccountTitle;

  /// Delete account explanation intro.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account is permanent and signs you out.'**
  String get deleteAccountIntro;

  /// Delete account explanation section heading.
  ///
  /// In en, this message translates to:
  /// **'What is deleted'**
  String get deleteAccountDeletedHeading;

  /// What deleting the account removes.
  ///
  /// In en, this message translates to:
  /// **'Your name, email address and rider documents.'**
  String get deleteAccountDeletedBody;

  /// Delete account explanation section heading.
  ///
  /// In en, this message translates to:
  /// **'What is kept, without your name'**
  String get deleteAccountKeptHeading;

  /// What is kept after deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Past orders and their evidence records, for disputes and tax.'**
  String get deleteAccountKeptBody;

  /// Button on the explanation screen that opens the confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get deleteAccountContinue;

  /// Confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountConfirmTitle;

  /// Confirmation dialog body; {word} is deleteAccountConfirmWord.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm.'**
  String deleteAccountConfirmBody(String word);

  /// The word the user must type to confirm account deletion.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get deleteAccountConfirmWord;

  /// Confirmation dialog cancel button.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get deleteAccountKeep;

  /// Shown when account deletion fails for a network or server reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Try again.'**
  String get deleteAccountFailed;

  /// Shown on the sign-in screen after the account was deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeletedNotice;

  /// Error code account_has_active_order (deleting the account while an order is active).
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel your active order first.'**
  String get errCodeAccountHasActiveOrder;

  /// Error code legal_acceptance_required; also shown when the sign-up checkbox is not ticked.
  ///
  /// In en, this message translates to:
  /// **'Agree to the Terms of Service and Privacy Policy to continue.'**
  String get errCodeLegalAcceptanceRequired;

  /// Required checkbox label at sign-up (and before Google sign-in).
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get legalAgreeLabel;

  /// Link that opens the Terms of Service in the browser.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsLink;

  /// Link that opens the Privacy Policy in the browser.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyLink;

  /// Shown when GET /legal fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the Terms of Service and Privacy Policy. Check your connection and try again.'**
  String get legalLoadFailed;

  /// Shown when no browser or store app could open a link.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get linkOpenFailed;

  /// Blocking screen title when updated terms must be accepted.
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our terms'**
  String get legalUpdateTitle;

  /// Blocking terms-update screen body.
  ///
  /// In en, this message translates to:
  /// **'Read the updated Terms of Service and Privacy Policy. To keep using RideLink, accept them.'**
  String get legalUpdateBody;

  /// Button that accepts the updated terms.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get legalUpdateAccept;

  /// Shown when POST /legal/accept fails for a network or server reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your answer. Try again.'**
  String get legalUpdateAcceptFailed;

  /// Data-protection notice above the rider document checklist.
  ///
  /// In en, this message translates to:
  /// **'Your documents are used only to verify you, stored privately, and deleted if you delete your account.'**
  String get documentsPrivacyNotice;

  /// Blocking screen title when the installed version is below the minimum.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateRequiredTitle;

  /// Blocking update-required screen body.
  ///
  /// In en, this message translates to:
  /// **'This version of RideLink is no longer supported. Update the app to continue.'**
  String get updateRequiredBody;

  /// Button that opens the store page.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateRequiredButton;

  /// Error code account_deleted (401: the account was deleted; the app signs out locally).
  ///
  /// In en, this message translates to:
  /// **'This account has been deleted.'**
  String get errCodeAccountDeleted;

  /// Payment method: cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payMethodCash;

  /// Payment method: M-Pesa Buy Goods till.
  ///
  /// In en, this message translates to:
  /// **'M-Pesa Till'**
  String get payMethodMpesaTill;

  /// Payment method: M-Pesa Pochi la Biashara (product name).
  ///
  /// In en, this message translates to:
  /// **'Pochi la Biashara'**
  String get payMethodMpesaPochi;

  /// Payment method: M-Pesa Send Money.
  ///
  /// In en, this message translates to:
  /// **'Send Money'**
  String get payMethodMpesaSendMoney;

  /// Optional M-Pesa transaction code field label.
  ///
  /// In en, this message translates to:
  /// **'M-Pesa code (optional)'**
  String get mpesaCodeLabel;

  /// Helper under the M-Pesa code field.
  ///
  /// In en, this message translates to:
  /// **'The 10-character code from the M-Pesa message.'**
  String get mpesaCodeHelp;

  /// M-Pesa code validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter the 10-character M-Pesa code, or leave it empty.'**
  String get mpesaCodeInvalid;

  /// Rider job payment step: label above the dominant amount.
  ///
  /// In en, this message translates to:
  /// **'Amount to collect'**
  String get collectPaymentLabel;

  /// Rider job payment step: method picker heading.
  ///
  /// In en, this message translates to:
  /// **'How were you paid?'**
  String get paymentHowPaidLabel;

  /// Rider job payment step: GET /orders/{id}/payment failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the M-Pesa details for this order. Cash is still available.'**
  String get paymentMethodsLoadFailed;

  /// Sender tracking: payment card title while payment_requested.
  ///
  /// In en, this message translates to:
  /// **'Pay your rider'**
  String get payYourRiderTitle;

  /// The account name the payer should see in M-Pesa.
  ///
  /// In en, this message translates to:
  /// **'Name in M-Pesa: {name}'**
  String nameInMpesa(String name);

  /// Tooltip on the copy button next to an M-Pesa number.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumber;

  /// Snack after copying an M-Pesa number.
  ///
  /// In en, this message translates to:
  /// **'Number copied'**
  String get numberCopied;

  /// Sender tracking: payment details failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your rider\'s payment details.'**
  String get paymentDetailsLoadFailed;

  /// Sender: prompt after the rider reported not paid.
  ///
  /// In en, this message translates to:
  /// **'Your rider says this order wasn\'t paid. Did you pay?'**
  String get payerPromptTitle;

  /// Sender payer response: yes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I paid'**
  String get payerYes;

  /// Sender payer response: no.
  ///
  /// In en, this message translates to:
  /// **'No, I didn\'t pay'**
  String get payerNo;

  /// Sender payer response: method heading.
  ///
  /// In en, this message translates to:
  /// **'How did you pay?'**
  String get payerHowPaidLabel;

  /// Sender payer response: submit button.
  ///
  /// In en, this message translates to:
  /// **'Send answer'**
  String get payerSubmit;

  /// Sender payer response: shown after answering.
  ///
  /// In en, this message translates to:
  /// **'Thanks, RideLink will review this order.'**
  String get payerThanks;

  /// Sender payer response: request failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your answer. Try again.'**
  String get payerResponseFailed;

  /// Error code payment_details_hidden (422).
  ///
  /// In en, this message translates to:
  /// **'Payment details are shown only while your rider is requesting payment.'**
  String get errCodePaymentDetailsHidden;

  /// Evidence event payment_details_viewed.
  ///
  /// In en, this message translates to:
  /// **'Payment details viewed'**
  String get evidenceEventPaymentDetailsViewed;

  /// Evidence event payment_received.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get evidenceEventPaymentReceived;

  /// Evidence event payment_not_received.
  ///
  /// In en, this message translates to:
  /// **'Reported not paid'**
  String get evidenceEventPaymentNotReceived;

  /// Evidence event payer_payment_response.
  ///
  /// In en, this message translates to:
  /// **'Payer answered about payment'**
  String get evidenceEventPayerResponse;

  /// Rider payment methods screen title and home tile.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethodsTitle;

  /// Rider home tile subtitle for payment methods.
  ///
  /// In en, this message translates to:
  /// **'Cash, and M-Pesa if you add it'**
  String get paymentMethodsNavSubtitle;

  /// Rider payment methods intro note.
  ///
  /// In en, this message translates to:
  /// **'Customers see your M-Pesa details only when you request payment, and only for that order.'**
  String get paymentMethodsIntro;

  /// Rider payment methods: snapshot-at-acceptance note.
  ///
  /// In en, this message translates to:
  /// **'Changes apply to new orders. An accepted order keeps the details it was accepted with.'**
  String get paymentMethodsFootnote;

  /// Cash row badge: cash cannot be removed.
  ///
  /// In en, this message translates to:
  /// **'Always accepted'**
  String get cashAlwaysAccepted;

  /// M-Pesa method row with no details yet.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get paymentMethodNotAdded;

  /// Add an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get paymentMethodAdd;

  /// Edit an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get paymentMethodEdit;

  /// Remove an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get paymentMethodRemove;

  /// Confirm removing an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Remove {method}?'**
  String paymentMethodRemoveTitle(String method);

  /// Confirm removing an M-Pesa method: body.
  ///
  /// In en, this message translates to:
  /// **'Customers won\'t see it on new orders.'**
  String get paymentMethodRemoveBody;

  /// Snack after saving an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get paymentMethodSaved;

  /// Snack after removing an M-Pesa method.
  ///
  /// In en, this message translates to:
  /// **'Payment method removed'**
  String get paymentMethodRemoved;

  /// Removing an M-Pesa method failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove. Try again.'**
  String get paymentMethodRemoveFailed;

  /// Rider payment methods failed to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your payment methods.'**
  String get paymentMethodsLoadError;

  /// M-Pesa Till number field label.
  ///
  /// In en, this message translates to:
  /// **'Till number'**
  String get tillNumberLabel;

  /// Pochi / Send Money phone field label.
  ///
  /// In en, this message translates to:
  /// **'M-Pesa phone number'**
  String get mpesaPhoneLabel;

  /// M-Pesa account name field label.
  ///
  /// In en, this message translates to:
  /// **'Name shown in M-Pesa'**
  String get mpesaNameLabel;

  /// Helper under the M-Pesa name field.
  ///
  /// In en, this message translates to:
  /// **'The name customers see when they pay you.'**
  String get mpesaNameHelp;

  /// Till number validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter a till number of 5 to 8 digits.'**
  String get tillNumberInvalid;

  /// Pochi / Send Money number validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter a Kenyan mobile number, e.g. 0712345678.'**
  String get mpesaPhoneInvalid;

  /// M-Pesa name validation error.
  ///
  /// In en, this message translates to:
  /// **'Enter 2 to 60 characters.'**
  String get mpesaNameInvalid;

  /// Notification payer_payment_response (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Payment answer received'**
  String get notifPayerResponseTitle;

  /// Notification payer_payment_response body.
  ///
  /// In en, this message translates to:
  /// **'The customer answered whether they paid. RideLink will review this order.'**
  String get notifPayerResponseBody;

  /// Notification payment_not_paid (to the sender).
  ///
  /// In en, this message translates to:
  /// **'Payment not received'**
  String get notifPaymentNotPaidTitle;

  /// Notification payment_not_paid body.
  ///
  /// In en, this message translates to:
  /// **'Your rider says this order was not paid. Tell us if you paid.'**
  String get notifPaymentNotPaidBody;

  /// Delivery order form: section title for choosing who pays the rider.
  ///
  /// In en, this message translates to:
  /// **'Who pays?'**
  String get whoPaysTitle;

  /// Who pays option: the sender pays (default).
  ///
  /// In en, this message translates to:
  /// **'I pay'**
  String get payerSenderOption;

  /// Who pays option: the receiver pays the delivery fee. Also shown to the rider at arrival.
  ///
  /// In en, this message translates to:
  /// **'Receiver pays'**
  String get payerReceiverOption;

  /// Rider job view at arrival: the sender pays this delivery.
  ///
  /// In en, this message translates to:
  /// **'Sender pays'**
  String get riderSenderPays;

  /// Sender pay card when the receiver pays. amount is like KES 350.
  ///
  /// In en, this message translates to:
  /// **'Your receiver is paying {amount}.'**
  String receiverIsPaying(String amount);

  /// Sender pay card when the receiver pays: heading above the rider's payment details.
  ///
  /// In en, this message translates to:
  /// **'If they can\'t pay, you can pay here.'**
  String get receiverCantPayNote;

  /// Status label for an order closed by the payment timeout.
  ///
  /// In en, this message translates to:
  /// **'Completed, payment not confirmed'**
  String get statusCompletedUnconfirmed;

  /// Rider: timeout-closed order while Not paid can still be reported. deadline is local date and time like 14 Oct, 15:30.
  ///
  /// In en, this message translates to:
  /// **'This order was closed because payment wasn\'t confirmed. If you weren\'t paid, tap Not paid by {deadline}.'**
  String lateReportBody(String deadline);

  /// Notification payment_reminder (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Confirm payment'**
  String get notifPaymentReminderTitle;

  /// Notification payment_reminder body.
  ///
  /// In en, this message translates to:
  /// **'Did you get paid for this order? Tap to confirm.'**
  String get notifPaymentReminderBody;

  /// Notification title to the sender when the payment timeout closes the order.
  ///
  /// In en, this message translates to:
  /// **'Order complete'**
  String get notifOrderCompleteTitle;

  /// Notification body to the sender when the payment timeout closes the order.
  ///
  /// In en, this message translates to:
  /// **'Your order is complete.'**
  String get notifOrderCompleteBody;

  /// Notification payment_not_paid body when the receiver was the payer.
  ///
  /// In en, this message translates to:
  /// **'Your rider says the receiver didn\'t pay. Tell us if it was paid.'**
  String get notifPaymentNotPaidReceiverBody;

  /// Rider timeout-close notification body when the deadline is unknown (pushes carry no data).
  ///
  /// In en, this message translates to:
  /// **'This order was closed because payment wasn\'t confirmed. If you weren\'t paid, tap Not paid.'**
  String get lateReportBodyNoDeadline;

  /// Notification payment_timeout_closed title (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Order closed'**
  String get notifOrderClosedTitle;

  /// Sender's Did you pay? prompt when the receiver was the payer.
  ///
  /// In en, this message translates to:
  /// **'Your rider says the receiver didn\'t pay. Was it paid?'**
  String get payerPromptTitleReceiver;

  /// Notification document_approved title.
  ///
  /// In en, this message translates to:
  /// **'Document approved'**
  String get notifDocumentApprovedTitle;

  /// Notification document_approved body.
  ///
  /// In en, this message translates to:
  /// **'Your {doc} was approved.'**
  String notifDocumentApprovedBody(String doc);

  /// Notification document_rejected title.
  ///
  /// In en, this message translates to:
  /// **'Document not approved'**
  String get notifDocumentRejectedTitle;

  /// Notification document_rejected body; reason is a docRejection* text.
  ///
  /// In en, this message translates to:
  /// **'Your {doc} was not approved: {reason}. Please upload a new one.'**
  String notifDocumentRejectedBody(String doc, String reason);

  /// Notification rider_verified title.
  ///
  /// In en, this message translates to:
  /// **'You\'re verified'**
  String get notifRiderVerifiedTitle;

  /// Notification rider_verified body.
  ///
  /// In en, this message translates to:
  /// **'You can now go online and accept Delivery and Ride orders.'**
  String get notifRiderVerifiedBody;

  /// Document rejection reason code blurry.
  ///
  /// In en, this message translates to:
  /// **'The photo is blurry or hard to read'**
  String get docRejectionBlurry;

  /// Document rejection reason code wrong_document.
  ///
  /// In en, this message translates to:
  /// **'This is not the requested document'**
  String get docRejectionWrongDocument;

  /// Document rejection reason code expired.
  ///
  /// In en, this message translates to:
  /// **'This document has expired'**
  String get docRejectionExpired;

  /// Document rejection reason code name_mismatch.
  ///
  /// In en, this message translates to:
  /// **'The name doesn\'t match your ID'**
  String get docRejectionNameMismatch;

  /// Document rejection reason code details_mismatch.
  ///
  /// In en, this message translates to:
  /// **'The details don\'t match your registration (for example the plate)'**
  String get docRejectionDetailsMismatch;

  /// Document rejection reason code bike_photo.
  ///
  /// In en, this message translates to:
  /// **'The bike photo must show the plate clearly and the bike in good condition'**
  String get docRejectionBikePhoto;

  /// Document rejection reason code suspected_fake (deliberately neutral).
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t verify this document'**
  String get docRejectionSuspectedFake;

  /// Document rejection reason code other.
  ///
  /// In en, this message translates to:
  /// **'See the message from RideLink'**
  String get docRejectionOther;

  /// Documents screen: the reviewer's message to the rider on a rejected document.
  ///
  /// In en, this message translates to:
  /// **'Message from RideLink: {message}'**
  String docRejectionMessage(String message);

  /// Status label for closed_unpaid: an admin closed the order without payment.
  ///
  /// In en, this message translates to:
  /// **'Closed, unpaid'**
  String get statusClosedUnpaid;

  /// Suspension reason safety_incident.
  ///
  /// In en, this message translates to:
  /// **'Safety incident'**
  String get suspensionReasonSafetyIncident;

  /// Suspension reason fraud_or_fake_documents.
  ///
  /// In en, this message translates to:
  /// **'Fraud or fake documents'**
  String get suspensionReasonFraud;

  /// Suspension reason harassment_or_abuse.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get suspensionReasonHarassment;

  /// Suspension reason repeated_non_payment.
  ///
  /// In en, this message translates to:
  /// **'Repeated non-payment'**
  String get suspensionReasonNonPayment;

  /// Suspension reason repeated_no_shows.
  ///
  /// In en, this message translates to:
  /// **'Repeated no-shows or cancellations'**
  String get suspensionReasonNoShows;

  /// Suspension reason strikes (automatic after 3 warnings).
  ///
  /// In en, this message translates to:
  /// **'Repeated warnings'**
  String get suspensionReasonStrikes;

  /// Suspension reason other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get suspensionReasonOther;

  /// Title of the suspended screen, banners and the account_suspended notification.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get accountSuspendedTitle;

  /// Suspension end. date is local date and time like 14 Oct, 15:30.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended until {date}.'**
  String accountSuspendedUntil(String date);

  /// Permanent suspension (no end date).
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended permanently.'**
  String get accountSuspendedPermanent;

  /// Suspension decided but waiting for the current order to end (no end date yet).
  ///
  /// In en, this message translates to:
  /// **'Your account will be suspended when your current order ends.'**
  String get accountSuspendedAfterOrder;

  /// Suspension reason line; reason is the category name.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}.'**
  String accountSuspendedReason(String reason);

  /// Shown while an appeal can still be sent.
  ///
  /// In en, this message translates to:
  /// **'You can appeal.'**
  String get accountSuspendedCanAppeal;

  /// App bar title of the suspension and appeal screen.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatusTitle;

  /// Account status screen when the account is not suspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is active.'**
  String get accountNotSuspended;

  /// Account status load error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your account status.'**
  String get accountStatusLoadFailed;

  /// Button on suspension banners opening the account status screen.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get suspendedViewDetails;

  /// Heading of the appeal section.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get appealTitle;

  /// Appeal text field label.
  ///
  /// In en, this message translates to:
  /// **'Tell us why the suspension should be lifted'**
  String get appealLabel;

  /// Note above the appeal form.
  ///
  /// In en, this message translates to:
  /// **'You can send one appeal for this suspension.'**
  String get appealOnceNote;

  /// Appeal submit button.
  ///
  /// In en, this message translates to:
  /// **'Send appeal'**
  String get appealSubmit;

  /// Appeal validation: empty message.
  ///
  /// In en, this message translates to:
  /// **'Write your appeal'**
  String get appealRequired;

  /// Appeal submit failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your appeal. Try again.'**
  String get appealFailed;

  /// Appeal status pending.
  ///
  /// In en, this message translates to:
  /// **'Your appeal has been sent and is being reviewed.'**
  String get appealPending;

  /// Appeal status upheld; also the appeal_decided notification body.
  ///
  /// In en, this message translates to:
  /// **'Your appeal was reviewed. The suspension stays in place.'**
  String get appealUpheld;

  /// Appeal status lifted; also the appeal_decided notification body.
  ///
  /// In en, this message translates to:
  /// **'Your appeal was accepted and the suspension lifted.'**
  String get appealLifted;

  /// Settle-balance screen title and links to it.
  ///
  /// In en, this message translates to:
  /// **'Settle your balance'**
  String get settleBalanceTitle;

  /// Settle-balance screen intro.
  ///
  /// In en, this message translates to:
  /// **'You can\'t book until your rider confirms they have received your payment.'**
  String get settleBalanceIntro;

  /// Label above the owed amount. rider is the rider's first name.
  ///
  /// In en, this message translates to:
  /// **'You owe {rider} for this order'**
  String balanceOwedTo(String rider);

  /// Label above the owed amount when the rider's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'You owe your rider for this order'**
  String get balanceOwedToRider;

  /// Opens the order a balance is for.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get balanceViewOrder;

  /// Settle-balance screen when nothing is owed; balance_settled notification title.
  ///
  /// In en, this message translates to:
  /// **'Balance settled'**
  String get balanceSettledTitle;

  /// Settle-balance screen when nothing is owed.
  ///
  /// In en, this message translates to:
  /// **'You can book again.'**
  String get balanceSettledBody;

  /// Settle-balance load error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your balance.'**
  String get balanceLoadFailed;

  /// Returns to the sender home.
  ///
  /// In en, this message translates to:
  /// **'Back to home'**
  String get backToHomeButton;

  /// Sender home banner while a balance is open; balance_created notification title.
  ///
  /// In en, this message translates to:
  /// **'Unpaid balance'**
  String get homeBalanceBannerTitle;

  /// Sender home banner body. amount like KES 350 (total of open balances).
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}. Pay your rider to book again.'**
  String homeBalanceBannerBody(String amount);

  /// Rider: settle an unresolved or unpaid order.
  ///
  /// In en, this message translates to:
  /// **'Payment received?'**
  String get riderSettleTitle;

  /// Rider on an unresolved order with no ruling yet.
  ///
  /// In en, this message translates to:
  /// **'If the payer has paid you since, confirm it here. This completes the order.'**
  String get riderSettleBodyUnresolved;

  /// Rider on a closed_unpaid order with an open balance. amount like KES 350.
  ///
  /// In en, this message translates to:
  /// **'The payer owes you {amount} for this order. When you receive it, confirm it here.'**
  String riderSettleBodyBalance(String amount);

  /// Notification payment_ruled title.
  ///
  /// In en, this message translates to:
  /// **'Payment review complete'**
  String get notifPaymentRuledTitle;

  /// Notification payment_ruled body.
  ///
  /// In en, this message translates to:
  /// **'Open the order to see the decision.'**
  String get notifPaymentRuledBody;

  /// Notification balance_created body. amount like KES 350.
  ///
  /// In en, this message translates to:
  /// **'You owe your rider {amount} for this order.'**
  String notifBalanceCreatedBody(String amount);

  /// Notification balance_created body without an amount.
  ///
  /// In en, this message translates to:
  /// **'You owe your rider for this order.'**
  String get notifBalanceCreatedBodyNoAmount;

  /// Notification balance_settled body (sender and rider).
  ///
  /// In en, this message translates to:
  /// **'The payment for this order is confirmed.'**
  String get notifBalanceSettledBody;

  /// Notification strike_issued title (neutral).
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get notifStrikeIssuedTitle;

  /// Notification strike_issued body (neutral).
  ///
  /// In en, this message translates to:
  /// **'You received a warning on this order.'**
  String get notifStrikeIssuedBody;

  /// Notification account_suspended body when no details are sent.
  ///
  /// In en, this message translates to:
  /// **'Open RideLink to see the details.'**
  String get notifAccountSuspendedBody;

  /// Notification suspension_lifted title.
  ///
  /// In en, this message translates to:
  /// **'Suspension lifted'**
  String get notifSuspensionLiftedTitle;

  /// Notification suspension_lifted body.
  ///
  /// In en, this message translates to:
  /// **'Your account is active again.'**
  String get notifSuspensionLiftedBody;

  /// Notification appeal_decided title.
  ///
  /// In en, this message translates to:
  /// **'Appeal decided'**
  String get notifAppealDecidedTitle;

  /// Notification appeal_decided body when the decision is unknown.
  ///
  /// In en, this message translates to:
  /// **'Your appeal has been reviewed.'**
  String get notifAppealDecidedBody;

  /// Error code outstanding_balance.
  ///
  /// In en, this message translates to:
  /// **'Settle your balance with your rider before booking again.'**
  String get errCodeOutstandingBalance;

  /// Error code account_suspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended.'**
  String get errCodeAccountSuspended;

  /// Warning reason payer_at_fault.
  ///
  /// In en, this message translates to:
  /// **'Unpaid order'**
  String get strikeReasonUnpaidOrder;

  /// Warning reason false_report (rider's not-paid report found false).
  ///
  /// In en, this message translates to:
  /// **'Payment report not upheld'**
  String get strikeReasonFalseReport;

  /// Warning with a reason this build doesn't name.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get strikeReasonGeneric;

  /// Title for an intended suspension (prior notice); suspension_intended notification title.
  ///
  /// In en, this message translates to:
  /// **'Suspension notice'**
  String get suspensionIntendedTitle;

  /// First sentence of an intended-suspension notice.
  ///
  /// In en, this message translates to:
  /// **'RideLink intends to suspend your account.'**
  String get suspensionIntendedLead;

  /// Intended suspension response deadline; time like 14 Oct, 15:30.
  ///
  /// In en, this message translates to:
  /// **'You can respond until {time}.'**
  String suspensionRespondUntil(String time);

  /// Title for safety/fraud holds.
  ///
  /// In en, this message translates to:
  /// **'Account on hold'**
  String get accountOnHoldTitle;

  /// First sentence for safety/fraud holds.
  ///
  /// In en, this message translates to:
  /// **'Your account is on hold pending review.'**
  String get accountOnHold;

  /// Intended suspension response field label.
  ///
  /// In en, this message translates to:
  /// **'Your response'**
  String get suspensionResponseLabel;

  /// Intended suspension response button.
  ///
  /// In en, this message translates to:
  /// **'Send response'**
  String get suspensionResponseSubmit;

  /// Response validation: empty.
  ///
  /// In en, this message translates to:
  /// **'Write your response'**
  String get suspensionResponseRequired;

  /// Response submit failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your response. Try again.'**
  String get suspensionResponseFailed;

  /// After responding to an intended suspension.
  ///
  /// In en, this message translates to:
  /// **'Your response has been sent. RideLink will review it before deciding.'**
  String get suspensionResponseSent;

  /// Heading of the warnings section.
  ///
  /// In en, this message translates to:
  /// **'Account standing'**
  String get standingTitle;

  /// Warnings rule shown with the list.
  ///
  /// In en, this message translates to:
  /// **'3 warnings in 90 days can lead to a 7-day suspension.'**
  String get standingRule;

  /// Warnings section when empty.
  ///
  /// In en, this message translates to:
  /// **'You have no warnings.'**
  String get standingNoWarnings;

  /// Warning issue date.
  ///
  /// In en, this message translates to:
  /// **'Issued {date}'**
  String strikeIssuedOn(String date);

  /// Warning expiry date.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String strikeExpiresOn(String date);

  /// Opens the one-time dispute form for a warning.
  ///
  /// In en, this message translates to:
  /// **'Dispute'**
  String get disputeButton;

  /// Dispute field label.
  ///
  /// In en, this message translates to:
  /// **'Tell us why this warning is wrong'**
  String get disputeLabel;

  /// Note above the dispute form.
  ///
  /// In en, this message translates to:
  /// **'You can dispute each warning once, within 7 days.'**
  String get disputeOnceNote;

  /// Dispute submit button.
  ///
  /// In en, this message translates to:
  /// **'Send dispute'**
  String get disputeSubmit;

  /// Dispute validation: empty.
  ///
  /// In en, this message translates to:
  /// **'Write your dispute'**
  String get disputeRequired;

  /// Dispute submit failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send your dispute. Try again.'**
  String get disputeFailed;

  /// Dispute status pending.
  ///
  /// In en, this message translates to:
  /// **'Dispute sent. RideLink will review it.'**
  String get disputePending;

  /// Dispute upheld; also notification body.
  ///
  /// In en, this message translates to:
  /// **'Your dispute was accepted and the warning removed.'**
  String get disputeUpheld;

  /// Dispute rejected; also notification body.
  ///
  /// In en, this message translates to:
  /// **'Your dispute was reviewed. The warning stays.'**
  String get disputeRejected;

  /// Debtor: opens the I've-paid form on the settle-balance screen.
  ///
  /// In en, this message translates to:
  /// **'I\'ve paid'**
  String get iPaidButton;

  /// I've-paid form heading.
  ///
  /// In en, this message translates to:
  /// **'Tell us how you paid'**
  String get iPaidTitle;

  /// I've-paid cash note label.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get cashNoteLabel;

  /// I've-paid cash note helper.
  ///
  /// In en, this message translates to:
  /// **'For example, when and where you paid'**
  String get cashNoteHelp;

  /// I've-paid submit button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get iPaidSubmit;

  /// I've-paid submit failure.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send. Try again.'**
  String get iPaidFailed;

  /// After the debtor says they paid.
  ///
  /// In en, this message translates to:
  /// **'We\'ve asked your rider to confirm. RideLink will review if they don\'t respond.'**
  String get iPaidSent;

  /// Rider: forgive an open balance.
  ///
  /// In en, this message translates to:
  /// **'Forgive balance'**
  String get forgiveBalanceButton;

  /// Forgive confirmation title.
  ///
  /// In en, this message translates to:
  /// **'Forgive this balance?'**
  String get forgiveBalanceTitle;

  /// Forgive confirmation body.
  ///
  /// In en, this message translates to:
  /// **'The payer will no longer owe you for this order. This can\'t be undone.'**
  String get forgiveBalanceBody;

  /// Forgive confirmation button.
  ///
  /// In en, this message translates to:
  /// **'Forgive'**
  String get forgiveBalanceConfirm;

  /// New delivery: shown when Receiver pays is chosen (P6 disclosure).
  ///
  /// In en, this message translates to:
  /// **'If your receiver doesn\'t pay, you will owe the rider.'**
  String get receiverPaysDisclosure;

  /// Notification balance_claim_received title (to the rider).
  ///
  /// In en, this message translates to:
  /// **'Customer says they paid'**
  String get notifBalanceClaimTitle;

  /// Notification balance_claim_received body.
  ///
  /// In en, this message translates to:
  /// **'Your customer says they paid for this order. Please confirm.'**
  String get notifBalanceClaimBody;

  /// Notification strike_dispute_decided title.
  ///
  /// In en, this message translates to:
  /// **'Dispute decided'**
  String get notifDisputeDecidedTitle;

  /// Notification strike_dispute_decided body when the decision is unknown.
  ///
  /// In en, this message translates to:
  /// **'Your dispute has been reviewed.'**
  String get notifDisputeDecidedBody;

  /// Upload sheet for the national ID: the typed ID number field label.
  ///
  /// In en, this message translates to:
  /// **'National ID number'**
  String get idNumberLabel;

  /// ID number field helper.
  ///
  /// In en, this message translates to:
  /// **'As printed on your ID'**
  String get idNumberHint;

  /// ID number validation: empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your ID number'**
  String get idNumberRequired;

  /// ID number validation: bad format.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 to 20 letters or digits'**
  String get idNumberInvalid;

  /// Documents screen: the national ID number is on file (not a verification).
  ///
  /// In en, this message translates to:
  /// **'ID number received'**
  String get idNumberReceived;
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
