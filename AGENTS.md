# Repository Guidelines

## Project Structure & Module Organization
The Flutter client lives in lib/. lib/main.dart bootstraps Riverpod scopes and should stay lean-push business logic into lib/src/. Feature code is grouped under lib/src/config/ (environment switches), lib/src/models/ (data classes prefixed m_), lib/src/providers/ (Riverpod state and async controllers), lib/src/views/ (UI screens such as iew_movements.dart), and lib/src/db_helper.dart for Sqflite persistence. Assets live in ssets/img/ and ssets/sounds/; add new files to pubspec.yaml. Tests sit in 	est/, mirroring feature folders (widget_test.dart shows the base pattern).

## Build, Test, and Development Commands
- lutter pub get fetches dependencies; run after editing pubspec.yaml.
- lutter run --debug launches the app with hot reload for local work.
- lutter analyze enforces lints defined in nalysis_options.yaml.
- lutter test executes the widget and unit suites; pair with --coverage before releasing.
- lutter build apk --release produces the Play Store artifact; add --split-per-abi when needed.

## Coding Style & Naming Conventions
Use Dart’s default 2-space indentation and keep lines under 100 chars. File names stay snake_case.dart; classes and providers use UpperCamelCase, while variables use lowerCamelCase. Favor trailing commas in widget trees so dart format keeps diffs small. Follow the lint set from lutter_lints; suppress rules locally with // ignore only when justified.

## Testing Guidelines
Target new logic with widget tests in 	est/feature_name/ and name files *_test.dart. Mock async dependencies via Riverpod overrides to keep tests hermetic. Aim for meaningful coverage of database paths (db_helper.dart) and synchronization flows before merging. Run lutter test --coverage locally and verify generated reports before tagging builds.

## Commit & Pull Request Guidelines
You must never run any git-related commands, for example: `git status`, `git commit`, `git branch`, `git checkout`, etc. Never work on the dev branch and master branch. Never delete any branch. Never change branches.

## Security & Configuration Tips
Keep secrets out of source control; lib/src/config/main_config.dart should only hold non-sensitive defaults. Store device-specific values with shared_preferences or secure storage, and document any manual setup in the PR. When touching sync logic, confirm db_helper.dart migrations leave existing data intact and note rollback steps.
