import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

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
    Locale('hi'),
    Locale('ru'),
    Locale('tr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'InsideX'**
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
  /// **'Help us improve InsideX'**
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

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @welcomeToAdminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your admin dashboard'**
  String get welcomeToAdminDashboard;

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

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

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
  /// **'Sessions'**
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
  /// **'Active'**
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
  /// **'Error saving data'**
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

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry! It happens. Please enter the email associated with your account.'**
  String get forgotPasswordDescription;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @securityReasonNote.
  ///
  /// In en, this message translates to:
  /// **'For security reasons, we will send a password reset link to your registered email if it exists in our system.'**
  String get securityReasonNote;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// No description provided for @resetLinkSentMessage.
  ///
  /// In en, this message translates to:
  /// **'We have sent a password reset link to your email address. Please check your inbox and follow the instructions.'**
  String get resetLinkSentMessage;

  /// No description provided for @didntReceiveEmail.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the email?'**
  String get didntReceiveEmail;

  /// No description provided for @checkSpamFolder.
  ///
  /// In en, this message translates to:
  /// **'Please check your spam folder or try resending the email after a few minutes.'**
  String get checkSpamFolder;

  /// No description provided for @tryDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Try Different Email'**
  String get tryDifferentEmail;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account Not Found'**
  String get accountNotFound;

  /// No description provided for @noAccountExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'No account exists with this email address.\n\nWould you like to create a new account instead?'**
  String get noAccountExistsMessage;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get failedToSendResetEmail;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your healing journey'**
  String get signInToContinue;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @weSentPasswordTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a password to:'**
  String get weSentPasswordTo;

  /// No description provided for @enterSixDigitPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit password:'**
  String get enterSixDigitPassword;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @youCanResendIn.
  ///
  /// In en, this message translates to:
  /// **'You can resend in'**
  String get youCanResendIn;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @didntGetIt.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t get it?'**
  String get didntGetIt;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @newCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'New code sent to'**
  String get newCodeSentTo;

  /// No description provided for @failedToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get failedToSendCode;

  /// No description provided for @pleaseEnterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code.'**
  String get pleaseEnterSixDigitCode;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @accountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get accountCreatedSuccessfully;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @startYourHealingJourney.
  ///
  /// In en, this message translates to:
  /// **'Start your healing journey today'**
  String get startYourHealingJourney;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourFullName;

  /// No description provided for @createAPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createAPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reenterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reenterYourPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @iAgreeToThe.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get iAgreeToThe;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsAndConditions;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @pleaseAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the terms and conditions'**
  String get pleaseAgreeToTerms;

  /// No description provided for @verificationCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent! Please check your email.'**
  String get verificationCodeSent;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @createYourPersonalProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your personal profile\nto get custom subliminal sessions'**
  String get createYourPersonalProfile;

  /// No description provided for @emailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email + Password'**
  String get emailPassword;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'💡 Suggestion'**
  String get suggestion;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'🐛 Bug Report'**
  String get bugReport;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'✨ Feature Request'**
  String get featureRequest;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'😔 Complaint'**
  String get complaint;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'📝 Other'**
  String get other;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @briefSummary.
  ///
  /// In en, this message translates to:
  /// **'Brief summary'**
  String get briefSummary;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @tellUsMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more...'**
  String get tellUsMore;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseDescribeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Please describe your feedback'**
  String get pleaseDescribeFeedback;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @forFollowUp.
  ///
  /// In en, this message translates to:
  /// **'For follow-up'**
  String get forFollowUp;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'✅ Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @allNotifications.
  ///
  /// In en, this message translates to:
  /// **'All Notifications'**
  String get allNotifications;

  /// No description provided for @masterControlNotifications.
  ///
  /// In en, this message translates to:
  /// **'Master control for all app notifications'**
  String get masterControlNotifications;

  /// No description provided for @dailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get dailyReminders;

  /// No description provided for @achievementNotifications.
  ///
  /// In en, this message translates to:
  /// **'Achievement Notifications'**
  String get achievementNotifications;

  /// No description provided for @streakMilestones.
  ///
  /// In en, this message translates to:
  /// **'Streak Milestones'**
  String get streakMilestones;

  /// No description provided for @celebrateConsistency.
  ///
  /// In en, this message translates to:
  /// **'Celebrate your consistency achievements'**
  String get celebrateConsistency;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent! 🔔'**
  String get testNotificationSent;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications Disabled'**
  String get notificationsDisabled;

  /// No description provided for @enableNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications to receive daily reminders for your wellness routine'**
  String get enableNotificationsMessage;

  /// No description provided for @pleaseEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Please enable notifications in system settings'**
  String get pleaseEnableNotifications;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @getRemindedDaily.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to practice daily'**
  String get getRemindedDaily;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @minCharacters.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters'**
  String get minCharacters;

  /// No description provided for @newPasswordMustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current'**
  String get newPasswordMustBeDifferent;

  /// No description provided for @mustBeDifferent.
  ///
  /// In en, this message translates to:
  /// **'Must be different'**
  String get mustBeDifferent;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password Strength'**
  String get passwordStrength;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @fair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get fair;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @reenterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get reenterNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements'**
  String get passwordRequirements;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @oneUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'One uppercase letter'**
  String get oneUppercaseLetter;

  /// No description provided for @oneLowercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'One lowercase letter'**
  String get oneLowercaseLetter;

  /// No description provided for @oneNumber.
  ///
  /// In en, this message translates to:
  /// **'One number'**
  String get oneNumber;

  /// No description provided for @differentFromCurrent.
  ///
  /// In en, this message translates to:
  /// **'Different from current'**
  String get differentFromCurrent;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password Changed!'**
  String get passwordChanged;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed successfully.'**
  String get passwordChangedSuccess;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @createStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password for your account'**
  String get createStrongPassword;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @unexpectedErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get unexpectedErrorOccurred;

  /// No description provided for @stayOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Stay on Track'**
  String get stayOnTrack;

  /// No description provided for @dailyRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Get daily reminders to maintain your wellness routine and achieve your goals'**
  String get dailyRemindersDescription;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notNow;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @notificationsEnabledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled! 🔔'**
  String get notificationsEnabledSuccess;

  /// No description provided for @notificationDailyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for Your Daily Session 🎧'**
  String get notificationDailyReminderTitle;

  /// No description provided for @notificationDailyReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to relax and heal with InsideX'**
  String get notificationDailyReminderMessage;

  /// No description provided for @notificationStreak3Title.
  ///
  /// In en, this message translates to:
  /// **'🎉 Congratulations!'**
  String get notificationStreak3Title;

  /// No description provided for @notificationStreak3Message.
  ///
  /// In en, this message translates to:
  /// **'🔥 3 day streak! Great start!'**
  String get notificationStreak3Message;

  /// No description provided for @notificationStreak7Title.
  ///
  /// In en, this message translates to:
  /// **'🎯 One Week Achievement!'**
  String get notificationStreak7Title;

  /// No description provided for @notificationStreak7Message.
  ///
  /// In en, this message translates to:
  /// **'7 days in a row! You\'re doing amazing!'**
  String get notificationStreak7Message;

  /// No description provided for @notificationStreak14Title.
  ///
  /// In en, this message translates to:
  /// **'💪 Two Weeks Strong!'**
  String get notificationStreak14Title;

  /// No description provided for @notificationStreak14Message.
  ///
  /// In en, this message translates to:
  /// **'14 day streak! The habit is forming.'**
  String get notificationStreak14Message;

  /// No description provided for @notificationStreak21Title.
  ///
  /// In en, this message translates to:
  /// **'🌟 21 Days - Habit Formed!'**
  String get notificationStreak21Title;

  /// No description provided for @notificationStreak21Message.
  ///
  /// In en, this message translates to:
  /// **'Science says you\'ve built a new habit!'**
  String get notificationStreak21Message;

  /// No description provided for @notificationStreak30Title.
  ///
  /// In en, this message translates to:
  /// **'🏆 30 Day Legend!'**
  String get notificationStreak30Title;

  /// No description provided for @notificationStreak30Message.
  ///
  /// In en, this message translates to:
  /// **'One full month! Incredible dedication!'**
  String get notificationStreak30Message;

  /// No description provided for @notificationStreak50Title.
  ///
  /// In en, this message translates to:
  /// **'💎 50 Day Diamond Streak!'**
  String get notificationStreak50Title;

  /// No description provided for @notificationStreak50Message.
  ///
  /// In en, this message translates to:
  /// **'Half a century! You\'re a true InsideX master!'**
  String get notificationStreak50Message;

  /// No description provided for @notificationStreak100Title.
  ///
  /// In en, this message translates to:
  /// **'👑 100 Day Champion!'**
  String get notificationStreak100Title;

  /// No description provided for @notificationStreak100Message.
  ///
  /// In en, this message translates to:
  /// **'One hundred days! You\'re absolutely legendary! 🎊'**
  String get notificationStreak100Message;

  /// No description provided for @notificationStreakLostTitle.
  ///
  /// In en, this message translates to:
  /// **'😔 Streak Ended'**
  String get notificationStreakLostTitle;

  /// No description provided for @notificationStreakLostMessage.
  ///
  /// In en, this message translates to:
  /// **'Your {days} day streak has ended. But don\'t worry, you can start fresh today!'**
  String notificationStreakLostMessage(Object days);

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// No description provided for @intro.
  ///
  /// In en, this message translates to:
  /// **'Intro'**
  String get intro;

  /// No description provided for @introduction.
  ///
  /// In en, this message translates to:
  /// **'Introduction'**
  String get introduction;

  /// No description provided for @subliminalSession.
  ///
  /// In en, this message translates to:
  /// **'Subliminal Session'**
  String get subliminalSession;

  /// No description provided for @noIntroductionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No introduction available'**
  String get noIntroductionAvailable;

  /// No description provided for @unknownSession.
  ///
  /// In en, this message translates to:
  /// **'Unknown Session'**
  String get unknownSession;

  /// No description provided for @audioFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found'**
  String get audioFileNotFound;

  /// No description provided for @failedToPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Failed to play audio'**
  String get failedToPlayAudio;

  /// No description provided for @subliminal.
  ///
  /// In en, this message translates to:
  /// **'Subliminal'**
  String get subliminal;

  /// No description provided for @sessionDetails.
  ///
  /// In en, this message translates to:
  /// **'Session Details'**
  String get sessionDetails;

  /// No description provided for @aboutThisSession.
  ///
  /// In en, this message translates to:
  /// **'ABOUT THIS SESSION'**
  String get aboutThisSession;

  /// No description provided for @loopEnabled.
  ///
  /// In en, this message translates to:
  /// **'Loop enabled'**
  String get loopEnabled;

  /// No description provided for @loopDisabled.
  ///
  /// In en, this message translates to:
  /// **'Loop disabled'**
  String get loopDisabled;

  /// No description provided for @shuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle ON'**
  String get shuffleOn;

  /// No description provided for @shuffleOff.
  ///
  /// In en, this message translates to:
  /// **'Shuffle OFF'**
  String get shuffleOff;

  /// No description provided for @errorUpdatingPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Error updating playlist'**
  String get errorUpdatingPlaylist;

  /// No description provided for @errorUpdatingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorites'**
  String get errorUpdatingFavorites;

  /// No description provided for @premiumFeature.
  ///
  /// In en, this message translates to:
  /// **'Premium feature'**
  String get premiumFeature;

  /// No description provided for @autoPlayEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-play enabled'**
  String get autoPlayEnabled;

  /// No description provided for @autoPlayDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto-play disabled'**
  String get autoPlayDisabled;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @noTimerSet.
  ///
  /// In en, this message translates to:
  /// **'No timer set'**
  String get noTimerSet;

  /// No description provided for @currentMinutes.
  ///
  /// In en, this message translates to:
  /// **'Current: {minutes} minutes'**
  String currentMinutes(String minutes);

  /// No description provided for @cancelTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// No description provided for @set.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get set;

  /// No description provided for @setMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String setMinutes(String minutes);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchSessions.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchSessions;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @searchCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get searchCategories;

  /// No description provided for @searchSessionsTab.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get searchSessionsTab;

  /// No description provided for @allResults.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allResults;

  /// No description provided for @foundResults.
  ///
  /// In en, this message translates to:
  /// **'{count} results found'**
  String foundResults(String count);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Search History'**
  String get clearSearchHistory;

  /// No description provided for @clearSearchHistoryConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all search history?'**
  String get clearSearchHistoryConfirmation;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Search history cleared'**
  String get searchHistoryCleared;

  /// No description provided for @accountOpenedOnAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'Account Opened on Another Device'**
  String get accountOpenedOnAnotherDevice;

  /// No description provided for @accountOpenedMessage.
  ///
  /// In en, this message translates to:
  /// **'For your security, you will be automatically logged out from this device.'**
  String get accountOpenedMessage;

  /// No description provided for @securityWarningUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'If this wasn\'t you, please change your password immediately!'**
  String get securityWarningUnauthorized;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @deviceSecurityWarning.
  ///
  /// In en, this message translates to:
  /// **'Your account can only be active on one device at a time for security purposes.'**
  String get deviceSecurityWarning;

  /// No description provided for @second.
  ///
  /// In en, this message translates to:
  /// **'second'**
  String get second;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordMustBeAtLeast6Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBeAtLeast6Characters;

  /// No description provided for @passwordMustBeAtLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAtLeast8Characters;

  /// No description provided for @passwordMustContainUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMustContainUppercase;

  /// No description provided for @passwordMustContainLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMustContainLowercase;

  /// No description provided for @passwordMustContainNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMustContainNumber;

  /// No description provided for @pleaseEnterName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// No description provided for @nameMustBeAtLeast2Characters.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameMustBeAtLeast2Characters;

  /// No description provided for @nameCanOnlyContainLetters.
  ///
  /// In en, this message translates to:
  /// **'Name can only contain letters and spaces'**
  String get nameCanOnlyContainLetters;

  /// No description provided for @pleaseEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// No description provided for @pleaseEnterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhone;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @newPasswordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get newPasswordSameAsCurrent;

  /// No description provided for @noUserSignedIn.
  ///
  /// In en, this message translates to:
  /// **'No user is currently signed in'**
  String get noUserSignedIn;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak'**
  String get passwordTooWeak;

  /// No description provided for @pleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign out and sign in again before changing your password'**
  String get pleaseSignInAgain;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection'**
  String get networkError;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later'**
  String get tooManyAttempts;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in instead'**
  String get emailAlreadyInUse;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid'**
  String get invalidEmail;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Please use at least 6 characters'**
  String get weakPassword;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User with email {email} not found'**
  String userNotFound(Object email);

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again'**
  String get incorrectPassword;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled'**
  String get accountDisabled;

  /// No description provided for @tooManyFailedAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later'**
  String get tooManyFailedAttempts;

  /// No description provided for @invalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredential;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email/password sign-in is not enabled. Please contact support'**
  String get operationNotAllowed;

  /// No description provided for @invalidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailAddress;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please sign in or use forgot password.'**
  String get emailAlreadyExists;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// No description provided for @failedToResendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend code. Please try again'**
  String get failedToResendCode;

  /// No description provided for @noPendingVerification.
  ///
  /// In en, this message translates to:
  /// **'No pending verification found. Please sign up again'**
  String get noPendingVerification;

  /// No description provided for @verificationCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Verification code not found. Please sign up again.'**
  String get verificationCodeNotFound;

  /// No description provided for @verificationCodeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This code has already been used.'**
  String get verificationCodeAlreadyUsed;

  /// No description provided for @verificationCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'Verification code has expired. Please sign up again.'**
  String get verificationCodeExpired;

  /// No description provided for @tooManyVerificationAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please sign up again.'**
  String get tooManyVerificationAttempts;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code. Please try again.'**
  String get invalidVerificationCode;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @noImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No image available'**
  String get noImageAvailable;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanel;

  /// No description provided for @manageYourApp.
  ///
  /// In en, this message translates to:
  /// **'Manage your app'**
  String get manageYourApp;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @adminMenu.
  ///
  /// In en, this message translates to:
  /// **'Admin Menu'**
  String get adminMenu;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @homeCards.
  ///
  /// In en, this message translates to:
  /// **'Home Cards'**
  String get homeCards;

  /// No description provided for @addSession.
  ///
  /// In en, this message translates to:
  /// **'Add Session'**
  String get addSession;

  /// No description provided for @manageDiseases.
  ///
  /// In en, this message translates to:
  /// **'Manage Diseases'**
  String get manageDiseases;

  /// No description provided for @addDisease.
  ///
  /// In en, this message translates to:
  /// **'Add Disease'**
  String get addDisease;

  /// No description provided for @editDisease.
  ///
  /// In en, this message translates to:
  /// **'Edit Disease'**
  String get editDisease;

  /// No description provided for @diseaseName.
  ///
  /// In en, this message translates to:
  /// **'Disease Name'**
  String get diseaseName;

  /// No description provided for @physical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get physical;

  /// No description provided for @mental.
  ///
  /// In en, this message translates to:
  /// **'Mental'**
  String get mental;

  /// No description provided for @emotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional'**
  String get emotional;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @displayOrder.
  ///
  /// In en, this message translates to:
  /// **'Display Order'**
  String get displayOrder;

  /// No description provided for @lowerNumbersFirst.
  ///
  /// In en, this message translates to:
  /// **'Lower numbers appear first'**
  String get lowerNumbersFirst;

  /// No description provided for @orderRequired.
  ///
  /// In en, this message translates to:
  /// **'Order is required'**
  String get orderRequired;

  /// No description provided for @mustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'Must be a number'**
  String get mustBeNumber;

  /// No description provided for @englishNameRequired.
  ///
  /// In en, this message translates to:
  /// **'English name is required'**
  String get englishNameRequired;

  /// No description provided for @diseaseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get diseaseCategory;

  /// No description provided for @diseaseCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease created successfully'**
  String get diseaseCreatedSuccessfully;

  /// No description provided for @diseaseUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease updated successfully'**
  String get diseaseUpdatedSuccessfully;

  /// No description provided for @diseaseDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease deleted successfully'**
  String get diseaseDeletedSuccessfully;

  /// No description provided for @deletingDiseaseKeepsCauses.
  ///
  /// In en, this message translates to:
  /// **'Note: Disease causes for this disease will NOT be deleted.'**
  String get deletingDiseaseKeepsCauses;

  /// No description provided for @noDiseasesFound.
  ///
  /// In en, this message translates to:
  /// **'No diseases found'**
  String get noDiseasesFound;

  /// No description provided for @tapToAddDisease.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add a disease'**
  String get tapToAddDisease;

  /// No description provided for @deleteDisease.
  ///
  /// In en, this message translates to:
  /// **'Delete Disease'**
  String get deleteDisease;

  /// No description provided for @deleteDiseaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete'**
  String get deleteDiseaseConfirm;

  /// No description provided for @manageDiseaseCauses.
  ///
  /// In en, this message translates to:
  /// **'Manage Disease Causes'**
  String get manageDiseaseCauses;

  /// No description provided for @addDiseaseCause.
  ///
  /// In en, this message translates to:
  /// **'Add Disease Cause'**
  String get addDiseaseCause;

  /// No description provided for @editDiseaseCause.
  ///
  /// In en, this message translates to:
  /// **'Edit Disease Cause'**
  String get editDiseaseCause;

  /// No description provided for @disease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get disease;

  /// No description provided for @selectADisease.
  ///
  /// In en, this message translates to:
  /// **'Select a disease'**
  String get selectADisease;

  /// No description provided for @pleaseSelectDisease.
  ///
  /// In en, this message translates to:
  /// **'Please select a disease'**
  String get pleaseSelectDisease;

  /// No description provided for @diseaseCauseContent.
  ///
  /// In en, this message translates to:
  /// **'Disease Cause Content'**
  String get diseaseCauseContent;

  /// No description provided for @describeDiseaseHelp.
  ///
  /// In en, this message translates to:
  /// **'Describe the root cause of this disease and how the session helps...'**
  String get describeDiseaseHelp;

  /// No description provided for @diseaseCauseCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease cause created successfully'**
  String get diseaseCauseCreatedSuccessfully;

  /// No description provided for @diseaseCauseUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease cause updated successfully'**
  String get diseaseCauseUpdatedSuccessfully;

  /// No description provided for @diseaseCauseDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Disease cause deleted successfully'**
  String get diseaseCauseDeletedSuccessfully;

  /// No description provided for @noDiseaseCausesFound.
  ///
  /// In en, this message translates to:
  /// **'No disease causes found'**
  String get noDiseaseCausesFound;

  /// No description provided for @tapToAddDiseaseCause.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add a disease cause'**
  String get tapToAddDiseaseCause;

  /// No description provided for @deleteDiseaseCause.
  ///
  /// In en, this message translates to:
  /// **'Delete Disease Cause'**
  String get deleteDiseaseCause;

  /// No description provided for @deleteDiseaseCauseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the disease cause for'**
  String get deleteDiseaseCauseConfirm;

  /// No description provided for @forDisease.
  ///
  /// In en, this message translates to:
  /// **'For:'**
  String get forDisease;

  /// No description provided for @updateDisease.
  ///
  /// In en, this message translates to:
  /// **'Update Disease'**
  String get updateDisease;

  /// No description provided for @updateDiseaseCause.
  ///
  /// In en, this message translates to:
  /// **'Update Disease Cause'**
  String get updateDiseaseCause;

  /// No description provided for @recommendsSession.
  ///
  /// In en, this message translates to:
  /// **'Recommends: Session'**
  String get recommendsSession;

  /// No description provided for @recommendedSession.
  ///
  /// In en, this message translates to:
  /// **'Recommended Session'**
  String get recommendedSession;

  /// No description provided for @selectASession.
  ///
  /// In en, this message translates to:
  /// **'Select a session'**
  String get selectASession;

  /// No description provided for @pleaseSelectSession.
  ///
  /// In en, this message translates to:
  /// **'Please select a session'**
  String get pleaseSelectSession;

  /// No description provided for @englishContentRequired.
  ///
  /// In en, this message translates to:
  /// **'English content is required'**
  String get englishContentRequired;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillAllFields;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorDeletingData.
  ///
  /// In en, this message translates to:
  /// **'Error deleting data'**
  String get errorDeletingData;

  /// No description provided for @updateSession.
  ///
  /// In en, this message translates to:
  /// **'Update Session'**
  String get updateSession;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get createSession;

  /// No description provided for @updateSymptom.
  ///
  /// In en, this message translates to:
  /// **'Update Symptom'**
  String get updateSymptom;

  /// No description provided for @updateEmotionalMap.
  ///
  /// In en, this message translates to:
  /// **'Update Emotional Map'**
  String get updateEmotionalMap;

  /// No description provided for @pleaseLoginToAccessAdmin.
  ///
  /// In en, this message translates to:
  /// **'Please login to access admin panel'**
  String get pleaseLoginToAccessAdmin;

  /// No description provided for @adminAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get adminAccessRequired;

  /// No description provided for @totalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsers;

  /// No description provided for @premiumUsers.
  ///
  /// In en, this message translates to:
  /// **'Premium Users'**
  String get premiumUsers;

  /// No description provided for @totalCategories.
  ///
  /// In en, this message translates to:
  /// **'Total Categories'**
  String get totalCategories;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @newSessionAdded.
  ///
  /// In en, this message translates to:
  /// **'New session added to Sleep category'**
  String get newSessionAdded;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get hoursAgo;

  /// No description provided for @editSession.
  ///
  /// In en, this message translates to:
  /// **'Edit Session'**
  String get editSession;

  /// No description provided for @addNewSession.
  ///
  /// In en, this message translates to:
  /// **'Add New Session'**
  String get addNewSession;

  /// No description provided for @sessionNumber.
  ///
  /// In en, this message translates to:
  /// **'Session Number'**
  String get sessionNumber;

  /// No description provided for @sessionNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Session Number (№)'**
  String get sessionNumberLabel;

  /// No description provided for @sessionNumberHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 17'**
  String get sessionNumberHint;

  /// No description provided for @sessionNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Unique number for this session'**
  String get sessionNumberHelper;

  /// No description provided for @sessionNumberAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Session number already exists!'**
  String get sessionNumberAlreadyExists;

  /// No description provided for @emoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emoji;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @audioFiles.
  ///
  /// In en, this message translates to:
  /// **'Audio Files'**
  String get audioFiles;

  /// No description provided for @subliminalAudio.
  ///
  /// In en, this message translates to:
  /// **'Subliminal Audio'**
  String get subliminalAudio;

  /// No description provided for @backgroundImages.
  ///
  /// In en, this message translates to:
  /// **'Background Images'**
  String get backgroundImages;

  /// No description provided for @backgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Background Image'**
  String get backgroundImage;

  /// No description provided for @noAudioSelected.
  ///
  /// In en, this message translates to:
  /// **'No audio selected'**
  String get noAudioSelected;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @existing.
  ///
  /// In en, this message translates to:
  /// **'Existing'**
  String get existing;

  /// No description provided for @audioFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Audio file too large! Max 500MB allowed'**
  String get audioFileTooLarge;

  /// No description provided for @imageFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image file too large! Max 10MB allowed'**
  String get imageFileTooLarge;

  /// No description provided for @errorSelectingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error selecting audio'**
  String get errorSelectingAudio;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @pleaseEnterTitleInOneLang.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title in at least one language'**
  String get pleaseEnterTitleInOneLang;

  /// No description provided for @startingUpload.
  ///
  /// In en, this message translates to:
  /// **'Starting upload...'**
  String get startingUpload;

  /// No description provided for @uploadingAudio.
  ///
  /// In en, this message translates to:
  /// **'Uploading audio...'**
  String get uploadingAudio;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @savingSessionData.
  ///
  /// In en, this message translates to:
  /// **'Saving session data...'**
  String get savingSessionData;

  /// No description provided for @sessionSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Session saved successfully!'**
  String get sessionSavedSuccessfully;

  /// No description provided for @errorSavingSession.
  ///
  /// In en, this message translates to:
  /// **'Error saving session'**
  String get errorSavingSession;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @addNewAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add New Admin'**
  String get addNewAdmin;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add Admin'**
  String get addAdmin;

  /// No description provided for @currentAdmins.
  ///
  /// In en, this message translates to:
  /// **'Current Admins'**
  String get currentAdmins;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @removeAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin Access'**
  String get removeAdminAccess;

  /// No description provided for @removeAdminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove admin access?'**
  String get removeAdminConfirm;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @adminAccessRemoved.
  ///
  /// In en, this message translates to:
  /// **'Admin access removed'**
  String get adminAccessRemoved;

  /// No description provided for @adminAccessGranted.
  ///
  /// In en, this message translates to:
  /// **'Admin access granted to {email}'**
  String adminAccessGranted(Object email);

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get adminManagement;

  /// No description provided for @categoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Category Management'**
  String get categoryManagement;

  /// No description provided for @addNewCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addNewCategory;

  /// No description provided for @updateCategory.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get updateCategory;

  /// No description provided for @categoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category updated successfully!'**
  String get categoryUpdatedSuccessfully;

  /// No description provided for @errorUpdatingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error updating category'**
  String get errorUpdatingCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryNameHint;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories'**
  String get errorLoadingCategories;

  /// No description provided for @noCategoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get noCategoriesYet;

  /// No description provided for @noCardsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cards available'**
  String get noCardsAvailable;

  /// No description provided for @addFirstCategory.
  ///
  /// In en, this message translates to:
  /// **'Add your first category above'**
  String get addFirstCategory;

  /// No description provided for @pleaseEnterCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a category name'**
  String get pleaseEnterCategoryName;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @categoryAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category added successfully!'**
  String get categoryAddedSuccessfully;

  /// No description provided for @errorAddingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error adding category'**
  String get errorAddingCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get editCategory;

  /// No description provided for @selectEmoji.
  ///
  /// In en, this message translates to:
  /// **'Select Emoji'**
  String get selectEmoji;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?\n\nNote: Sessions in this category will NOT be deleted.'**
  String deleteCategoryConfirm(Object title);

  /// No description provided for @thisCategoryLower.
  ///
  /// In en, this message translates to:
  /// **'this category'**
  String get thisCategoryLower;

  /// No description provided for @categoryDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Category deleted successfully'**
  String get categoryDeletedSuccessfully;

  /// No description provided for @errorDeletingCategory.
  ///
  /// In en, this message translates to:
  /// **'Error deleting category'**
  String get errorDeletingCategory;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(Object count);

  /// No description provided for @hoursAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgoFull(Object count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(Object count);

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @sessionManagement.
  ///
  /// In en, this message translates to:
  /// **'Session Management'**
  String get sessionManagement;

  /// No description provided for @deleteSession.
  ///
  /// In en, this message translates to:
  /// **'Delete Session'**
  String get deleteSession;

  /// No description provided for @deleteSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this session?'**
  String get deleteSessionConfirm;

  /// No description provided for @sessionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Session deleted successfully'**
  String get sessionDeletedSuccessfully;

  /// No description provided for @noSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get noSessionsFound;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Admin Settings'**
  String get adminSettings;

  /// No description provided for @homeCardsManagement.
  ///
  /// In en, this message translates to:
  /// **'Home Cards Management'**
  String get homeCardsManagement;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @imagesRandomRotation.
  ///
  /// In en, this message translates to:
  /// **'{count} images • Random rotation'**
  String imagesRandomRotation(Object count);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @manageImagesFor.
  ///
  /// In en, this message translates to:
  /// **'Manage Images for {title}'**
  String manageImagesFor(Object title);

  /// No description provided for @addImages.
  ///
  /// In en, this message translates to:
  /// **'Add Images'**
  String get addImages;

  /// No description provided for @saveImages.
  ///
  /// In en, this message translates to:
  /// **'Save Images'**
  String get saveImages;

  /// No description provided for @noImagesYet.
  ///
  /// In en, this message translates to:
  /// **'No Images Yet'**
  String get noImagesYet;

  /// No description provided for @addImagesToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add images to get started'**
  String get addImagesToGetStarted;

  /// No description provided for @imagesUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{success} images uploaded successfully'**
  String imagesUploadedSuccessfully(Object success);

  /// No description provided for @imagesFailed.
  ///
  /// In en, this message translates to:
  /// **'{fail} failed'**
  String imagesFailed(Object fail);

  /// No description provided for @errorUploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Error uploading images'**
  String get errorUploadingImages;

  /// No description provided for @imageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Image removed'**
  String get imageRemoved;

  /// No description provided for @pleaseAddAtLeast3Images.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 3 images'**
  String get pleaseAddAtLeast3Images;

  /// No description provided for @maximum10ImagesAllowed.
  ///
  /// In en, this message translates to:
  /// **'Maximum 10 images allowed'**
  String get maximum10ImagesAllowed;

  /// No description provided for @imagesSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Images saved successfully'**
  String get imagesSavedSuccessfully;

  /// No description provided for @errorSavingImages.
  ///
  /// In en, this message translates to:
  /// **'Error saving images'**
  String get errorSavingImages;

  /// No description provided for @loadingText.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingText;

  /// No description provided for @errorLoadingCard.
  ///
  /// In en, this message translates to:
  /// **'Error loading card'**
  String get errorLoadingCard;

  /// No description provided for @cardEnabled.
  ///
  /// In en, this message translates to:
  /// **'Card enabled'**
  String get cardEnabled;

  /// No description provided for @cardDisabled.
  ///
  /// In en, this message translates to:
  /// **'Card disabled'**
  String get cardDisabled;

  /// No description provided for @manageImages.
  ///
  /// In en, this message translates to:
  /// **'Manage Images'**
  String get manageImages;

  /// No description provided for @randomBackgroundImages.
  ///
  /// In en, this message translates to:
  /// **'Random Background Images'**
  String get randomBackgroundImages;

  /// No description provided for @addImagesInfo.
  ///
  /// In en, this message translates to:
  /// **'Add 3-10 images. One will be randomly selected each time the home screen loads.'**
  String get addImagesInfo;

  /// No description provided for @imagesUploaded.
  ///
  /// In en, this message translates to:
  /// **'images uploaded successfully'**
  String get imagesUploaded;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get failed;

  /// No description provided for @contentMultiLanguage.
  ///
  /// In en, this message translates to:
  /// **'📝 Content (Multi-Language)'**
  String get contentMultiLanguage;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editing;

  /// No description provided for @enterSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter session title'**
  String get enterSessionTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterSessionDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter session description'**
  String get enterSessionDescription;

  /// No description provided for @introductionTitle.
  ///
  /// In en, this message translates to:
  /// **'Introduction Title'**
  String get introductionTitle;

  /// No description provided for @introductionContent.
  ///
  /// In en, this message translates to:
  /// **'Introduction Content'**
  String get introductionContent;

  /// No description provided for @describeWhatSessionDoes.
  ///
  /// In en, this message translates to:
  /// **'Describe what this session does...'**
  String get describeWhatSessionDoes;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon'**
  String get categoryIcon;

  /// No description provided for @tapToChooseIcon.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose an icon for this category'**
  String get tapToChooseIcon;

  /// No description provided for @selectIcon.
  ///
  /// In en, this message translates to:
  /// **'Select Icon'**
  String get selectIcon;

  /// No description provided for @failedToSaveDisease.
  ///
  /// In en, this message translates to:
  /// **'Failed to save disease'**
  String get failedToSaveDisease;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get selectGender;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @originalCategoryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Original category was deleted. Please select a new category.'**
  String get originalCategoryDeleted;

  /// No description provided for @pleaseAddAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 1 image'**
  String get pleaseAddAtLeastOneImage;

  /// No description provided for @categoryImagesInfo.
  ///
  /// In en, this message translates to:
  /// **'Add 1-10 images. One will be randomly selected each time.'**
  String get categoryImagesInfo;

  /// No description provided for @showingOnlyYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Showing only your language'**
  String get showingOnlyYourLanguage;

  /// No description provided for @showingAllLanguages.
  ///
  /// In en, this message translates to:
  /// **'Showing all languages'**
  String get showingAllLanguages;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get images;

  /// No description provided for @unknownDisease.
  ///
  /// In en, this message translates to:
  /// **'Unknown Disease'**
  String get unknownDisease;

  /// No description provided for @browseAllSubliminals.
  ///
  /// In en, this message translates to:
  /// **'Browse all available subliminal sessions'**
  String get browseAllSubliminals;

  /// No description provided for @yourPersonalizedCollection.
  ///
  /// In en, this message translates to:
  /// **'Your personalized subliminal collection'**
  String get yourPersonalizedCollection;

  /// No description provided for @deletingSessionAndFiles.
  ///
  /// In en, this message translates to:
  /// **'Deleting session and files...'**
  String get deletingSessionAndFiles;

  /// No description provided for @errorDeletingSession.
  ///
  /// In en, this message translates to:
  /// **'Error deleting session'**
  String get errorDeletingSession;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @unlockAndListen.
  ///
  /// In en, this message translates to:
  /// **'Unlock & Listen'**
  String get unlockAndListen;

  /// No description provided for @listenNow.
  ///
  /// In en, this message translates to:
  /// **'Listen Now'**
  String get listenNow;

  /// No description provided for @startEmotionalTestFree.
  ///
  /// In en, this message translates to:
  /// **'Start My Emotional Test — Free'**
  String get startEmotionalTestFree;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @noDiseasesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No diseases available'**
  String get noDiseasesAvailable;

  /// No description provided for @mensTest.
  ///
  /// In en, this message translates to:
  /// **'Men\'s Test'**
  String get mensTest;

  /// No description provided for @womensTest.
  ///
  /// In en, this message translates to:
  /// **'Women\'s Test'**
  String get womensTest;

  /// No description provided for @yourResults.
  ///
  /// In en, this message translates to:
  /// **'Your Results'**
  String get yourResults;

  /// No description provided for @selectedDiseases.
  ///
  /// In en, this message translates to:
  /// **'Selected Diseases'**
  String get selectedDiseases;

  /// No description provided for @diseases.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get diseases;

  /// No description provided for @whyIsThisCaused.
  ///
  /// In en, this message translates to:
  /// **'Why is this caused?'**
  String get whyIsThisCaused;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get seeLess;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @noHealingSessionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No healing session available for this disease yet.'**
  String get noHealingSessionAvailable;

  /// No description provided for @seeXMore.
  ///
  /// In en, this message translates to:
  /// **'See {count} More'**
  String seeXMore(int count);

  /// No description provided for @session.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get session;

  /// No description provided for @couldNotOpenSession.
  ///
  /// In en, this message translates to:
  /// **'Could not open session'**
  String get couldNotOpenSession;

  /// No description provided for @noHealingSessionYetWorkingOnIt.
  ///
  /// In en, this message translates to:
  /// **'No healing session available for this condition yet. Our team is working on it!'**
  String get noHealingSessionYetWorkingOnIt;

  /// No description provided for @loadingRecommendation.
  ///
  /// In en, this message translates to:
  /// **'Loading recommendation...'**
  String get loadingRecommendation;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Avatar'**
  String get chooseAvatar;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No Downloads'**
  String get noDownloads;

  /// No description provided for @noDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'Download sessions to listen offline without internet'**
  String get noDownloadsMessage;

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove Download'**
  String get removeDownload;

  /// No description provided for @removeDownloadMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the downloaded file from your device'**
  String get removeDownloadMessage;

  /// No description provided for @storageUsed.
  ///
  /// In en, this message translates to:
  /// **'Storage Used'**
  String get storageUsed;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// No description provided for @clearAllDownloads.
  ///
  /// In en, this message translates to:
  /// **'Clear All Downloads'**
  String get clearAllDownloads;

  /// No description provided for @clearAllDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all downloaded sessions from your device'**
  String get clearAllDownloadsMessage;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download Complete'**
  String get downloadComplete;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download Failed'**
  String get downloadFailed;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// No description provided for @offlineModeMessage.
  ///
  /// In en, this message translates to:
  /// **'Only downloaded sessions are available'**
  String get offlineModeMessage;

  /// No description provided for @offlineListening.
  ///
  /// In en, this message translates to:
  /// **'Listen to downloaded sessions offline'**
  String get offlineListening;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get youAreOffline;

  /// No description provided for @offlineDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to access all features, or listen to your downloaded sessions.'**
  String get offlineDescription;

  /// No description provided for @goToDownloads.
  ///
  /// In en, this message translates to:
  /// **'Go to Downloads'**
  String get goToDownloads;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @stillOffline.
  ///
  /// In en, this message translates to:
  /// **'Still offline. Please check your connection.'**
  String get stillOffline;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet'**
  String get noInternet;

  /// No description provided for @internetRequiredForFirstLogin.
  ///
  /// In en, this message translates to:
  /// **'Internet connection is required for first login. Please connect and try again.'**
  String get internetRequiredForFirstLogin;

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing...'**
  String get preparing;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// No description provided for @lightModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Classic bright theme'**
  String get lightModeSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// No description provided for @darkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get darkModeSubtitle;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemDefault;

  /// No description provided for @systemDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow device settings'**
  String get systemDefaultSubtitle;

  /// No description provided for @minutesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'minutes this week'**
  String get minutesThisWeek;

  /// No description provided for @minutesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'minutes this month'**
  String get minutesThisMonth;

  /// No description provided for @minutesThisYear.
  ///
  /// In en, this message translates to:
  /// **'minutes this year'**
  String get minutesThisYear;

  /// No description provided for @minutesAllTime.
  ///
  /// In en, this message translates to:
  /// **'minutes all time'**
  String get minutesAllTime;

  /// No description provided for @tooManyResetRequestsHourly.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again in an hour.'**
  String get tooManyResetRequestsHourly;

  /// No description provided for @tooManyResetRequestsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached. Please try again tomorrow.'**
  String get tooManyResetRequestsDaily;

  /// No description provided for @quizCategories.
  ///
  /// In en, this message translates to:
  /// **'Quiz Categories'**
  String get quizCategories;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get both;

  /// No description provided for @names.
  ///
  /// In en, this message translates to:
  /// **'Names'**
  String get names;

  /// No description provided for @selectCategoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Select Category (Optional)'**
  String get selectCategoryOptional;

  /// No description provided for @noCategory.
  ///
  /// In en, this message translates to:
  /// **'No Category'**
  String get noCategory;

  /// No description provided for @addYourFirstQuizCategory.
  ///
  /// In en, this message translates to:
  /// **'Add your first quiz category'**
  String get addYourFirstQuizCategory;

  /// No description provided for @deleteCategoryWithDiseaseNote.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{categoryName}\"?\n\nNote: Diseases in this category will not be deleted, but their category reference will be removed.'**
  String deleteCategoryWithDiseaseNote(String categoryName);

  /// No description provided for @failedToSaveCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to save category'**
  String get failedToSaveCategory;

  /// No description provided for @failedToDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete category'**
  String get failedToDeleteCategory;

  /// No description provided for @grantSubscription.
  ///
  /// In en, this message translates to:
  /// **'Grant Subscription'**
  String get grantSubscription;

  /// No description provided for @quizTab.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTab;

  /// No description provided for @quizCategoriesSection.
  ///
  /// In en, this message translates to:
  /// **'Quiz Categories'**
  String get quizCategoriesSection;

  /// No description provided for @diseasesSection.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get diseasesSection;

  /// No description provided for @sessionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionAvailable;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming'**
  String get comingSoon;

  /// No description provided for @searchQuizHint.
  ///
  /// In en, this message translates to:
  /// **'Search diseases, categories...'**
  String get searchQuizHint;
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
      <String>['en', 'hi', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
