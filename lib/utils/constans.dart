class AppConstans  {
  //App Info
  static const String appName = 'VoicePin';
  static const String appVersion = '1.0.0';

  //Datatbase
  static const String dbName = 'voicepin.db';
  static const int dbVersion = 1;
  static const String tableVoiceNotes = 'voice_notes';

  //Default Values
  static const double defaultRadius = 100.0; //metres
  static const double minRadius = 10.0;
  static const double maxRadius = 500.0;

  //Categories
  static const String categoryShopping ='Shopping';
  static const String categoryWork ='Work';
  static const String categoryPersonal ='Personal';
  static const String categoryOther ='Other';

  static const List<String> categories = [
    'categoryShopping',
    'categoryWork',
    'categoryPersonal',
    'categoryOther',
  ];

  static const List<String> categoryColorNames = [
    'green', //'Shopping'
    'orange', //'Work'
    'purple', //'Personal'
    'pink', //'Other'
  ];

  //Map
  static const double defaultZoom = 15.0;
  static const double markerZoom = 18.0;

  //Audio
  static const String audioExtension = '.aac';
  static const int maxRecordingSecons = 300; //5 minutes
}