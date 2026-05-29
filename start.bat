@echo off
cd /d "A:\艾宾浩斯曲线"
start "" "http://localhost:8765/index.html"
python -m http.server 8765
