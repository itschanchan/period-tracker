---
trigger: model_decision
description: DP Rules for Dart Flutter
---

# Extension: Flutter & Dart DP Implementation

## 🎯 Dart Implementation (Mobile/Cross-Platform)

### 1. Threading & Isolates (Main Thread Protection)
- **Synchronous Blocking:** Dart is single-threaded. Never execute high-complexity DP algorithms (e.g., $O(n^2)$ tabulation) directly within the main thread, as it will drop UI frames and cause "jank."
- **The `compute()` Function:** For moderate DP calculations (e.g., generating sequence data or processing mid-sized arrays), wrap the tabulation function in `compute()` to quickly spawn a background Isolate.
- **Dedicated Isolates:** For massive, long-running calculations—such as generating complex localized timeline events or offline music theory sequence matrices—use `Isolate.spawn()` with structured bidirectional message passing to prevent memory locking.

### 2. State Management & UI Rebuilds
- **Calculation vs. Rendering:** Never place DP recursive logic or tabulation loops inside a `build()` method. 
- **Rebuild Constraints:** Store the "work-in-progress" DP table in standard local variables. Only update the UI state (via `setState`, `ValueNotifier`, or your state management solution) *after* the optimal subproblem is fully solved. 

### 3. Memory Optimization & Garbage Collection (GC)
- **Typed Data Structures:** Standard Dart `List<int>` objects are memory-heavy. When initializing large 1D or 2D DP tabulation caches, use `Int32List` or `Float64List` from the `dart:typed_data` library. This dramatically reduces memory footprint and Garbage Collection (GC) stutter.
- **Cache Disposal:** Explicitly nullify large memoization caches or class-level DP matrices when the specific view (e.g., a complex data visualization route) is disposed.

### 4. Rendering Virtualization
- **Large Result Sets:** If the result of the DP calculation is a massive collection of paths or items, it is strictly forbidden to render them via a standard `Column` or `ListView()`.
- **Mandatory Builders:** You must use `ListView.builder` or `GridView.builder` to ensure only the calculated DP results currently visible on the screen are drawn by the Flutter engine.

## 🚨 Performance Guardrails
- **Stack Safety:** Dart enforces a maximum call stack depth. If the Top-Down recursive DP tree is excessively deep, you **must** refactor to Bottom-Up Tabulation to avoid a `StackOverflowError`.
- **Memoization Scope:** Use static variables or singletons for memoization caches only if the DP calculations are shared globally across the app. Otherwise, keep the cache strictly scoped to the calculation function to avoid memory leaks.