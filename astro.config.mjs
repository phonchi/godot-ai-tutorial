import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mdx from '@astrojs/mdx';
export default defineConfig({
 site: 'https://phonchi.github.io', base: '/godot-ai-tutorial',
 integrations: [starlight({
  title: 'Godot × AI', description: '從第一個節點到可玩的遊戲：Godot 與 AI agent 的繁體中文實作課程。',
  logo: {src: './public/godot-logo.svg', replacesTitle: false},
  defaultLocale: 'root', locales: {root: {label: '繁體中文', lang: 'zh-TW'}},
  customCss: ['./src/styles/course.css'],
  social: [{icon: 'github', label: 'GitHub', href: 'https://github.com/phonchi/godot-ai-tutorial'}],
  sidebar: [
   {label: '開始學習', link: '/'},
   {label: '課程章節', items: [{autogenerate: {directory: 'lessons'}}]},
   {label: 'AI 提示詞工具箱', link: '/prompts/'},
   {label: '下載範例專案', link: '/downloads/'},
   {label: '遊戲試玩', link: '/play/'},
   {label: '參考資料與授權', link: '/resources/'}
  ],
  components: {Footer: './src/components/CourseFooter.astro', PageTitle: './src/components/CourseTitle.astro'},
  tableOfContents: {minHeadingLevel: 2, maxHeadingLevel: 3},
 }), mdx()],
});
