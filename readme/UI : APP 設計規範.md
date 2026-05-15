# 🎨 UI / APP 設計規範（統一風格系統）

本文件用於所有 Web / App UI 設計，確保跨平台風格一致。

---

# 1. 設計核心原則

- 統一風格（Single Design Language）
- 簡潔優先（Less is more）
- 功能優先於裝飾
- UI 必須一致可預測
- 所有元件可重用

---

# 2. 設計系統（Design System）

## 2.1 色彩規則

- Primary Color：主操作顏色（按鈕 / 重點）
- Secondary Color：輔助資訊
- Background：淺灰 / 白 / 深色模式支援
- Error：紅色（錯誤）
- Success：綠色（成功）
- Warning：橘色（警告）

👉 原則：
- 不可亂用顏色
- 同類功能必須用同色系

---

## 2.2 字體規則

- Title：粗體大字
- Subtitle：中等字重
- Body：標準內文
- Caption：輔助文字

👉 規則：
- 不可使用超過 3 種字重
- 所有平台字體視覺一致

---

## 2.3 間距系統（Spacing）

- 4 / 8 / 12 / 16 / 24 / 32
- 所有 UI 必須使用固定間距系統
- 不可隨意調 margin / padding

---

## 2.4 圓角規則（Border Radius）

- Small：4px（input）
- Medium：8px（button / card）
- Large：16px（modal / container）

👉 全系統統一使用

---

# 3. 元件設計（Component System）

## 3.1 基礎元件

- Button（主要 / 次要 / 危險）
- Input（文字 / 密碼 / 搜尋）
- Card（資訊容器）
- Modal（彈窗）
- List Item（列表）
- Avatar（頭像）

---

## 3.2 元件規則

- 所有元件必須可重用
- 不可每個頁面重寫 UI
- 元件不可包含 business logic
- UI = display only

---

## 3.3 Button 規範

- Primary（主要操作）
- Secondary（次要操作）
- Danger（刪除 / 危險操作）

👉 規則：
- 一頁最多一個 primary button
- 不可濫用顏色

---

# 4. 前端 / App 統一規則

## 4.1 UI 一致性

- Web 與 App 必須共用 design system
- 相同功能 UI 必須一致
- 不可各自亂設計

---

## 4.2 Layout 規則

- 上 → 下（垂直流）
- 左 → 右（輔助資訊）
- 重要資訊置頂
- 操作按鈕固定在底部或右下

---

## 4.3 UX 規則

- 所有操作必須有 feedback（loading / success / error）
- 禁止無反應操作
- 所有刪除操作必須確認

---

# 5. 狀態設計（State Design）

所有 UI 必須考慮三種狀態：

- Loading（載入中）
- Empty（沒有資料）
- Error（錯誤狀態）

👉 不可只做正常畫面

---

# 6. App 特別規則（Mobile）

- 拇指友善區域（bottom area）
- 按鈕不可太靠邊
- List 可滑動優先
- Modal 不可遮死 UI

---

# 7. Web 特別規則

- 支援 responsive（手機 / 平板 / 桌機）
- Grid layout 優先
- Sidebar + Content 分離
- 表格可簡化顯示

---

# 8. 設計禁止事項

- ❌ 不可每頁不同風格
- ❌ 不可亂用顏色
- ❌ 不可 UI 為了好看犧牲可用性
- ❌ 不可沒有 loading / error state
- ❌ 不可不考慮手機使用

---

# 9. AI 設計指令（Claude / Design AI）

當請 AI 設計 UI 時，必須使用：
