// navigation_service
import 'package:book_exchange/pages/user_page.dart';

import 'package:book_exchange/pages/register_page.dart';
import 'package:flutter/material.dart';
import 'package:book_exchange/pages/login_page.dart';
import 'package:book_exchange/pages/home_page.dart';
import 'package:book_exchange/pages/add_book.dart';

class NavigationService {
  late GlobalKey<NavigatorState> _navigatorKey;
  final Map<String, Widget Function(BuildContext)> _routes = {
    "/login": (context) => LoginPage(),
    "/register": (context) => RegisterPage(),
    "/home": (context) => Homepage(),
    "/user": (context) => UserPage(),
    "/addBook": (context) => AddBookPage(),
  };

  GlobalKey<NavigatorState>? get navigatorKey {
    return _navigatorKey;
  }

  Map<String, Widget Function(BuildContext)> get routes {
    return _routes;
  }

  NavigationService() {
    _navigatorKey = GlobalKey<NavigatorState>();
  }
  void push(MaterialPageRoute route) {
    _navigatorKey.currentState?.push(route);
  }

  void pushNamed(String routeName) {
    _navigatorKey.currentState?.pushNamed(routeName);
  }

  void pushReplacementNamed(String routeName) {
    _navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  void goBack() {
    _navigatorKey.currentState?.pop();
  }
}
