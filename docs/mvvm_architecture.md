## MVVM Architecture

This Flutter Period Tracker follows the MVVM Architecture: Model-View-ViewModel. It separates the widgets (frontend) from business data logic (backend) and data logic (database) of an application.

**Sample Folder Structure**:

- Inside the root project folder, the `core/` folder contains all of the shared global themes, constants, utilities, etc.
- All of the database setups and schemas are stored in the `data/` folder.
- The subfolders and contents inside the `features/` folder shall strictly follow the MVVM architecture for each feature to be made based on the sample folder structure diagram below:

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
        |        |--- viewModels/
        |        |--- views/
        |               |--- components/
        |
        |---- calendar/
        |        |--- models/
        |        |--- viewModels/
        |        |--- views/
        |               |--- components/
...

```

## Setup

The order of folder structuring in the project.

- `lib\`: Flutter's standard folder in the project.
  - `core\`
    - `constants\`: All of the constants to be used for business logic will be stored in this folder.
    - `network\`: Supabase configuration file will be stored here.
    - `routes\`: Serve as the main map of all Dart files.
    - `theme\`: Used to manage global themes.
    - `utils\`: App utilities will be stored here.
    - `core.dart`: The main core Dart file shall have in this folder.

  - `data\`: This should contain the data schemas and data management files.
    - `local\`: Data sources to be used in development locally.
    - `repositories`: Like a route, but maps out only the flow of data across the project.

  - `features\`: Serve as the frontend folder of the project.
    - `app-feature`: this is only a sample feature folder to demonstrate the subfolders inside it.
      - `models\`: Represents the data layer and core business rules.
      - `viewModels\`: Acts as the bridge between the View and the Model.
      - `views\`: Renders the user interface (UI) and captures user input (e.g., button clicks, text entries).
      - `app_feature.dart`

    - `main.dart`: The main file in the app.

---

## Rules:

1. In the `lib\` folder, this will contain `features\`, and `core\` subfolders only, with `main.dart` file inside.
2. It should strictly follow the MVVM architecture (Model-View-ViewModel).
3. There will be no other redundant files based on the mentioned subfolders and files. Remove the unnecessary files, if there is a logic on a redundant file, then move it to its corresponding correct file.
