# blocitory

`blocitory` is a small Flutter helper package built around `flutter_bloc` for apps that repeatedly need:

- resource cubits for query and mutation flows
- paged list state and widgets
- lightweight loading, retry, and feedback widgets

## Included pieces

- `ResourceCubit` and `ResourceListCubit`
- resource query and mutation helper widgets
- paged cubit and paged list helpers
- reusable loading, retry, snackbar, and button widgets

## Installation

```yaml
dependencies:
  blocitory:
    git:
      url: https://github.com/your-org/blocitory.git
      ref: main
```

## Usage

```dart
import 'package:blocitory/blocitory.dart';
```

This fork is intended to keep existing projects working on modern Flutter versions. Before publishing it under your own GitHub account or organization, update the dependency example above and any package metadata URLs to match the final repository.
