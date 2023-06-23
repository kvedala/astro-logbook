// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Add observation`
  String get addObservation {
    return Intl.message(
      'Add observation',
      name: 'addObservation',
      desc: '',
      args: [],
    );
  }

  /// `Record observation`
  String get recordObservation {
    return Intl.message(
      'Record observation',
      name: 'recordObservation',
      desc: '',
      args: [],
    );
  }

  /// `Astronomy Log Book`
  String get appTitle {
    return Intl.message(
      'Astronomy Log Book',
      name: 'appTitle',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Cannot be NULL`
  String get cannotBeNull {
    return Intl.message(
      'Cannot be NULL',
      name: 'cannotBeNull',
      desc: '',
      args: [],
    );
  }

  /// `Cannot be empty`
  String get cannotBeEmpty {
    return Intl.message(
      'Cannot be empty',
      name: 'cannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Messier #`
  String get messierNumber {
    return Intl.message(
      'Messier #',
      name: 'messierNumber',
      desc: '',
      args: [],
    );
  }

  /// `Cannot be negative`
  String get cannotBeNegative {
    return Intl.message(
      'Cannot be negative',
      name: 'cannotBeNegative',
      desc: '',
      args: [],
    );
  }

  /// `Messier catalog numbers are only upto 110`
  String get messierCatalogNumbersAreOnlyUpto110 {
    return Intl.message(
      'Messier catalog numbers are only upto 110',
      name: 'messierCatalogNumbersAreOnlyUpto110',
      desc: '',
      args: [],
    );
  }

  /// `NGC #`
  String get ngcNumber {
    return Intl.message(
      'NGC #',
      name: 'ngcNumber',
      desc: '',
      args: [],
    );
  }

  /// `Not a valid number`
  String get notAValidNumber {
    return Intl.message(
      'Not a valid number',
      name: 'notAValidNumber',
      desc: '',
      args: [],
    );
  }

  /// `Not a number`
  String get notANumber {
    return Intl.message(
      'Not a number',
      name: 'notANumber',
      desc: '',
      args: [],
    );
  }

  /// `Invalid range`
  String get invalidRange {
    return Intl.message(
      'Invalid range',
      name: 'invalidRange',
      desc: '',
      args: [],
    );
  }

  /// `Longitude`
  String get longitude {
    return Intl.message(
      'Longitude',
      name: 'longitude',
      desc: '',
      args: [],
    );
  }

  /// `Location - Enter Address`
  String get locationEnterAddress {
    return Intl.message(
      'Location - Enter Address',
      name: 'locationEnterAddress',
      desc: '',
      args: [],
    );
  }

  /// `Location`
  String get location {
    return Intl.message(
      'Location',
      name: 'location',
      desc: '',
      args: [],
    );
  }

  /// `Value cannot be null`
  String get valueCannotBeNull {
    return Intl.message(
      'Value cannot be null',
      name: 'valueCannotBeNull',
      desc: '',
      args: [],
    );
  }

  /// `Value cannot be empty`
  String get valueCannotBeEmpty {
    return Intl.message(
      'Value cannot be empty',
      name: 'valueCannotBeEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Equipment used`
  String get equipmentUsed {
    return Intl.message(
      'Equipment used',
      name: 'equipmentUsed',
      desc: '',
      args: [],
    );
  }

  /// `Date & Time of observation`
  String get dateTimeOfObservation {
    return Intl.message(
      'Date & Time of observation',
      name: 'dateTimeOfObservation',
      desc: '',
      args: [],
    );
  }

  /// `Seeing`
  String get seeing {
    return Intl.message(
      'Seeing',
      name: 'seeing',
      desc: '',
      args: [],
    );
  }

  /// `Transparency`
  String get transparency {
    return Intl.message(
      'Transparency',
      name: 'transparency',
      desc: '',
      args: [],
    );
  }

  /// `Notes:`
  String get notes {
    return Intl.message(
      'Notes:',
      name: 'notes',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message(
      'Submit',
      name: 'submit',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Add Note:`
  String get addNote {
    return Intl.message(
      'Add Note:',
      name: 'addNote',
      desc: '',
      args: [],
    );
  }

  /// `Edit Note:`
  String get editNote {
    return Intl.message(
      'Edit Note:',
      name: 'editNote',
      desc: '',
      args: [],
    );
  }

  /// `Accept`
  String get accept {
    return Intl.message(
      'Accept',
      name: 'accept',
      desc: '',
      args: [],
    );
  }

  /// `New Observation`
  String get newObservation {
    return Intl.message(
      'New Observation',
      name: 'newObservation',
      desc: '',
      args: [],
    );
  }

  /// `Add checklist item`
  String get addChecklistItem {
    return Intl.message(
      'Add checklist item',
      name: 'addChecklistItem',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
  }

  /// `Save Checklist`
  String get saveChecklist {
    return Intl.message(
      'Save Checklist',
      name: 'saveChecklist',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure?`
  String get areYouSure {
    return Intl.message(
      'Are you sure?',
      name: 'areYouSure',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get thisActionCannotBeUndone {
    return Intl.message(
      'This action cannot be undone.',
      name: 'thisActionCannotBeUndone',
      desc: '',
      args: [],
    );
  }

  /// `Observations`
  String get observations {
    return Intl.message(
      'Observations',
      name: 'observations',
      desc: '',
      args: [],
    );
  }

  /// `Equipment`
  String get equipment {
    return Intl.message(
      'Equipment',
      name: 'equipment',
      desc: '',
      args: [],
    );
  }

  /// `Checklist`
  String get checklist {
    return Intl.message(
      'Checklist',
      name: 'checklist',
      desc: '',
      args: [],
    );
  }

  /// `List of Objects`
  String get listOfObjects {
    return Intl.message(
      'List of Objects',
      name: 'listOfObjects',
      desc: '',
      args: [],
    );
  }

  /// `Weather Page`
  String get weatherPage {
    return Intl.message(
      'Weather Page',
      name: 'weatherPage',
      desc: '',
      args: [],
    );
  }

  /// `Settings Page`
  String get settingsPage {
    return Intl.message(
      'Settings Page',
      name: 'settingsPage',
      desc: '',
      args: [],
    );
  }

  /// `No display name available`
  String get noDisplayNameAvailable {
    return Intl.message(
      'No display name available',
      name: 'noDisplayNameAvailable',
      desc: '',
      args: [],
    );
  }

  /// `No public email available`
  String get noPublicEmailAvailable {
    return Intl.message(
      'No public email available',
      name: 'noPublicEmailAvailable',
      desc: '',
      args: [],
    );
  }

  /// `Sign Out`
  String get signOut {
    return Intl.message(
      'Sign Out',
      name: 'signOut',
      desc: '',
      args: [],
    );
  }

  /// `Cannot delete. Equipment is being referenced in an observation.`
  String get cannotDeleteEquipmentIsBeingReferencedInAnObservation {
    return Intl.message(
      'Cannot delete. Equipment is being referenced in an observation.',
      name: 'cannotDeleteEquipmentIsBeingReferencedInAnObservation',
      desc: '',
      args: [],
    );
  }

  /// `Add new equipment`
  String get addNewEquipment {
    return Intl.message(
      'Add new equipment',
      name: 'addNewEquipment',
      desc: '',
      args: [],
    );
  }

  /// `Telescope`
  String get telescope {
    return Intl.message(
      'Telescope',
      name: 'telescope',
      desc: '',
      args: [],
    );
  }

  /// `Canot be NULL`
  String get canotBeNull {
    return Intl.message(
      'Canot be NULL',
      name: 'canotBeNull',
      desc: '',
      args: [],
    );
  }

  /// `Telescope Aperture (mm)`
  String get telescopeApertureMm {
    return Intl.message(
      'Telescope Aperture (mm)',
      name: 'telescopeApertureMm',
      desc: '',
      args: [],
    );
  }

  /// `Focal Length (mm)`
  String get focalLengthMm {
    return Intl.message(
      'Focal Length (mm)',
      name: 'focalLengthMm',
      desc: '',
      args: [],
    );
  }

  /// `Mount`
  String get mount {
    return Intl.message(
      'Mount',
      name: 'mount',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update {
    return Intl.message(
      'Update',
      name: 'update',
      desc: '',
      args: [],
    );
  }

  /// `New Equipment`
  String get newEquipment {
    return Intl.message(
      'New Equipment',
      name: 'newEquipment',
      desc: '',
      args: [],
    );
  }

  /// `Updated Equipment`
  String get updatedEquipment {
    return Intl.message(
      'Updated Equipment',
      name: 'updatedEquipment',
      desc: '',
      args: [],
    );
  }

  /// `Date Range`
  String get dateRange {
    return Intl.message(
      'Date Range',
      name: 'dateRange',
      desc: '',
      args: [],
    );
  }

  /// `From date`
  String get fromDate {
    return Intl.message(
      'From date',
      name: 'fromDate',
      desc: '',
      args: [],
    );
  }

  /// `End date`
  String get endDate {
    return Intl.message(
      'End date',
      name: 'endDate',
      desc: '',
      args: [],
    );
  }

  /// `Observation Date:`
  String get observationDate {
    return Intl.message(
      'Observation Date:',
      name: 'observationDate',
      desc: '',
      args: [],
    );
  }

  /// `Messier`
  String get messier {
    return Intl.message(
      'Messier',
      name: 'messier',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
  }

  /// `New Value`
  String get newValue {
    return Intl.message(
      'New Value',
      name: 'newValue',
      desc: '',
      args: [],
    );
  }

  /// `Editing`
  String get editing {
    return Intl.message(
      'Editing',
      name: 'editing',
      desc: '',
      args: [],
    );
  }

  /// `Unable to delete the object.`
  String get unableToDeleteTheObject {
    return Intl.message(
      'Unable to delete the object.',
      name: 'unableToDeleteTheObject',
      desc: '',
      args: [],
    );
  }

  /// `Delete observation`
  String get deleteObservation {
    return Intl.message(
      'Delete observation',
      name: 'deleteObservation',
      desc: '',
      args: [],
    );
  }

  /// `Close details`
  String get closeDetails {
    return Intl.message(
      'Close details',
      name: 'closeDetails',
      desc: '',
      args: [],
    );
  }

  /// `Selected observations`
  String get selectedObservations {
    return Intl.message(
      'Selected observations',
      name: 'selectedObservations',
      desc: '',
      args: [],
    );
  }

  /// `Observation Summary`
  String get observationSummary {
    return Intl.message(
      'Observation Summary',
      name: 'observationSummary',
      desc: '',
      args: [],
    );
  }

  /// `Astronomy and Stargazing`
  String get astronomyAndStargazing {
    return Intl.message(
      'Astronomy and Stargazing',
      name: 'astronomyAndStargazing',
      desc: '',
      args: [],
    );
  }

  /// `Sky conditions`
  String get skyConditions {
    return Intl.message(
      'Sky conditions',
      name: 'skyConditions',
      desc: '',
      args: [],
    );
  }

  /// `Visibility`
  String get visibility {
    return Intl.message(
      'Visibility',
      name: 'visibility',
      desc: '',
      args: [],
    );
  }

  /// `Circumpolar`
  String get circumpolar {
    return Intl.message(
      'Circumpolar',
      name: 'circumpolar',
      desc: '',
      args: [],
    );
  }

  /// `Below Horizon`
  String get belowHorizon {
    return Intl.message(
      'Below Horizon',
      name: 'belowHorizon',
      desc: '',
      args: [],
    );
  }

  /// `Rise`
  String get rise {
    return Intl.message(
      'Rise',
      name: 'rise',
      desc: '',
      args: [],
    );
  }

  /// `Set`
  String get set {
    return Intl.message(
      'Set',
      name: 'set',
      desc: '',
      args: [],
    );
  }

  /// `Number of Observations`
  String get numberOfObservations {
    return Intl.message(
      'Number of Observations',
      name: 'numberOfObservations',
      desc: '',
      args: [],
    );
  }

  /// `User Stats`
  String get userStats {
    return Intl.message(
      'User Stats',
      name: 'userStats',
      desc: '',
      args: [],
    );
  }

  /// `Number of Equipment`
  String get numberOfEquipment {
    return Intl.message(
      'Number of Equipment',
      name: 'numberOfEquipment',
      desc: '',
      args: [],
    );
  }

  /// `Delete Account`
  String get deleteAccount {
    return Intl.message(
      'Delete Account',
      name: 'deleteAccount',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to delete your account? This action cannot be undone.`
  String get areYouSureYouWantToDeleteYourAccountThis {
    return Intl.message(
      'Are you sure you want to delete your account? This action cannot be undone.',
      name: 'areYouSureYouWantToDeleteYourAccountThis',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get delete {
    return Intl.message(
      'Delete',
      name: 'delete',
      desc: '',
      args: [],
    );
  }

  /// `Error with Apple Sign In`
  String get errorWithAppleSignIn {
    return Intl.message(
      'Error with Apple Sign In',
      name: 'errorWithAppleSignIn',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Google`
  String get signInWithGoogle {
    return Intl.message(
      'Sign in with Google',
      name: 'signInWithGoogle',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Apple`
  String get signInWithApple {
    return Intl.message(
      'Sign in with Apple',
      name: 'signInWithApple',
      desc: '',
      args: [],
    );
  }

  /// `Sign in with Facebook`
  String get signInWithFacebook {
    return Intl.message(
      'Sign in with Facebook',
      name: 'signInWithFacebook',
      desc: '',
      args: [],
    );
  }

  /// `Sign In Page`
  String get signInPage {
    return Intl.message(
      'Sign In Page',
      name: 'signInPage',
      desc: '',
      args: [],
    );
  }

  /// `My Logbook`
  String get myLogbook {
    return Intl.message(
      'My Logbook',
      name: 'myLogbook',
      desc: '',
      args: [],
    );
  }

  /// `Astronomy Log Book`
  String get astronomyLogBook {
    return Intl.message(
      'Astronomy Log Book',
      name: 'astronomyLogBook',
      desc: '',
      args: [],
    );
  }

  /// `Location permission not granted.`
  String get locationPermissionNotGranted {
    return Intl.message(
      'Location permission not granted.',
      name: 'locationPermissionNotGranted',
      desc: '',
      args: [],
    );
  }

  /// `Location service not available.`
  String get locationServiceNotAvailable {
    return Intl.message(
      'Location service not available.',
      name: 'locationServiceNotAvailable',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
