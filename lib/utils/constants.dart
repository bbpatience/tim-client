class Constants {
  static const String KEY_LOGIN = 'key_login'; //false: show login page;
  static const String KEY_LOGIN_ACCOUNT = 'key_login_account';
  static const String KEY_LOGIN_ACCOUNT_MOBILE = 'key_login_account_mobile';
  static const String KEY_LOGIN_ACCOUNT_PORTRAIT = 'key_login_account_url';
  static const String KEY_LOGIN_UID = 'key_login_uid';
  static const String KEY_LOGIN_TOKEN = 'key_login_token';
  static const String KEY_ACCESS_NODE_IP = 'key_access_ip';
  static const String KEY_ACCESS_NODE_PORT = 'key_access_port';
  static const String INPUTFORMATTERS = '[a-zA-Z0-9!.?,~@#%^&*()]';
  static int currentPage = 0;

  static const int CONVERSATION_SINGLE = 0;
  static const int CONVERSATION_GROUP = 1;

  static const int CONTENT_TYPE_TEXT = 0;
  static const int CONTENT_TYPE_IMAGE = 1;
  static const int CONTENT_TYPE_VOICE = 2;
  static const int CONTENT_TYPE_VIDEO = 3;

  static const int PLAIN_MESSAGE = 0;
  static const int NOTIFICATION = 1;
  /* response code from */
  static const int RSP_COMMON_SUCCESS = 10000;

  static const String DEFAULT_PORTRAIT =
      "https://api.adorable.io/avatars/285/1.png";

  //group operation
  static const int GROUP_CHANGE_CREATE = 1;
  static const int GROUP_CHANGE_JOIN = 2;
  static const int GROUP_CHANGE_QUIT = 3;
  static const int GROUP_CHANGE_KICK = 4;
  static const int GROUP_CHANGE_DISMISS = 5;
}
