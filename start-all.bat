@echo off
echo Starting 空予风博客...
start "Blog" cmd /c "cd /d %~dp0 && pnpm dev"
start "CMS" cmd /c "cd /d %~dp0 && pnpm cms"
echo Blog: http://127.0.0.1:4321
echo CMS:  http://localhost:3456
