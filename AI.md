# AI Usage Documentation

## Introduction

- **Project Name:** `waiting_room_app` (Workshop 2 & Workshop 3)
- **Project Purpose:** A cross-platform Flutter application designed to manage a waiting room queue (such as for a clinic, customer service desk, or administrative office). The app allows users to add client names to a queue, remove specific clients, call the next client in First-In-First-Out (FIFO) order, and view live client counts.
- **AI & Tools Used:** Antigravity AI / Gemini coding assistant, Flutter SDK & Dart, Provider package (`provider: ^6.1.2`), Git & GitHub.

---

## AI-Assisted Development Conversation

**Me:** I need to build a Flutter application for managing a waiting room queue where people can be added and removed. We are practicing Test-Driven Development (TDD) for Workshop 2. How should we structure the project to start with unit testing before touching the UI?

**AI:** Start with pure Dart domain logic decoupled from Flutter widgets. First, write a unit test (`test/waiting_room_manager_test.dart`) following the Arrange-Act-Assert pattern for adding and removing clients. Then implement a clean `WaitingRoomManager` class in `lib/waiting_room_manager.dart` that manages a private list of client strings with `addClient(String name)` and `removeClient(String name)` methods.

---

**Me:** I wrote the manager test, but should `clients` just be a public `List<String>`? What is the best practice so external widgets don't tamper with the list directly?

**AI:** To preserve encapsulation and avoid unintended side-effects, keep the backing list private (`final List<String> _clients = [];`) and expose it through a getter that returns an unmodifiable view:
```dart
List<String> get clients => List.unmodifiable(_clients);
```
This guarantees that clients can only be added or removed through the methods you define on the manager.

---

**Me:** For Workshop 3, we need to migrate our state management to the `provider` package instead of using local widget state. How do I transition `WaitingRoomManager` into a ChangeNotifier?

**AI:** Rename or refactor `WaitingRoomManager` into `QueueProvider` inside `lib/queue_provider.dart` and extend `ChangeNotifier`:
1. Import `package:flutter/foundation.dart`.
2. Add `notifyListeners();` at the end of `addClient` and `removeClient`.
3. In `pubspec.yaml`, add `provider: ^6.1.2`.
4. In `lib/main.dart`, wrap the root `WaitingRoomApp` with `ChangeNotifierProvider(create: (context) => QueueProvider(), child: const WaitingRoomApp())`.

---

**Me:** I also need to add a "Next Client" feature that serves clients in FIFO order (the first person in line gets called and removed). How should I add this to `QueueProvider` and display it in the AppBar?

**AI:** In `QueueProvider`, add a `nextClient()` method that removes the first element from `_clients`:
```dart
void nextClient() {
  if (_clients.isNotEmpty) {
    _clients.removeAt(0);
    notifyListeners();
  }
}
```
Checking `if (_clients.isNotEmpty)` prevents a `RangeError` if the button is pressed when the queue is empty. Then in `WaitingRoomScreen`, add an `IconButton` to `AppBar.actions` with `Icons.skip_next`, a tooltip `'Next Client'`, and key `const Key('nextClientButton')` that triggers `context.read<QueueProvider>().nextClient()`.

---

**Me:** When I wrote widget tests in `test/waiting_room_widget_test.dart`, running `flutter test` gave me this error:
`ProviderNotFoundException: Error: Could not find the correct Provider<QueueProvider> above this WaitingRoomApp Widget`.
Why does this happen if `ChangeNotifierProvider` is in `main.dart`?

**AI:** In `main.dart`, `ChangeNotifierProvider` wraps `WaitingRoomApp` inside `runApp()`. However, in your widget tests, calling `tester.pumpWidget(const WaitingRoomApp())` mounts `WaitingRoomApp` directly without the provider above it. To fix this cleanly, define a test helper function in your test file:
```dart
Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}
```
Now each test case can simply call `await pumpApp(tester);`.

---

**Me:** In `lib/main.dart`, when should I use `context.watch<QueueProvider>()` versus `context.read<QueueProvider>()`? I want to make sure I don't trigger unnecessary widget rebuilds.

**AI:** The rule of thumb in `provider` is:
- Use `context.watch<QueueProvider>()` in widget `build()` methods where the UI needs to react to state changes (such as displaying `queueProvider.clients.length` or the client cards in `ListView.builder`).
- Use `context.read<QueueProvider>()` inside event callbacks (such as `onPressed` for the Add, Delete, and Next Client buttons). `context.read` accesses the provider without subscribing the widget to rebuilds when state changes.

---

**Me:** I noticed that clicking "Add" with an empty text box creates an empty card. Also, what tests should I write for `nextClient()`?

**AI:** 1. In `_AddClientFormState._submit()`, add a check:
```dart
void _submit() {
  if (controller.text.isNotEmpty) {
    context.read<QueueProvider>().addClient(controller.text);
    controller.clear();
  }
}
```
2. For testing `nextClient()`, add unit tests verifying:
   - Calling `nextClient()` removes the first client from the list (FIFO).
   - Calling `nextClient()` on an empty list does not throw (`expect(() => provider.nextClient(), returnsNormally);`) and leaves the list empty.
3. In `waiting_room_widget_test.dart`, test that tapping `nextClientButton` removes the first client and updates the remaining queue count, and that tapping Add with an empty TextField leaves the queue count at 0.

---

**Me:** How can I unit test that `QueueProvider` actually calls `notifyListeners()` when modifying state?

**AI:** You can register a listener on the provider instance in your unit test:
```dart
final provider = QueueProvider();
int notificationCount = 0;
provider.addListener(() {
  notificationCount++;
});

provider.addClient('Client 1');
expect(notificationCount, 1);

provider.nextClient();
expect(notificationCount, 2);
```
This directly asserts that every state mutation triggers a UI notification.

---

## What I Learned / My Own Contribution

- **Encapsulation & Defensive State Design:** I made sure that the queue state cannot be modified from outside `QueueProvider` by exposing `List.unmodifiable(_clients)`. This prevented bugs where widgets might directly mutate the list without triggering `notifyListeners()`.
- **Mastering Provider Mechanics (`watch` vs `read`):** I learned the fundamental difference between subscribing to reactive updates with `context.watch<QueueProvider>()` in the widget build tree and executing commands without subscription using `context.read<QueueProvider>()` in button handlers.
- **Handling Edge Cases & Boundary Conditions:** I identified and handled edge cases such as empty user input in the form and invoking `nextClient()` on an empty list, validating with `returnsNormally` so the app never throws unhandled runtime exceptions.
- **TDD & Test Harness Architecture:** Rather than repeatedly configuring `ChangeNotifierProvider` in every widget test, I architected the `pumpApp` helper function to keep our test suite DRY, readable, and easy to maintain.
