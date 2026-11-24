# PrivatePolicy · 应用隐私条款托管站

四款 App 的隐私政策与用户协议，通过 GitHub Pages 对外发布，用来填 Google Play / App Store 后台的「隐私政策网址」。

> 本仓库只做**集成与托管**。条款正文由各个 App 项目自己生成，这里不改写内容，只按统一路径放好。

线上地址（部署后）：

| App | 包名 | 商店用隐私政策网址 |
|---|---|---|
| Morse Craft | `com.zizworks.morsecraft` | https://zig-zag-wag.github.io/PrivatePolicy/morse-craft/privacy.html |
| ID Photo Maker | `com.zizworks.photosizeeditor` | https://zig-zag-wag.github.io/PrivatePolicy/id-photo-maker/privacy.html |
| MD Reader | `com.zizworks.mdreader` | https://zig-zag-wag.github.io/PrivatePolicy/md-reader/privacy.html |
| Any Convert | `com.zizworks.anyconvert` | https://zig-zag-wag.github.io/PrivatePolicy/any-convert/privacy.html |

首页（人看的入口）：https://zig-zag-wag.github.io/PrivatePolicy/

站点已上线（2026-11-25）：仓库 [Zig-Zag-Wag/PrivatePolicy](https://github.com/Zig-Zag-Wag/PrivatePolicy)，Pages 来源 `main` / `/ (root)`，HTTPS 已强制。以后同步完条款，`git push` 一分钟后线上就更新。

## 目录结构

```
PrivatePolicy/
├─ index.html                  首页：四款 App 的入口（中英切换）
├─ 404.html                    自包含样式，路径写死 /PrivatePolicy/ 前缀
├─ assets/site.css|site.js     首页与索引页的样式/中英切换（条款正文页不引用）
├─ morse-craft/                 条款文件 + index.html（语言索引）
├─ id-photo-maker/
├─ md-reader/                   保留原文件名 privacy.en.html 等，多语言页里的 hreflang 才不会断
├─ any-convert/
└─ scripts/
   ├─ sync-from-projects.ps1    从各 App 项目同步条款文件
   └─ check-links.js            发布前检查站内链接是否都指向真实文件
```

每个 App 目录里的 `privacy*.html` / `terms*.html` 都是从项目里**原样复制**的，唯一改动是有几个文件按站点规则改了名（见同步脚本里的 `Files` 映射）。

## 同步条款

在各 App 项目里改完条款、重新生成 HTML 之后：

```powershell
cd D:\Projects\PrivatePolicy
pwsh -File scripts\sync-from-projects.ps1
node scripts\check-links.js
git status          # 确认哪些条款更新了
git add -A
git commit -m "sync legal docs from app projects"
git push
```

脚本做的事：

1. 按 `$apps` 清单找到 `<项目>\flutter_project\docs\` 下的 `privacy*` / `terms*` 文件；
2. 显式映射的文件改名（例如 Morse Craft 的 `privacy_en.html` → `privacy.html`）；
3. 其余按原文件名复制（MD Reader 的 30 个语言文件）；
4. 检查每个复制结果是 HTML，最后打印文件清单。

源文件缺失时脚本会直接报错停下，不会留下半套文件。

同步完跑一下链接检查（首页、404、各 App 索引页的相对链接必须都存在）：

```powershell
node scripts\check-links.js
```

正常输出是 `pages: 6, links: 81, missing: 0`，然后可以提交推送。

## 新增一个 App

1. 在 App 项目的 `flutter_project/docs/` 生成 `privacy*.html`、`terms*.html`；
2. 在 `scripts/sync-from-projects.ps1` 的 `$apps` 里加一项（`Slug` / `Source` / `Files` 或 `Globs`）；
3. 跑一次同步脚本；
4. 新建 `<slug>/index.html`（复制现有某个 App 的索引页，改标题、链接、包名）；
5. 在根 `index.html` 加一张卡片，在 README 的表里加一行。

## 部署（GitHub Pages）

当前状态：已开启，`main` 分支根目录直接发布，没有构建步骤；`.nojekyll` 关掉 Jekyll 处理，`.gitattributes` 保证 HTML 以 LF 存储。

如果需要重新配置（换仓库、换分支、关掉再开）：

1. 仓库 **Settings → Pages**；
2. Source 选 **Deploy from a branch**，Branch 选 **main**，目录 **/ (root)**，保存；
3. 等 1 分钟左右，打开 https://zig-zag-wag.github.io/PrivatePolicy/ 确认首页能开，再逐个点四个 App 的隐私政策链接。

组织层面的坑：Zig-Zag-Wag 的 **Settings → Member privileges → Pages creation** 原来只勾了 Private，导致仓库里 Pages 显示「disabled」；已勾上 **Public** 才能发布公开站点。换组织或新建组织时记得检查这一项。

## 维护备注

- 条款正文里如果更新了「最后更新日期」，同步后顺手改一下首页页脚的 `Updated` 日期。
- 首页和各 App 索引页面是自己写的，条款文件是复制品；两边都用 `zizworks.eu.org@gmail.com`（2026-11-25 统一替换旧地址；Morse Craft 与 Any Convert 原来只写「见商店联系方式」，这次补上了具体地址）。
- MD Reader 与 Any Convert 的条款 HTML 来自项目内生成器（`tools/render_legal_html.dart`、`tool/build-legal-assets.ps1`）：改条款要改 `assets/legal/*.json` 再重新生成，不要直接改 HTML。
- 各项目里的 `report/log.md` 是历史记录，仍保留旧邮箱，属于历史条目，不必同步。
- 如果以后改仓库名或绑定自定义域名，`404.html` 里的 `/PrivatePolicy/` 前缀、README 里的四个商店网址都要一起改。
