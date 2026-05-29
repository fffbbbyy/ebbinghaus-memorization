# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概览

单文件交互式艾宾浩斯遗忘曲线背诵计划表（`index.html`，约 2000+ 行）。无框架、无构建工具 — 直接用浏览器打开即可。

## 项目文件

| 文件 | 用途 |
|------|------|
| `index.html` | 全部代码（HTML + CSS + JS） |
| `shortcut.vbs` | Windows 脚本，在桌面创建 `index.html` 的快捷方式 |
| `CLAUDE.md` | 本文件 |
| `skills-lock.json` | skills CLI 自动生成，记录曾安装过的 skill（可能过时，勿手动编辑） |
| `.claude/settings.local.json` | 项目级 Claude Code 权限白名单 |

## 打开方式

```
start "" "A:\艾宾浩斯曲线\index.html"
```

或运行 `shortcut.vbs` 在桌面创建快捷方式。

调试时可启动本地 HTTP 服务器（避免 `file://` 协议缓存问题）：
```
cd "A:\艾宾浩斯曲线" && python -m http.server 8765
start "" "http://localhost:8765/index.html"
```

## 架构

所有代码集中在 `index.html`：CSS 在 `<style>` 标签中，JS 在文件末尾的单个 `<script>` 块中。

### 数据模型

持久化到 localStorage，两个 key：

- `ebbinghaus_schedule_v2`（主数据）:
```js
{ version: 2, config: { startDate, itemsPerDay, totalDays }, completions: { "{id}_{interval}": true }, contents: { id: "自定义内容" } }
```
- `ebbinghaus_notify`（通知设置）:
```js
{ enabled: false, time: "09:00", lastNotified: "2026-05-28" }
```

旧版 v1 数据（`ebbinghaus_schedule`）会在加载时自动迁移。

### 核心算法

复习周期 `[1, 2, 4, 7, 15, 30]` 天：
- 第 `d` 天新学内容：`[d*N+1, (d+1)*N]`，其中 N = 每日项数
- 第 `d` 天复习周期 I 的内容：若 `d-I >= 0`，则复习第 `(d-I)` 天的所有项，否则为空

### 关键函数

**计划与渲染：**
- `generateSchedule(startDate, itemsPerDay, totalDays)` → 返回每天的对象数组
- `renderTable(schedule, completions, contents)` → 构建 `<tbody>` 行，含跨月分隔行和今日高亮
- `renderContentPanel(schedule, contents)` → 按天分组的文本输入区，支持折叠
- `renderTodayOverview(schedule, completions, contents)` → 今日焦点概览卡片（新学内容 + 待复习）

**持久化：**
- `loadState()` / `saveState(config, completions, contents)` → v2 格式，自动兼容 v1
- `loadNotifyState()` / `saveNotifyState(state)` → 通知设置

**交互：**
- `onGenerate()` → 读取表单配置生成计划，保留已有完成标记
- `onCheckbox(e)` → 事件委托处理复选框（同时用于表格和今日概览），双向同步 DOM，触发 streak 更新和印章判定
- `onToggle()` → 折叠/展开全部复习列
- `onToggleFocus()` → 切换今日焦点模式，只显示今天行 + 概览卡片。激活时自动将今日概览卡片滚动到视口顶部（`scrollIntoView({ block: 'start' })`）
- `computeStreak(schedule, completions)` → 从最近一天往前数连续完成天数（当天未完成则从前一天算起）
- `isTodayComplete(schedule, completions)` → 判断当天（或最近过往日）是否全部复习完成
- `fireStamp()` → 触发印章动画 + 烟花 + Web Audio API 盖章音效
- `launchFireworks()` → 在页面两侧生成彩色粒子爆发动画，每侧 3 组约 60 个粒子

### UI 分区

配置面板（日期/项数/天数 + 生成按钮）→ 第二行按钮栏（全部折叠、今日焦点、清空标记、每日提醒）→ 今日概览卡片（焦点模式）→ 统计栏（连续打卡徽章 + 复习统计 + 进度条）→ 主表格（9列）→ 内容编辑面板 → 图例

### 新增功能（v3）

1. **连续打卡** — 统计栏左侧朱红色徽章，追踪连续完成天数。仅计算有复习任务的日期，0 天时半透明显示。连续天数增加时触发脉冲动画。
2. **今日焦点视图** — 按钮切换，开启后表格仅显示今天行。上方「Scholar's Daily Folio」概览卡片：新学内容 + 待复习项（圈形印章复选框 + 内容文字 + 颜色编码周期标签），勾选后整行变灰+删除线。卡片入场时逐项错峰动画（staggered entrance，50ms 间隔）。复选框与主表格双向同步。当天不在计划内时给出提示。
3. **印章庆祝动画** — 当天最后一个复习项勾选时触发。全屏叠加红色"背完了"印章（马山正书法字体），配合盖章动画（缩放回弹旋转）+ Web Audio API 低音音效 + 页面两侧彩色烟花爆发。
4. **浏览器通知提醒** — 点击铃铛按钮授权通知权限后，每 45 秒检查一次是否到达提醒时间（默认 9:00），弹出浏览器通知显示今日剩余复习项数。同日不重复提醒。

### 事件处理

