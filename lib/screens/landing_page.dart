import 'dart:ui';
import 'package:flutter/material.dart';
import 'student/login_student.dart';
import 'teacher/login_teacher.dart';
import 'admin/login_admin.dart';
import 'student/signup_student.dart';
import 'teacher/signup_teacher.dart';
import 'admin/signup_admin.dart';
import 'school_registration.dart';
import 'about_us.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  bool _isLoginVisible = false;
  bool _isSignupVisible = false;

  late final AnimationController _loginController;
  late final AnimationController _signupController;

  @override
  void initState() {
    super.initState();
    _loginController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _signupController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _loginController.dispose();
    _signupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    bool isMobile = screenSize.width < 600;

    return Scaffold(
    appBar: PreferredSize(
      preferredSize: Size(screenSize.width, isMobile ? 80 : 100),
      child: SafeArea(
        child: Container(
          color: Colors.blue[900],
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: isMobile ? 12 : 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ELIMU LMS',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildAboutUsButton(context, isMobile),
                      SizedBox(width: 10),
                      _buildRegisterSchoolButton(context, isMobile),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),

      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/kidlearning.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Container(color: Colors.black.withOpacity(0.2)),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width / 10, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "🎓 Welcome to Elimu LMS",
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMainActionButton("Sign Up", Colors.blueAccent, () {
                              setState(() {
                                _isSignupVisible = !_isSignupVisible;
                                _isLoginVisible = false;
                                _isSignupVisible
                                    ? _signupController.forward()
                                    : _signupController.reverse();
                              });
                            }, isMobile),
                            SizedBox(height: 12),
                            _buildMainActionButton("Log In", Colors.blueAccent, () {
                              setState(() {
                                _isLoginVisible = !_isLoginVisible;
                                _isSignupVisible = false;
                                _isLoginVisible
                                    ? _loginController.forward()
                                    : _loginController.reverse();
                              });
                            }, isMobile),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMainActionButton("Sign Up", Colors.blueAccent, () {
                              setState(() {
                                _isSignupVisible = !_isSignupVisible;
                                _isLoginVisible = false;
                                _isSignupVisible
                                    ? _signupController.forward()
                                    : _signupController.reverse();
                              });
                            }, isMobile),
                            SizedBox(width: 12),
                            _buildMainActionButton("Log In", Colors.blueAccent, () {
                              setState(() {
                                _isLoginVisible = !_isLoginVisible;
                                _isSignupVisible = false;
                                _isLoginVisible
                                    ? _loginController.forward()
                                    : _loginController.reverse();
                              });
                            }, isMobile),
                          ],
                        ),

                    SizedBox(height: 30),
                    AnimatedSize(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Column(
                        children: [
                          if (_isSignupVisible) ...[
                            _buildSignupRoleButton(context, "Student", Icons.school),
                            SizedBox(height: 10),
                            _buildSignupRoleButton(context, "Teacher", Icons.person),
                            SizedBox(height: 10),
                            _buildSignupRoleButton(context, "Admin", Icons.admin_panel_settings),
                          ],
                          if (_isLoginVisible) ...[
                            _buildLoginRoleButton(context, "Student", Icons.school),
                            SizedBox(height: 10),
                            _buildLoginRoleButton(context, "Teacher", Icons.person),
                            SizedBox(height: 10),
                            _buildLoginRoleButton(context, "Admin", Icons.admin_panel_settings),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutUsButton(BuildContext context, bool isMobile) {
  return InkWell(
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AboutUsPage()));
    },
    child: Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 6 : 14,
        horizontal: isMobile ? 14 : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "About Us",
        style: TextStyle(
          fontSize: isMobile ? 16 : 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
}

  Widget _buildRegisterSchoolButton(BuildContext context, bool isMobile) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => SchoolRegistrationPage()));
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 6 : 14,
          horizontal: isMobile ? 14 : 24,
        ),
        decoration: BoxDecoration(
          color: Colors.green[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Register School",
          style: TextStyle(
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }


  Widget _buildMainActionButton(String text, Color color, VoidCallback onPressed, bool isMobile) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 30, vertical: isMobile ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isMobile ? 14 : 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginRoleButton(BuildContext context, String role, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          "Login as $role",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          if (role == "Student") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LoginStudentPage()));
          } else if (role == "Teacher") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LoginTeacherPage()));
          } else if (role == "Admin") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LoginAdminPage()));
          }
        },
      ),
    );
  }

  Widget _buildSignupRoleButton(BuildContext context, String role, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          "Sign Up as $role",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          if (role == "Student") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpStudentPage()));
          } else if (role == "Teacher") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpTeacherPage()));
          } else if (role == "Admin") {
            Navigator.push(context, MaterialPageRoute(builder: (_) => SignUpAdminPage()));
          }
        },
      ),
    );
  }
}
