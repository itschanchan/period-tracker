---
trigger: always_on
---

# Core: Dynamic Programming Standards

## 🎯 Purpose
This document defines the mandatory standards, architectural constraints, and optimization workflow for all Dynamic Programming (DP) implementations inside the Antigravity agentic workflow system.

Every DP solution must prioritize:
- Predictable performance
- Memory efficiency
- Non-blocking execution
- Scalability for real-time applications
- Refactorability and maintainability

---

# 📊 Complexity Requirements

Every DP implementation must be evaluated against these Big O benchmarks.  
If the implementation exceeds these limits, it must be flagged for refactoring or moved to a background execution strategy.

---

## 1. Time Complexity Goals

### ✅ Primary Optimization Goal
Transform inefficient recursive solutions from:

- Exponential → $O(2^n)$
- Factorial → $O(n!)$

Into polynomial-time solutions:

- Polynomial → $O(n^k)$
- Linear → $O(n)$
- Log-linear → $O(n \log n)$

---

### ✅ Real-Time UI Constraints (React / Flutter)

For UI-bound workflows:

- Preferred complexity:
  - $O(n)$
  - $O(n \log n)$

- Avoid synchronous:
  - $O(n^2)$
  - $O(n^3)$
  - higher-order nested DP

Large DP computations must never block:
- React render cycles
- Flutter UI thread
- animation frames
- streaming responses
- interactive agent pipelines

---

### ⚠️ Bottleneck Threshold

If a DP algorithm reaches:

- $O(n^2)$ or higher time complexity

You **must** move execution into a non-blocking runtime:

#### Approved strategies
- Flutter Isolates
- Web Workers
- Worker Threads
- Async Task Queues
- Background Agents
- Deferred Computation Pipelines

---

# 🧠 Space Complexity & Memory Management

---

## 2. Standard Memoization Rules

Typical DP state storage:

- $O(n)$
- $O(n^2)$

Allowed storage methods:
- Arrays
- Maps
- Objects
- Hash Tables
- Sparse Tables

Memoization must:
- minimize recomputation
- reduce recursion branching
- cache deterministic states only

---

## 3. Space Optimization Protocol

If only previous states are required:

### REQUIRED Refactor
Convert:

- Full DP Table → $O(n^2)$

Into:

- Rolling Window / Sliding Window → $O(n)$

---

### Examples
Use rolling-state optimization for:
- Fibonacci
- Kadane variants
- path optimization
- stock trading DP
- sequence compression DP

Preferred patterns:
- Two-pointer DP
- Ring buffer states
- Sliding window memoization
- State compression

---

## 4. Garbage Collection & Cache Lifecycle

Memoization caches must not persist longer than necessary.

### REQUIRED
After the primary computation:
- clear memoization maps
- release temporary arrays
- dereference recursive state objects

This prevents:
- memory leaks
- retained closures
- long-session heap growth
- agent memory fragmentation

---

# 🛠️ The 4-Step DP Protocol

Every Dynamic Programming workflow must follow this protocol.

---

## Step 1 — Identify

Prove overlapping subproblems exist.

Requirements:
- identify repeated recursive calls
- define subproblem boundaries
- verify optimal substructure

Questions:
- Is the same computation repeated?
- Can results be cached?
- Does solving smaller states help solve larger states?

---

## Step 2 — Decompose

Define the DP state transition equation.

Canonical form:

\[
DP[i] = f(DP[i-1], DP[i-2], ...)
\]

Requirements:
- define state variables
- define transitions
- define base cases
- define termination conditions

---

## Step 3 — Memoize

Implement Top-Down caching.

Approved cache systems:
- Object
- Map
- Dictionary
- HashMap

Requirements:
- deterministic state keys
- constant-time lookup preferred
- avoid duplicate state generation

---

## Step 4 — Tabulate

Convert recursion into Bottom-Up iteration when necessary.

Required when:
- recursion depth becomes unsafe
- stack overflow risk exists
- large datasets are expected
- iterative execution improves cache locality

Benefits:
- lower call overhead
- predictable memory usage
- improved runtime stability

---

# 🚀 Agentic Workflow Enforcement Rules

Inside Antigravity workflows:

## Mandatory Validation
Every DP agent must validate:
- time complexity
- space complexity
- recursion depth
- cache growth
- thread safety

---

## Automatic Refactor Triggers

Trigger optimization/refactor if:
- recursion becomes exponential
- memoization grows unbounded
- synchronous execution blocks UI
- heap usage spikes
- state transitions duplicate work

---

## Runtime Execution Policy

### UI Thread
Allowed:
- $O(n)$
- lightweight memoization

### Background Thread
Required:
- $O(n^2)$ or higher
- graph DP
- matrix DP
- combinatorial DP
- large-state memoization

---

# ✅ Preferred DP Architecture

Priority order:

1. Bottom-Up Iterative DP
2. Sliding Window DP
3. State Compression DP
4. Top-Down Memoization
5. Recursive Brute Force (prototype only)

---

# ❌ Anti-Patterns

Avoid:
- uncached recursion
- global mutable DP state
- infinite memoization growth
- blocking synchronous DP in UI
- storing unnecessary full DP tables
- recomputing deterministic states

---

# ✅ Final Rule

A Dynamic Programming implementation is considered production-ready only if it:
- avoids exponential growth
- minimizes memory usage
- does not block interactive systems
- safely manages cache lifecycle
- follows the full 4-Step DP Protocol