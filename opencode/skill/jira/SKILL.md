---
name: jira
description: 透過 jira 開單安排專案
tools: mcp-atlassian
---

相關的操作會使用到 mcp-atlassian。

## 開單規範

- 前端的單 Team 應該掛上 SMAX-FE (可以參考其它的前端單子，只要搜尋 title 是 `[FE]` 開頭的)
- 前端的任務(task)單 title 應該加上 `[FE][Feature Name] xxxx` e.g.: `[FE][購物車] 將商品加入購物車`
- Test的任務單 title 應該是 `[TEST][Feature Name] xxx` e.g.: `[TEST][購物車] 商品加入購物車`
- 如果開單時，未提供 Epic，詢問 User 是否確認不掛上 Epic，若 User 有提供則記得要掛上
- 單內的 Description 應該符合 Jira 的格式，避免使用 Markdown

## 建立連結規範 (Issue Linking Rules)

當需要建立 **Task 實作 Story** 的連結關係時 (Task implements Story)，請務必遵守以下參數配置方向，以避免連結語意顛倒：
1.  **Link Type**: 優先使用 `Polaris work item link` (若無則使用 `Implements`)。
    *   *Outward Description*: `implements` (主動)
    *   *Inward Description*: `is implemented by` (被動)
2.  **參數方向 (Direction)**:
    *   `inward_issue_key`: 填入 **Task Key** (實作端，例如 TICK-851)。這是連結的「發起者/主詞」。
    *   `outward_issue_key`: 填入 **Story Key** (需求端，例如 TICK-798)。這是連結的「目標/受詞」。
    > **記憶口訣**: `[Task] implements [Story]` -> `[Inward] implements [Outward]`
3.  **預期結果**:
    *   在 **Task** 頁面會看到: `implements TICK-798`
    *   在 **Story** 頁面會看到: `is implemented by TICK-851`

## 必填欄位規範 (Mandatory Fields)
1.  **Team 欄位 (Frontend)**:
    *   當建立前端任務（Summary 以 `[FE]` 開頭）時，必須設定 **Team** 欄位。
    *   **Field ID**: `customfield_10001`
    *   **Value**: `'SMAX-FE'`
    *   **SMAX-FE UUID**: `0ee9124b-11d8-4ae1-bb4d-7eed39a57962`
    *   **操作注意**: 使用 `update_issue` 時**必須**使用上述 UUID，不可使用名稱 "SMAX-FE" (會報錯)。建立時則兩者皆可。
    *   **Value**: `'0ee9124b-11d8-4ae1-bb4d-7eed39a57962'` (推薦) 或 `'SMAX-FE'` (僅限建立時)
    *   **操作方式**: 請在 `create_issue` 或 `batch_create_issues` 的 `additional_fields` 參數中帶入。
    > **Example Payload**:
    >     > {
    >   "project_key": "SMAXI",
    >   "summary": "[FE] Task Name",
    >   "additional_fields": {
    >     "customfield_10001": "SMAX-FE"
    >   }
    > }
    >
