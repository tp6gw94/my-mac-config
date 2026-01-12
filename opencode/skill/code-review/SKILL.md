
---
name: Code Review
description: Process and implement code review feedback systematically. Use when user provides reviewer comments, PR feedback, code review notes, or asks to implement suggestions from reviews.
---

Review 程式的整體架構，如果是 React 應該避免 React 的 Antipattern：

- Deriving State
- Redundant State
- Using multiple `useEffect` hooks that cascade and trigger each other

