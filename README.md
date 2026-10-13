# Godot × AI 遊戲開發

繁體中文 Godot 4.7.2 教學：18 章、Claude Code／Codex 協作，做出 2D「星星花園」與 3D「浮空島」兩款遊戲。

- 網站：https://phonchi.github.io/godot-ai-tutorial/
- 教材：`src/content/docs/lessons/`
- 可獨立執行的階段專案：`examples/2d/`、`examples/3d/`
- ZIP 與真正 Godot Web 匯出：`public/downloads/`、`public/play/`

## 本機預覽

需要 Node.js 22.12 以上，建議 Node.js 24。

```bash
npm ci
npm run dev
```

依終端機輸出的 URL 開啟 `/godot-ai-tutorial/`。正式靜態建置與預覽：

```bash
npm run check
npm run build
npm run preview
```

## 重建範例

```bash
python3 scripts/build_examples.py   # 由 scripts/templates/ 產生 9 個階段專案與 ZIP
GODOT_BIN=/absolute/path/to/godot python3 scripts/build_examples.py --test
```

Web 匯出需 Godot 4.7.2 與相符 Web templates。預設採專案本機工具目錄，可依 `scripts/export_games.py` 的 `GODOT_BIN` 覆寫引擎位置：

```bash
python3 scripts/fetch_web_templates.py
GODOT_BIN=/absolute/path/to/godot python3 scripts/export_games.py
npm run build
```

`fetch_web_templates.py` 透過 HTTP 位元組區段從官方 ZIP 只下載 Web 模板，不安裝全平台模板。

## 發布與授權

GitHub Actions 建置並發布到 GitHub Pages，base 路徑固定為 `/godot-ai-tutorial/`。無後端、無API金鑰，不需開啟付費功能。

原創程式：MIT。原創教材：CC BY 4.0。外部來源、Godot與字型授權見 `THIRD-PARTY-NOTICES.md`、`CONTENT-LICENSE` 和 `public/licenses/`。

驗證方法、執行環境與尚未驗證項目見 `verification/README.md`。
