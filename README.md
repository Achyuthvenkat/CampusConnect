# CampusConnect - College Freelancing Marketplace

A Flutter mobile application connecting college students for freelancing opportunities.

## Features

- 🔐 **Authentication** - College email (.edu) registration & login with Firebase Auth
- 👤 **Profiles** - Skills, hourly rates, portfolio, availability status
- 💼 **Jobs** - Post jobs, browse by category, filter by budget
- 💰 **Bidding** - Submit bids with proposals, accept/reject bids
- 💬 **Real-time Chat** - Direct messaging between clients and freelancers
- 🔔 **Push Notifications** - Firebase Cloud Messaging
- 🔖 **Bookmarks** - Save freelancers for later
- 📊 **Dashboard** - Manage posted jobs and submitted bids
- ⭐ **Reviews** - Rate and review after job completion

## Getting Started

### Setup

1. **Install dependencies**: `flutter pub get`
2. **Configure Firebase**:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
3. Enable Email/Password auth, Firestore, Storage, and FCM in Firebase Console
4. **Run**: `flutter run`

### Required Firestore Indexes

- `jobs`: `status` ASC, `createdAt` DESC
- `jobs`: `clientId` ASC, `createdAt` DESC
- `bids`: `jobId` ASC, `createdAt` DESC
- `chatRooms`: `participantIds` array-contains, `lastMessageTime` DESC

## Architecture

- **State**: Provider pattern
- **Backend**: Firebase (Auth, Firestore, Storage, FCM)
- **UI**: Material Design 3 with custom theme
