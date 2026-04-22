// import 'package:shared_preferences/shared_preferences.dart';

// class PrefHelper {

//   static const String  _tokenKey ='auth_token';
//   static Future<void> savetoken(String token)async{
//     final  prefs =await SharedPreferences.getInstance();
//     await prefs.setString(_tokenKey, token);
//   }
  
//    static Future<void> gettoken()async{
//     final  prefs =await SharedPreferences.getInstance();
//     await prefs.get(_tokenKey);
//   } 
//    static Future<void> cleertoken()async{
//     final  prefs =await SharedPreferences.getInstance();
//     await prefs.remove(_tokenKey);
//   }
// }