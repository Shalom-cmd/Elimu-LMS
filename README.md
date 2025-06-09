# Elimu LMS

Elimu LMS was intentionally designed for elementary school children in underserved communities who may not have consistent access to school, Wi-Fi, or modern devices. Elimu provides a lightweight, low-bandwidth, mobile-first solution that works offline and requires minimal storage. It’s meant to support students who are homeschooled, sick, or frequently absent, ensuring they can continue learning and stay connected to school. It's also a valuable tool for homeschooling parents and individual teachers who need a simple, reliable way to manage student records, assignments, and progress without relying on continuous internet access.

## Elimu Features:

### Student

#### Online Features:

Secure login using a fun, memorable username and password

Password rest if needed

Customize profile by choosing an avatar

View class resources (PDFs and YouTube links)

View and complete assignments and quizzes (text or file upload)

View grades and progress

Send and receive messages from teachers

#### Offline Access:

View previously loaded resources, assignments, and quizzes — even file-based ones (downloaded and stored locally)

Submit assignments and quizzes offline (text or file)

Offline submissions are automatically synced when the device reconnects to the internet

### Teacher
Secure login and password reset support

Create class resources (PDF or YouTube link), assignments, and quizzes (text-based or file-based)

View, edit, or delete assignments and quizzes

View student submissions

Grade and update student work

Send secure messages to students or admin

### Admin
Secure login 

Password rest if needed

Customize profile by choosing an avatar

View school roster

View class activity by grade

Send messages to teachers or students

### Offline Functionality (Students Only)

This app uses Hive, a lightweight local database for Flutter, to:

Cache user profile and grade info

Store assignments and quizzes for offline viewing

Queue submissions locally when offline, then syncs them to Firestore automatically when internet is restored

### How Hive Works:

Hive stores structured data in local files. When offline, Elimu reads from Hive instead of Firestore. When reconnected, it syncs pending submissions and updates the view.

### Important Notes

1. Assignments and quizzes may take up to 1 minute to load when offline. Please be patient.
2. If nothing loads after 4 minutes, it's likely an error—restart the app or check logs.
3. If you build and run on terminal you will see messages like:
    Saved offline. Will auto-submit later.
    Assignment submitted!
    Loaded 2 quizzes from Hive
4. When Firestore fetches fail, offline—errors like [cloud_firestore/unavailable] are expected.

### How to Test Offline Mode

  Sign in as a student while online.
  
  Open resources/assignments/quizzes — they will be cached automatically.
  
  Turn off Wi-Fi or disconnect emulator network.
  
  Reopen/Restart the app — previously loaded data should still display.
  
  Submit a quiz or assignment — you should see:
  
  - Saved offline. Will auto-submit later.
  
  Re-enable network. The app will sync automatically within seconds.

### Tech Stack

  Flutter + Dart
  
  Firebase (Auth, Firestore, Storage)
  
  Hive (Offline storage)
  
  Android Studio (for emulator testing)

