# Period Tracker Tech Stack

This document is used for establishing the tech stack, foundational tools, core system architeccture, and checking for dependencies in the project.

## Flutter Period Tracker

Description: A simple, minimalist period tracking app that measures the menstruation periods, flow intensity, fertile windows, and observe other symptoms that is helpful for women across the world!

## Tech Stack

These are the main tech stack to be used in the codebase.

| Stack | Description |
| :============= | :=============================================================== |
| Flutter (Dart) | Main language for cross-platform support across Android and iOS. |
| Provider | For state and stateless management to prevent prop-drilling. |
| Supabase | Lightweight database sycing for data cloud backups. |
| `flutter_test` | Native Flutter UI testing. |
| Postman | For API testing. |

## Dependencies

These are the core dependencies needed in the Flutter period tracking app. Look at the `pubspec.yaml` file in the root folder and check if there are missed dependencies in the codebase and ask before installing:

| Dependency | Description |
| :=================== | :============================================================================ |
| cupertino_icons | iOS icons. |
| calendar_date_picker | Calendar date picker for menstruation period marking and other date markings. |
| intl | Handles inernalization and localization (regional formats). |
| clock | Tells the time of each entered queries in the app. |
| visibility_detector | Wraps any widget and triggers a callback function for screen changes. |
| hugeicons | A react icon library to be used in the project. |
| flutter_animate | Adds a smooth and seamless animations as you navigate through the app. |

| DevDependency | Description |
| :============ | :======================================================== |
| flutter_test | For widget testing. |
| flutter_lints | Handles the Dart syntax especially in the frontend layer. |

**OPTIONAL DEPENDENCIES**:

- **Python**: for data analysis and description (future use).

## MVVM Architecture

This Flutter Period Tracker follows the MVVM Architecture: Model-View-ViewModel. It separates the widgets (frontend) from business data logic (backend) and data logic (database) of an application.

**Sample Folder Structure**:

- Inside the root project folder, the `core/` folder contains all of the shared global themes, constants, utilities, etc.
- All of the database setups and schemas are stored in the `data/` folder.
- The subfolders and contents inside the `features/` folder shall strictly follow the MVVM architecture for each feature to be made.

```

root/
|--- core/
|     |---- constants/
|     |---- network/
|     |---- theme/
|     |---- utils/
|
|--- data/
|     |---- local/
|     |---- repositories/
|
|
|
|--- features/
        |
        |---- dashboard/
        |        |--- models/
        |        |--- viewmodels/
        |        |--- views/
        |               |--- components/
        |
        |---- calendar/
        |        |--- models/
        |        |--- viewmodels/
        |        |--- views/
        |               |--- components/
...

```
