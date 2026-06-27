# 空予风博客 (Kong Yu Feng Blog)

> 哔哩哔哩虚拟主播空予风的个人博客 —— 基于 Astro 的静态站点

[![Astro](https://img.shields.io/badge/Astro-5.18-FF5D01?logo=astro)](https://astro.build)
[![Node.js](https://img.shields.io/badge/Node.js-≥22-339933?logo=nodedotjs)](https://nodejs.org)
[![pnpm](https://img.shields.io/badge/pnpm-≥9-F69220?logo=pnpm)](https://pnpm.io)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

---

## 📐 项目架构

```
kyfboke/
├── src/
│   ├── components/        # 可复用组件
│   │   ├── Header.astro       # 顶部导航栏（玻璃拟态效果）
│   │   ├── Hero.astro         # 首页 Hero 区（名字/头像/云图/B站入口）
│   │   ├── Splash.astro       # 开屏动画（打字机 + 水波纹消散）
│   │   ├── SiteStats.astro    # 站点统计小组件
│   │   ├── GalleryGrid.astro  # CSS Columns 瀑布流相册
│   │   ├── TagGraph.astro     # 标签思维节点云图
│   │   └── Footer.astro       # 页脚
│   ├── content/           # Astro 内容集合
│   │   └── blog/              # Markdown 博客文章
│   ├── data/              # JSON 数据源
│   │   ├── diary.json         # 直播日记
│   │   ├── timeline.json      # 时间线
│   │   ├── projects.json      # 作品
│   │   ├── friends.json       # 友链
│   │   └── site.json          # 站点配置（建站日期/访问计数）
│   ├── layouts/
│   │   └── BaseLayout.astro   # 根布局
│   ├── pages/             # 路由页面（文件即路由）
│   │   ├── index.astro        # 首页
│   │   ├── blog/              # 文章列表 + 文章详情
│   │   ├── gallery/           # 相册页
│   │   ├── diary.astro        # 直播日记
│   │   ├── timeline.astro     # 时间线
│   │   ├── projects.astro     # 作品
│   │   └── friends.astro      # 友链
│   ├── styles/
│   │   └── global.css         # 全局样式 + CSS 变量
│   └── utils/
│       └── gallery.ts         # 图片扫描 + 尺寸解析
├── public/
│   ├── gallery/           # 图库图片
│   └── avatar.jpg         # 头像
├── astro.config.mjs       # Astro 配置
├── package.json
└── tsconfig.json
```

### 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Astro 5.18（静态站点生成） |
| 样式 | CSS 变量 + 组件作用域样式 |
| 内容 | Markdown + YAML frontmatter（`astro:content`） |
| 包管理 | pnpm |
| 字体 | Zen Maru Gothic + Noto Serif SC + JetBrains Mono（Google Fonts） |

### 设计系统

```
调色板: B站蓝单色系
--ink-deep:   #0F1A2E   主背景
--ink-surface:#15243D   卡片表面
--accent:     #00AEEC   B站主蓝
--paper:      #DDE3EB   主文字
--ease-spring:cubic-bezier(0.34,1.56,0.64,1)  弹性缓动
```

---

## 🚀 本地部署

### 前置要求

- **Node.js** ≥ 22
- **pnpm** ≥ 9（`npm i -g pnpm`）

### Windows

```powershell
# 1. 克隆项目
git clone https://github.com/amu263/kyfboke.git
cd kyfboke

# 2. 安装依赖
pnpm install

# 3. 开发模式（热更新，http://127.0.0.1:4321）
pnpm dev

# 4. 构建生产版本
pnpm build
# 输出在 dist/ 目录

# 5. 预览生产版本（http://127.0.0.1:4322）
pnpm preview
```

### Linux / macOS

```bash
# 1. 克隆项目
git clone https://github.com/amu263/kyfboke.git
cd kyfboke

# 2. 安装 pnpm（如未安装）
npm install -g pnpm

# 3. 安装依赖
pnpm install

# 4. 开发模式
pnpm dev

# 5. 构建
pnpm build
```

---

## 🌐 GitHub 部署

### 方式一：GitHub Pages + Actions（推荐）

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [master]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with:
          version: 9
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: 'pnpm'
      - run: pnpm install
      - run: pnpm build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: dist

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - uses: actions/deploy-pages@v4
```

修改 `astro.config.mjs` 中的 `site` 为你的 GitHub Pages 地址：

```js
export default defineConfig({
  site: 'https://amu263.github.io/kyfboke',
  // ...
});
```

推送到 `master` 分支后自动部署。

### 方式二：手动构建 + 推送 dist

```bash
pnpm build
# 将 dist/ 内容推送到 gh-pages 分支
```

---

## 📦 dist 文件上传服务器部署

### 适用于 Nginx / Apache / Caddy 等

```bash
# 1. 本地构建
pnpm build

# 2. 上传 dist/ 目录到服务器
scp -r dist/* user@your-server:/var/www/kyfboke/

# 或使用 rsync
rsync -avz --delete dist/ user@your-server:/var/www/kyfboke/
```

### Nginx 配置示例

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/kyfboke;
    index index.html;

    # SPA 路由支持
    location / {
        try_files $uri $uri.html $uri/ =404;
    }

    # 静态资源缓存
    location /_astro/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    location /gallery/ {
        expires 30d;
    }

    # Gzip
    gzip on;
    gzip_types text/html text/css application/javascript image/svg+xml;
}
```

### Caddy 配置示例

```caddy
your-domain.com {
    root * /var/www/kyfboke
    file_server
    try_files {path} {path}.html {path}/
}
```

---

## 📝 内容管理

博客配套**图形化内容管理器**：https://github.com/amu263/kyfbokecms

```bash
git clone https://github.com/amu263/kyfbokecms.git
cd kyfbokecms
npm install
node server.js
# 打开 http://localhost:3456
```

功能：文章 CRUD、Markdown 编辑器、图库上传管理、日记/时间线/作品/友链数据编辑。

---

## 📁 添加内容

| 内容类型 | 操作 |
|----------|------|
| 博客文章 | 在 `src/content/blog/` 创建 `.md` 文件，或使用 CMS |
| 相册图片 | 放入 `public/gallery/`，支持 jpg/png/webp/gif/avif |
| 直播日记 | 编辑 `src/data/diary.json` 或使用 CMS |
| 时间线 | 编辑 `src/data/timeline.json` 或使用 CMS |
| 作品 | 编辑 `src/data/projects.json` 或使用 CMS |
| 友链 | 编辑 `src/data/friends.json` 或使用 CMS |

---

## 🎨 自定义

修改 `src/styles/global.css` 中的 CSS 变量：

```css
:root {
  --ink-deep: #0F1A2E;    /* 主背景色 */
  --accent:   #00AEEC;    /* 主题色 */
  --paper:    #DDE3EB;    /* 文字色 */
  /* ... */
}
```

---

## 📄 License

MIT
