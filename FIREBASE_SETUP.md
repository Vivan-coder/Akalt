# Firebase Setup Guide

Since the command-line tools are having permission issues, we will set up Firebase manually. It is a **website**, not a program you download.

## Step 1: Go to Firebase Console
Open this link in your browser:
👉 **[https://console.firebase.google.com/](https://console.firebase.google.com/)**

## Step 2: Create a Project
1. Click **"Create a project"** (or "Add project").
2. Name it **"Akalat"**.
3. You can disable Google Analytics for now to make it faster.
4. Click **"Create project"**.

## Step 3: Register Your App
Once your project is ready, you will see the dashboard.

### For Android:
1. Click the **Android icon** (🤖).
2. **Android package name**: `com.example.akalt` (or check `android/app/build.gradle` if you changed it).
👉 **[lib/firebase_options.dart](file:///c:/Users/vivan/OneDrive/Documents/GameTilt%20result%20page/.vscode/scratch/akalt/lib/firebase_options.dart)**

Replace the placeholders (like `'YOUR_WEB_API_KEY'`) with the real values you got from the Firebase Console.

## Step 5: Enable Authentication
1. Go back to Firebase Console.
2. Click **Build > Authentication** in the left menu.
3. Click **Get Started**.
4. Select **Email/Password**.
5. Enable the **Email/Password** switch.
6. Click **Save**.

---
Once you have updated `lib/firebase_options.dart` and (optionally) added `google-services.json`, the app should work!
