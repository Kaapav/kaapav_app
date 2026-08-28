@echo off
echo Deploying kaapav-store to Cloudflare Pages...
wrangler pages deploy D:\Apps\kaapav_app\worker\kaapav-store --project-name=kaapav-store
pause
