---
name: jira
description: 透過 jira 開單安排專案等
tools: jira 
---

相關的操作會使用到 mcp-atlassian。

- 前端的單 Team 應該掛上 SMAX-FE (可以參考其它的前端單子，只要搜尋 title 是 `[FE]` 開頭的)
- 前端的任務(task)單 title 應該加上 `[FE][Feature Name] xxxx` e.g.: `[FE][購物車] 將商品加入購物車`
- Test的任務單 title 應該是 `[TEST][Feature Name] xxx` e.g.: `[TEST][購物車] 商品加入購物車`
- Task (Inward) -> Story (Outward)
    這在 Jira 上會顯示為：
    *   Task 端: implements XXX-795
    *   Story 端: is implemented by XXX-833
