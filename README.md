# 🩸 BloodLinker

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white) ![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white) ![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

**BloodLinker** is a life-saving mobile application designed to bridge the gap between blood donors and patients in real-time. By removing middlemen and utilizing live data streams, it ensures critical requests are seen and acted upon instantly.

---

## Table of Contents

- [Project Description](#project-description)
- [Features](#features)
- [Screenshots](#screenshots)
- [Technical Architecture](#technical-architecture)
- [Tech Stack](#tech-stack)
- [Installation & Setup](#installation--setup)
- [Future Roadmap](#future-roadmap)
- [Contributing](#contributing)
- [Contact](#contact)

---

## Project Description

Blood donation delays can be fatal. **BloodLinker** solves this by creating a direct, real-time pipeline between those in need and those who can help.

Unlike traditional directories, BloodLinker features a **Live Dashboard** that updates instantly using Cloud Firestore streams. It allows users to post urgent requests with location details and provides a "One-Tap Call" feature that bypasses the app sandbox to trigger the native phone dialer, ensuring immediate communication.

## Features

- **Secure Authentication:** Robust email/password login system with session persistence using Firebase Auth.
- **Live Dashboard:** A real-time feed of blood requests that updates instantly on all devices without needing to refresh.
- **Smart Formatting:** Intelligent data parsing that converts raw database values (e.g., `bPositive`) into human-readable tags (`B+`).
- **One-Tap Contact:** Direct integration with the native Android/iOS dialer (`url_launcher`) to connect donors to patients immediately.
- **Secure Navigation:** Advanced navigation logic that clears history stacks upon logout to prevent unauthorized back-navigation.

## Screenshots

|              **Live Dashboard**              |                **Request Form**                 |               **Direct Call**                |
| :------------------------------------------: | :---------------------------------------------: | :------------------------------------------: |
| <img src="screenshots/home.png" width="250"> | <img src="screenshots/request.png" width="250"> | <img src="screenshots/call.png" width="250"> |

_(Note: These screenshots demonstrate the live data feed and the call-to-action interface.)_

## Technical Architecture

The app operates on a custom **Write/Read Pipeline** architecture:

1.  **Write Pipeline:**
    - User submits a `BloodRequest` form (Patient Name, Bags, Location).
    - Data is validated and pushed to the `requests` collection in Cloud Firestore.
2.  **Read Pipeline:**
    - The Dashboard uses a `StreamBuilder` to maintain a persistent connection to the database.
    - This ensures 0-latency updates when new requests come in.
3.  **Action Pipeline:**
    - The app uses `LaunchMode.externalApplication` to break out of the app sandbox and trigger the device's native phone functionality.

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Firebase Authentication](https://firebase.google.com/products/auth) & [Cloud Firestore](https://firebase.google.com/products/firestore)
- **State Management:** `provider`
- **Utilities:** `url_launcher` (for intent handling), `intl` (for timestamp formatting)

## Installation & Setup

This project is configured for immediate demonstration purposes.

### 1. Prerequisites

- Flutter SDK installed
- An Android Emulator or Physical Device

### 2. Clone the Repository

```bash
git clone [https://github.com/your-username/BloodLinker.git](https://github.com/your-username/BloodLinker.git)
cd BloodLinker
```
