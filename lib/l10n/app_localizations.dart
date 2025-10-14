import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

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
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'INSIDEX'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Sound Healing & Subliminal'**
  String get appTagline;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your notification preferences'**
  String get notificationsSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @supportAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Support & Feedback'**
  String get supportAndFeedback;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help us improve INSIDEX'**
  String get sendFeedbackSubtitle;

  /// No description provided for @reportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get reportBug;

  /// No description provided for @reportBugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Something not working?'**
  String get reportBugSubtitle;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get disclaimer;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @allSubliminals.
  ///
  /// In en, this message translates to:
  /// **'All Subliminals'**
  String get allSubliminals;

  /// No description provided for @yourPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Your Playlist'**
  String get yourPlaylist;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @myPlaylists.
  ///
  /// In en, this message translates to:
  /// **'My Playlists'**
  String get myPlaylists;

  /// No description provided for @myPlaylist.
  ///
  /// In en, this message translates to:
  /// **'My Playlist'**
  String get myPlaylist;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noSessionsInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'No Sessions in Playlist'**
  String get noSessionsInPlaylist;

  /// No description provided for @addSessionsToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add sessions to create your perfect healing journey'**
  String get addSessionsToPlaylist;

  /// No description provided for @noFavoriteSessions.
  ///
  /// In en, this message translates to:
  /// **'No Favorite Sessions'**
  String get noFavoriteSessions;

  /// No description provided for @markSessionsAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark sessions as favorite to find them quickly'**
  String get markSessionsAsFavorite;

  /// No description provided for @noRecentSessions.
  ///
  /// In en, this message translates to:
  /// **'No Recent Sessions'**
  String get noRecentSessions;

  /// No description provided for @sessionsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Sessions you play will appear here'**
  String get sessionsWillAppearHere;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Removed from playlist'**
  String get removedFromPlaylist;

  /// No description provided for @untitledSession.
  ///
  /// In en, this message translates to:
  /// **'Untitled Session'**
  String get untitledSession;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @addedToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Added to playlist'**
  String get addedToPlaylist;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdated;

  /// No description provided for @errorUpdatingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get yourProgress;

  /// No description provided for @trackYourListening.
  ///
  /// In en, this message translates to:
  /// **'Track your listening habits and improvements'**
  String get trackYourListening;

  /// No description provided for @myInsights.
  ///
  /// In en, this message translates to:
  /// **'My Insights'**
  String get myInsights;

  /// No description provided for @viewPersonalizedWellness.
  ///
  /// In en, this message translates to:
  /// **'View your personalized wellness profile'**
  String get viewPersonalizedWellness;

  /// No description provided for @premiumWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Premium Waitlist'**
  String get premiumWaitlist;

  /// No description provided for @joinEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Join early access for premium features'**
  String get joinEarlyAccess;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @manageUsersAndSessions.
  ///
  /// In en, this message translates to:
  /// **'Manage users, sessions and app settings'**
  String get manageUsersAndSessions;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @topSessions.
  ///
  /// In en, this message translates to:
  /// **'Top Sessions'**
  String get topSessions;

  /// No description provided for @minutesToday.
  ///
  /// In en, this message translates to:
  /// **'minutes today'**
  String get minutesToday;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get noSessionsYet;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @allSessions.
  ///
  /// In en, this message translates to:
  /// **'All Sessions'**
  String get allSessions;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a Category'**
  String get chooseCategory;

  /// No description provided for @selectCategoryExplore.
  ///
  /// In en, this message translates to:
  /// **'Select a category to explore sessions'**
  String get selectCategoryExplore;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'sessions'**
  String get sessions;

  /// No description provided for @errorLoadingSessions.
  ///
  /// In en, this message translates to:
  /// **'Error loading sessions'**
  String get errorLoadingSessions;

  /// No description provided for @noSessionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sessions available'**
  String get noSessionsAvailable;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later for new content'**
  String get checkBackLater;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @goalsTab.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsTab;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @journey.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get journey;

  /// No description provided for @subliminals.
  ///
  /// In en, this message translates to:
  /// **'subliminals'**
  String get subliminals;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @totalListening.
  ///
  /// In en, this message translates to:
  /// **'Total Listening'**
  String get totalListening;

  /// No description provided for @totalSessions.
  ///
  /// In en, this message translates to:
  /// **'Total Sessions'**
  String get totalSessions;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @noGoalsYet.
  ///
  /// In en, this message translates to:
  /// **'No goals set yet'**
  String get noGoalsYet;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get goalProgress;

  /// No description provided for @weeklyActivity.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity'**
  String get weeklyActivity;

  /// No description provided for @averageSession.
  ///
  /// In en, this message translates to:
  /// **'Average Session'**
  String get averageSession;

  /// No description provided for @editMode.
  ///
  /// In en, this message translates to:
  /// **'Edit Mode'**
  String get editMode;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @yourPersonalizedProfile.
  ///
  /// In en, this message translates to:
  /// **'Your personalized wellness profile'**
  String get yourPersonalizedProfile;

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth Date'**
  String get birthDate;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @personalityInsights.
  ///
  /// In en, this message translates to:
  /// **'Personality Insights'**
  String get personalityInsights;

  /// No description provided for @ageGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroup;

  /// No description provided for @wellnessFocus.
  ///
  /// In en, this message translates to:
  /// **'Wellness Focus'**
  String get wellnessFocus;

  /// No description provided for @recommendedSessions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Sessions'**
  String get recommendedSessions;

  /// No description provided for @yourWellnessGoals.
  ///
  /// In en, this message translates to:
  /// **'Your Wellness Goals'**
  String get yourWellnessGoals;

  /// No description provided for @daysActive.
  ///
  /// In en, this message translates to:
  /// **'Days Active'**
  String get daysActive;

  /// No description provided for @sessionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @streakLabel.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streakLabel;

  /// No description provided for @minTotal.
  ///
  /// In en, this message translates to:
  /// **'min total'**
  String get minTotal;

  /// No description provided for @sessionStats.
  ///
  /// In en, this message translates to:
  /// **'Session Stats'**
  String get sessionStats;

  /// No description provided for @longestSession.
  ///
  /// In en, this message translates to:
  /// **'Longest Session'**
  String get longestSession;

  /// No description provided for @favoriteTime.
  ///
  /// In en, this message translates to:
  /// **'Favorite Time'**
  String get favoriteTime;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @yourWellnessJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Wellness Journey'**
  String get yourWellnessJourney;

  /// No description provided for @trackMilestones.
  ///
  /// In en, this message translates to:
  /// **'Track your milestones and achievements'**
  String get trackMilestones;

  /// No description provided for @firstSession.
  ///
  /// In en, this message translates to:
  /// **'First Session'**
  String get firstSession;

  /// No description provided for @notStartedYet.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get notStartedYet;

  /// No description provided for @sevenDayStreak.
  ///
  /// In en, this message translates to:
  /// **'7 Day Streak'**
  String get sevenDayStreak;

  /// No description provided for @achieved.
  ///
  /// In en, this message translates to:
  /// **'Achieved!'**
  String get achieved;

  /// No description provided for @daysToGo.
  ///
  /// In en, this message translates to:
  /// **'days to go'**
  String get daysToGo;

  /// No description provided for @tenSessions.
  ///
  /// In en, this message translates to:
  /// **'10 Sessions'**
  String get tenSessions;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed!'**
  String get completed;

  /// No description provided for @sessionsToGo.
  ///
  /// In en, this message translates to:
  /// **'sessions to go'**
  String get sessionsToGo;

  /// No description provided for @thirtyDayStreak.
  ///
  /// In en, this message translates to:
  /// **'30 Day Streak'**
  String get thirtyDayStreak;

  /// No description provided for @amazingAchievement.
  ///
  /// In en, this message translates to:
  /// **'Amazing achievement!'**
  String get amazingAchievement;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going!'**
  String get keepGoing;

  /// No description provided for @fiftySessions.
  ///
  /// In en, this message translates to:
  /// **'50 Sessions'**
  String get fiftySessions;

  /// No description provided for @powerUser.
  ///
  /// In en, this message translates to:
  /// **'Power user!'**
  String get powerUser;

  /// No description provided for @longTermGoal.
  ///
  /// In en, this message translates to:
  /// **'Long term goal'**
  String get longTermGoal;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @yourAge.
  ///
  /// In en, this message translates to:
  /// **'Your Age'**
  String get yourAge;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @goalsLabel.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goalsLabel;

  /// No description provided for @member.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @night.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get night;

  /// No description provided for @youngAdult.
  ///
  /// In en, this message translates to:
  /// **'Young Adult'**
  String get youngAdult;

  /// No description provided for @earlyTwenties.
  ///
  /// In en, this message translates to:
  /// **'Early Twenties'**
  String get earlyTwenties;

  /// No description provided for @lateTwenties.
  ///
  /// In en, this message translates to:
  /// **'Late Twenties'**
  String get lateTwenties;

  /// No description provided for @thirties.
  ///
  /// In en, this message translates to:
  /// **'Thirties'**
  String get thirties;

  /// No description provided for @matureAdult.
  ///
  /// In en, this message translates to:
  /// **'Mature Adult'**
  String get matureAdult;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
  String get sleepQuality;

  /// No description provided for @mentalPeace.
  ///
  /// In en, this message translates to:
  /// **'Mental Peace'**
  String get mentalPeace;

  /// No description provided for @vitality.
  ///
  /// In en, this message translates to:
  /// **'Vitality'**
  String get vitality;

  /// No description provided for @generalWellness.
  ///
  /// In en, this message translates to:
  /// **'General Wellness'**
  String get generalWellness;

  /// No description provided for @sleepSessions.
  ///
  /// In en, this message translates to:
  /// **'Sleep Sessions'**
  String get sleepSessions;

  /// No description provided for @meditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get meditation;

  /// No description provided for @focusSessions.
  ///
  /// In en, this message translates to:
  /// **'Focus Sessions'**
  String get focusSessions;

  /// No description provided for @editGoals.
  ///
  /// In en, this message translates to:
  /// **'Edit Goals'**
  String get editGoals;

  /// No description provided for @goalEditingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Goal editing feature coming soon!'**
  String get goalEditingComingSoon;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @thisHelpsPersonalize.
  ///
  /// In en, this message translates to:
  /// **'This helps us personalize your experience'**
  String get thisHelpsPersonalize;

  /// No description provided for @answerQuickQuestions.
  ///
  /// In en, this message translates to:
  /// **'Answer a few quick questions to get personalized recommendations'**
  String get answerQuickQuestions;

  /// No description provided for @whatAreYourGoals.
  ///
  /// In en, this message translates to:
  /// **'What are your current goals'**
  String get whatAreYourGoals;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @betterSleep.
  ///
  /// In en, this message translates to:
  /// **'Better Sleep'**
  String get betterSleep;

  /// No description provided for @anxietyRelief.
  ///
  /// In en, this message translates to:
  /// **'Anxiety Relief'**
  String get anxietyRelief;

  /// No description provided for @emotionalBalance.
  ///
  /// In en, this message translates to:
  /// **'Emotional Balance'**
  String get emotionalBalance;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @selectYourBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your birth date'**
  String get selectYourBirthDate;

  /// No description provided for @youMustBeAtLeast18.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get youMustBeAtLeast18;

  /// No description provided for @pleaseSelectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth date'**
  String get pleaseSelectBirthDate;

  /// No description provided for @errorSavingData.
  ///
  /// In en, this message translates to:
  /// **'Error saving data. Please try again.'**
  String get errorSavingData;

  /// No description provided for @yourInformationIsSecure.
  ///
  /// In en, this message translates to:
  /// **'Your information is secure and will never be shared'**
  String get yourInformationIsSecure;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'years old'**
  String get yearsOld;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
