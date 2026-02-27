# 🚀 FairTrack  
### Offline-to-Online Jobseeker Registration System

FairTrack is an **offline-first mobile application** that enables instant jobseeker registration at job fairs using resume scanning, OCR, and seamless cloud synchronization.

---

## 🚀 Problem Statement

At job fairs and walk-ins, many jobseekers lack internet access or smartphones, making digital registration slow or impossible. Manual data entry is time-consuming and inefficient.

FairTrack solves this by enabling **fast, offline registration with later online synchronization**.

---

## 💡 Solution Overview

FaieTrack allows volunteers to:

- 📷 Scan resumes using mobile camera  
- 🤖 Extract data using OCR (Google ML Kit)  
- 🧠 Parse unstructured resume text into structured fields  
- ✏️ Review and edit extracted data  
- 💾 Store data offline  
- 🔄 Sync all records to cloud (Supabase) when internet is available  
- 🔳 Generate QR codes for quick candidate access  

---

## 🧱 System Architecture

```
Resume Scan → OCR → AI Parsing → Editable Form → Local Storage → QR Generation
↓
Batch Sync (Online)
↓
Supabase DB
```

---

## ⚙️ Tech Stack

- **Flutter** – Mobile App Development  
- **Google ML Kit** – OCR (Text Recognition)  
- **Supabase** – Backend & Database  
- **SQLite / Local Storage** – Offline data handling  
- **QR Generator/Scanner** – Quick access system  

---

## ✨ Key Features

- ✅ Offline-first registration (no internet required)  
- ✅ Resume-to-form auto extraction  
- ✅ Editable preview before saving  
- ✅ Incremental Candidate ID (fair1, fair2…)  
- ✅ QR-based quick retrieval  
- ✅ Batch sync to cloud when online  
- ✅ Multi-page resume handling  
- ✅ Flexible parsing for different resume formats  

---

## 🔁 Workflow

1. Volunteer scans candidate resume  
2. OCR extracts raw text  
3. Parsing engine structures data  
4. User verifies/edit details  
5. Data saved locally with unique ID  
6. QR generated for candidate  
7. When online → batch sync to Supabase  

---

## 📊 Database Schema

| Field        | Type   | Description                  |
|-------------|--------|------------------------------|
| id          | UUID   | Primary key                  |
| display_id  | TEXT   | fair1, fair2…                |
| name        | TEXT   | Candidate name               |
| phone       | TEXT   | Contact number               |
| email       | TEXT   | Email address                |
| linkedin    | TEXT   | LinkedIn profile             |
| skills      | TEXT   | Comma-separated skills       |
| status      | TEXT   | pending / synced             |
| created_at  | TIMESTAMP | Record creation time     |

---

## 🔳 QR Code Format

```
Name: John Doe
Phone: 9876543210
Email: john@gmail.com

LinkedIn: linkedin.com/in/john
Skills: Python, SQL, Excel
```

---

## 🏆 Unique Selling Proposition

**Offline-first system that converts resumes into instant digital registrations with seamless online synchronization.**

---

## 📦 Installation & Run

```bash
flutter pub get
flutter run
```

Run on specific device:

```bash
flutter run -d <device_id>
```

📱 Build APK

```bash
flutter build apk --release
```

APK location:

build/app/outputs/flutter-apk/app-release.apk

🔐 Authentication

Supabase Authentication integrated

Secure password hashing

Login & Register flow implemented

📌 Future Improvements

- Advanced AI-based resume parsing
- Multi-language OCR support
- Recruiter dashboard
- Analytics and reporting
- Real-time sync optimization

👨‍💻 Contributors

- Rajeev Dhoni
- Team Members

📄 License

Developed for hackathon and educational purposes.

⭐ Acknowledgements

- Flutter
- Google ML Kit
- Supabase

---

# 🔥 THIS VERSION IS PERFECT FOR:

✔ Hackathon submission  
✔ GitHub showcase  
✔ Recruiter visibility  

---

If you want next:

👉 Add **badges (build status, tech stack icons)**  
👉 Or create **GitHub banner (very impressive visually)**
