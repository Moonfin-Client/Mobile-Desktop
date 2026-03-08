import '../models/user.dart';

class UserRepository {
  User? _currentUser;

  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
  }
}
