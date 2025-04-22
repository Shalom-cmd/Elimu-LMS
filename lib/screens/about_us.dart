import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text("About Elimu LMS"),
        backgroundColor: themeColor,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionCard(
              context,
              title: "🧠 What is Elimu LMS?",
              content:
                  "Elimu is an independent project—currently in progress—that I’m working on in my final semester of college. "
                  "It is a supplemental Learning Management System (LMS) focused on elementary school students.",
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              context,
              title: "🎯 Our Mission",
              content:
                  "I designed Elimu with underserved communities in mind. It’s meant to be a lightweight and scalable LMS "
                  "that works well in low-resource environments and on low-end devices. The goal is to make technology and education "
                  "more accessible to every student and teacher.",
            ),
            SizedBox(height: 20),
            _buildSectionCard(
              context,
              title: "🌍 Design Philosophy",
              content:
                  "Elimu focuses on simplicity, accessibility, and collaboration. It’s built to be intuitive and fun for students, "
                  "while also empowering teachers with tools that enhance engagement, communication, and creativity.",
            ),
            SizedBox(height: 20),
            _buildUseCaseSection(themeColor),
            SizedBox(height: 40),
            Center(
              child: Text(
                "Thank you for supporting Elimu! 💙",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required String content}) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueAccent)),
          SizedBox(height: 12),
          Text(content, style: TextStyle(fontSize: 18, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildUseCaseSection(Color themeColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🧩 How Elimu is Used",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: themeColor)),
          SizedBox(height: 12),
          Text(
            "Elimu is intended to supplement in-class learning, not replace it. It offers a playful and interactive way "
            "for students to stay engaged with educational content beyond the classroom — through assignments, quizzes, and creative rewards.",
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            "Whether it’s adopted school-wide, used by an individual teacher with their class, or integrated into a homeschool environment, "
            "Elimu is designed to adapt. It supports a variety of teaching models while staying lightweight, fun, and effective.",
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            "By encouraging consistent practice and reinforcing concepts in an engaging way, Elimu gives learners a sense of ownership and achievement in their educational journey.",
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
        ],
      ),
    );
  }
}
