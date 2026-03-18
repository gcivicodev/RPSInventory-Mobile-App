# RPS Inventory Mobile App

Flutter-based mobile application for pharmaceutical and medical inventory management, delivery tracking (conduces), and warehouse stock control.

## 🚀 Project Overview

**RPS Inventory** is a specialized tool designed to manage medical supply chains. It handles the lifecycle of products, from warehouse storage to patient delivery, including signature capture, deductible calculations, and synchronization with a central REST API.

---

## 🛠 Technical Stack

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management:** [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Local Database:** [Sqflite](https://pub.dev/packages/sqflite) (SQLite for Flutter)
- **Networking:** `http` & `http_parser`
- **Scanning:** `mobile_scanner` (Barcode & QR)
- **E-Signatures:** `signature`
- **Data Persistence:** `shared_preferences`
- **Connectivity:** `connectivity_plus`

---

## 🏗 Project Architecture

The project follows a clean architecture pattern within the `lib/src` directory:

- `/config`: API configuration (`MainConfig`) and global constants.
- `/models`: PODO (Plain Old Dart Objects) for data representation and serialization.
- `/providers`: Logic controllers and state management using Riverpod.
- `/views`: UI components, screens, and custom widgets.
- `db_helper.dart`: Singleton manager for the local SQLite database, handling migrations (currently version 15) and complex queries.

---

## 📊 Core Data Entities

The application manages several key business entities locally and synchronizes them with the backend:

- **Products:** SKU, Item Number, Barcode, Categories, HCPC Codes, and Pricing.
- **Conduces (Delivery Notes):** Patient information, delivery status, signatures (Patient & Employee), and financial totals.
- **Warehouses:** Support for multiple storage locations (Physical Warehouses and Providers).
- **Movements:** Logs of all stock transfers between warehouses.
- **Inventory Audits:** Tools for periodic stock counting and reconciliation.
- **Deductibles:** Logic for medical plan coverage and patient responsibility.

---

## 📡 Backend Integration

- **Base URL:** `https://rpsinventory.com/`
- **API Path:** `public/api`
- **Sync Logic:** The app tracks `last_sync` timestamps to perform incremental updates, ensuring offline capability and data consistency.

---

## 📂 Directories & Files

- `assets/`: Contains images and sound files for scanning feedback.
- `lib/src/db_helper.dart`: The core of the offline-first strategy.
- `pubspec.yaml`: Project dependencies and metadata.

---

## 📝 Compliance & Protocol

All development changes must be recorded in the [AGENTS.md](AGENTS.md) file following the established documentation protocol.
