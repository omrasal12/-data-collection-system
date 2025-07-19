📦 Data Collection System
This project is a complete data collection solution built with three main components:

📱 Flutter App (data_collection1)

🧩 Dart SDK (inside Flutter lib/)

🖥️ .NET Backend API (WebApplication1)

🗃️ SQL Script (Sql code.txt)

🗂 Folder Structure

├── WebApplication1/          # ASP.NET Core Web API (C#)
│   └── Controllers/
│       └── HomeController.cs # Receives data from Flutter SDK
│


├── data_collection1/         # Flutter App
│   └── lib/
│       ├── main.dart         # App Entry Point
│       └── data_collection_sdk.dart  # SDK logic with batching
│

├── Sql code.txt              # SQL table & stored procedure
└── README.md

🏗 Architecture Diagram

Flutter App
   │
   │ uses
   ▼
Dart SDK (batching, send logic)
   │
   │ calls HTTP POST
   ▼
.NET Web API (HomeController.cs)
   │
   │ stores via SP
   ▼
SQL Server (Tables/Stored Procs)
🚀 How to Run the Project
✅ 1. Backend Server (.NET)
Requires: .NET SDK (7.0+), SQL Server

Open WebApplication1 in Visual Studio or VS Code.

Ensure connection string in appsettings.json points to your SQL server.

Run the SQL code in Sql code.txt to create the table and stored procedure.

Run the API:


dotnet run
✅ 2. Flutter App
Requires: Flutter SDK

Navigate to data_collection1

Run the app:

flutter pub get
flutter run
Grant permissions (SMS, Phone, Call Log)

The app uses the SDK to:

Read logs/SMS

Send transactional SMS immediately

Batch and flush others periodically to the backend

🧠 SDK Design Overview
The SDK is written in Dart (data_collection_sdk.dart)

Batching mechanism:

Collects up to 20 messages or waits for timeout (e.g., 30s)

Sends via HTTP POST to the backend

Transactional detection:

Uses keywords like "OTP", "payment", etc.

Sends these immediately to API

🎥 Demonstration Video (To Be Recorded)
Walkthrough of:

HomeController.cs logic for handling requests

main.dart calling the SDK

SDK collecting and batching messages

SQL showing inserted data

Show app running, permissions, and backend logging incoming data

👤 Collaborators
saurabh@clickpe.ai

harsh.srivastav@clickpe.ai

📜 License
Private repository for submission and review only. All rights reserved.
