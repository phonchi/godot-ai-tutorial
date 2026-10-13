"""Keep published checkpoint excerpts tied to executable example sources."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
entries={
'07-2d-movement':('2d','01-movement',[('player', 'apply_movement'), ('player', 'try_dash')]),
'08-2d-collection':('2d','02-collect',[('main', 'collect_item'), ('star', 'pop')]),
'09-2d-hazards':('2d','03-hazards',[('enemy', 'chase'), ('main', '_physics_process'), ('main', 'damage_player')]),
'10-ui-state':('2d','04-interface',[('main', 'start_wave'), ('main', 'finish_wave'), ('hud', 'draw_heart')]),
'11-audio-polish':('2d','05-final',[('main', 'build_background'), ('main', 'save_best_time'), ('player', 'update_trail')]),
'14-3d-world':('3d','01-world',[('main', 'build_environment'), ('main', 'make_island')]),
'15-3d-controller':('3d','02-controller',[('player', 'camera_relative_direction'), ('player', 'update_jump_timers'), ('main', 'update_camera')]),
'16-3d-collection':('3d','03-platforms',[('moving_platform', None), ('main', 'collect_item'), ('main', 'open_gate')]),
'17-3d-export':('3d','04-final',[('patrol_enemy', None), ('main', 'respawn_player'), ('main', 'activate_checkpoint')]),
}
for slug,(dimension,stage,snippets) in entries.items():
 p=root/'src/content/docs/lessons'/f'{slug}.mdx'
 s=p.read_text()
 if 'SourceExcerpt.astro' not in s:
  marker="import AgentTask from '../../../components/AgentTask.astro';"
  s=s.replace(marker,marker+"\nimport SourceExcerpt from '../../../components/SourceExcerpt.astro';")
  text='## 對照可下載的階段專案\n\n上面的操作讓你練習手動建立節點；下載版用程式建立同樣職責的物件，節點在執行後才出現在 Remote 場景樹。請以遊戲行為對照，並用以下原始碼認識另一種組合方式。\n\n'
  for file,method in snippets:
   text+=f'<SourceExcerpt dimension="{dimension}" stage="{stage}" file="{file}"'+(f' method="{method}"' if method else '')+' />\n\n'
  s=s.replace('## 官方參考',text+'## 官方參考')
 p.write_text(s)
print('Linked',len(entries),'lessons to actual checkpoint source')
