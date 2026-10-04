abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const otp = '/verify';
  static const register = '/register';
  static const registrationSuccess = '/registration-success';
  static const home = '/home';
  static const categories = '/categories';
  static const myLearning = '/my-learning';
  static const search = '/search';
  static const assessments = '/assessments';
  static const activities = '/activities';
  static const quizReview = '/quiz-review';
  static const gallery = '/gallery';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const completeProfile = '/profile/complete';
  static const notifications = '/notifications';
  static const downloads = '/downloads';
  static const achievements = '/achievements';
  static const plans = '/plans';
  static const faq = '/faq';
  static const privacy = '/privacy';
  static const terms = '/terms';
  static const about = '/about';
  static const contact = '/contact';
  static const logout = '/logout';
  static String detail(String id) => '/detail/${Uri.encodeComponent(id)}';
  static String checkout(String id) => '/checkout/${Uri.encodeComponent(id)}';
  static String quiz(String id) => '/quiz/${Uri.encodeComponent(id)}';
  static String lesson(String courseId, int index) =>
      '/lesson/${Uri.encodeComponent(courseId)}/$index';
  static String album(String id) => '/gallery/${Uri.encodeComponent(id)}';
}