- 复选框变化：`#tableWrap` 和 `#todayOverview` 上的 `change` 事件委托 → `onCheckbox`
- 按钮：直接 `addEventListener` 绑定
- 内容编辑实时保存：`#contentPanelBody` 上的 `input` 事件 + 400ms 防抖

### 设计风格

"复古科学笔记"美学 — CSS 渐变模拟羊皮纸背景，Google Fonts（Playfair Display、Crimson Text、JetBrains Mono、Ma Shan Zheng），CSS 自定义属性管理色彩体系（羊皮纸色、墨水色、黄铜色、朱红色、瓶绿色），复习列用水彩晕染底色，复选框用印章风格，进度条用温度计风格。

**无障碍优化（2026-05-29）：**
- `prefers-reduced-motion` 媒体查询：关闭所有动画和过渡
- `:focus-visible` 全局焦点样式：按钮/输入/复选框统一 `reagent-blue` 2px outline
- 触控目标最小 44px：表格复选框 24→44px、火漆印章复选框 22→44px
- 最小字号 10-11px：标签/表头/图例/徽章从 9-10px 提升

### CSS 分区索引（按行号近似，截至 2026-05-29）

| 行号范围 | 内容 |
|----------|------|
| ~10-75 | CSS 变量、body 基础、纸张纹理背景 |
| ~76-133 | 布局 (.app)、标题 (.header)、装饰线 |
| ~134-152 | 卡片 (.card) 通用样式 |
| ~153-226 | 控制面板 (.controls)、表单、按钮 |
| ~227-298 | 统计栏 (.stats)、streak 徽章、温度计进度条 |
| ~300-460 | 今日焦点视图 (.today-overview)、错峰入场动画、印章复选框 |
| ~464-500 | 通知组件 (.notify-group)、焦点模式表格行隐藏 |
| ~487-640 | 内容编辑面板 (.content-panel)、表格样式、行高亮、复选框 tooltip |
| ~672-748 | 印章庆祝 overlay (.stamp-overlay)、烟花 (.firework-side)、keyframes |
| ~751-870 | 打印样式 (@media print)、响应式 (@media 768px) |
| ~1177-1212 | 页面加载墨迹效果 (inkBleed)、暗角阴影 |
| ~1242-1252 | 无障碍：focus-visible 焦点样式 |
| ~1254-1265 | 无障碍：prefers-reduced-motion 降级 |

### 今日焦点动画系统

- 列表项错峰入场：`@keyframes todayItemEnter`（translateY(10px) → 0 + opacity 0 → 1），每项 `animation-delay` 递增 50ms
- 复选框勾选回弹：`@keyframes stampCheck`（scale 1 → 0.85 → 1，0.3s）
- 复习周期标签颜色编码：`.today-interval-tag.i1` / `.i2` / `.i4` / `.i7` / `.i15` / `.i30`，分别对应 6 个复习周期，颜色与水彩列底色一致
- 复选框勾选时进度条**不重新渲染整个卡片**（避免打断动画），而是直接更新 `#todayProgressText` 和 `#todayBar` 的 DOM

## 常见陷阱

### 内联 `style="display:none"` 会阻止 CSS 类显隐切换

**错误示例：**

```html
<div id="foo" style="display:none;">
```
```css
.foo.open { display: block; }
```
```js
document.getElementById('foo').classList.add('open'); // 无效！
```

**原因：** 内联样式优先级 (1,0,0,0) 高于 class 选择器 (0,0,1,0)，CSS 类的 `display: block` 无法覆盖内联的 `display:none`。

**正确做法：**
- 方案 A：移除内联 `style`，用 CSS 规则隐藏：`.foo { display: none; }` `.foo.open { display: block; }`（同级优先级，后者靠顺序胜出）
- 方案 B：JS 直接操作：`element.style.display = 'block'`

**调试清单（当报告"改了但页面没变化"时依次排查）：**
1. 确认文件确实被写入 → `grep` 检查关键字符串
2. 确认 JS 无语法错误 → `node -e "const fs=require('fs');const m=fs.readFileSync('A:/艾宾浩斯曲线/index.html','utf8').match(/<script>([\\s\\S]*?)<\\/script>/);new Function(m[1]);"` 检查
3. 确认没有内联样式阻止 CSS 类生效 → 检查元素是否有 `style="display:none"`
4. 确认 JS 函数在运行时被正确调用 → 检查 `classList.add('open')` 是否被执行
5. 浏览器缓存 → 先硬刷新（Ctrl+Shift+R），不行就 `taskkill /f /im msedge.exe && taskkill /f /im chrome.exe` 后重新打开

**常用调试命令：**
```
# JS 语法检查
node -e "const fs=require('fs');const m=fs.readFileSync('A:/艾宾浩斯曲线/index.html','utf8').match(/<script>([\\s\\S]*?)<\\/script>/);new Function(m[1]);console.log('OK');"

# 检查页面行数
wc -l "A:/艾宾浩斯曲线/index.html"

# 搜索关键 CSS 类/函数
grep -n "function renderTodayOverview" "A:/艾宾浩斯曲线/index.html"

# 结束浏览器进程强制重新加载
taskkill /f /im msedge.exe; taskkill /f /im chrome.exe; start "" "A:/艾宾浩斯曲线/index.html"
```

## 语言风格

在每一次回答的最后一句话上加上"喵"，例如"好的"改成"好的喵"
