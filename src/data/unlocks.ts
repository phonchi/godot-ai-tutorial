// What each hands-on chapter adds to the games. Used by the homepage and the chapter title badge.
export interface Unlock {slug:string;chapter:string;name:string;detail:string;glyph:keyof typeof glyphs;}

// 24×24 geometric glyphs (stroke = currentColor).
export const glyphs = {
 dash:'<path d="M4 7l5 5-5 5M11 7l5 5-5 5M18 7v10"/>',
 star:'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"/>',
 chaser:'<circle cx="12" cy="12" r="5.5"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>',
 waves:'<path d="M5 19V13M12 19V8M19 19V4"/>',
 sparkle:'<path d="M12 3v5M12 16v5M3 12h5M16 12h5M7 7l2 2M15 15l2 2M7 17l2-2M15 9l2-2"/>',
 sun:'<circle cx="12" cy="13" r="4"/><path d="M3 20h18M12 4v2M5 7l1.5 1.5M19 7l-1.5 1.5"/>',
 jump:'<path d="M4 19c2-9 6-13 9-13s5 3 5 6"/><path d="M15.5 10.5L18 13l2.5-2.5"/><path d="M3 21h18"/>',
 gate:'<path d="M5 21V9a7 7 0 0114 0v12M9 21v-8h6v8M3 21h18"/>',
 flag:'<path d="M6 21V4M6 4h11l-2.5 4L17 12H6"/>',
};

export const unlocks:Unlock[] = [
 {slug:'07-2d-movement',chapter:'07',name:'加速移動與衝刺',detail:'move_toward、dash 冷卻',glyph:'dash'},
 {slug:'08-2d-collection',chapter:'08',name:'星星、Tween 與粒子',detail:'Area2D 訊號、一次性爆散',glyph:'star'},
 {slug:'09-2d-hazards',chapter:'09',name:'追蹤敵人與生命',detail:'direction_to、無敵時間',glyph:'chaser'},
 {slug:'10-ui-state',chapter:'10',name:'波次與狀態機',detail:'enum State、繪製 HUD',glyph:'waves'},
 {slug:'11-audio-polish',chapter:'11',name:'Shader、音效與存檔',detail:'畫面震動、最佳紀錄',glyph:'sparkle'},
 {slug:'14-3d-world',chapter:'14',name:'天空、霧與浮島',detail:'Environment、光影構圖',glyph:'sun'},
 {slug:'15-3d-controller',chapter:'15',name:'鏡頭相對移動與跳躍',detail:'coyote time、平滑鏡頭',glyph:'jump'},
 {slug:'16-3d-collection',chapter:'16',name:'移動平台與拱門',detail:'AnimatableBody3D、Tween',glyph:'gate'},
 {slug:'17-3d-export',chapter:'17',name:'巡邏敵人與重生點',detail:'Path3D、PathFollow3D',glyph:'flag'},
];

export const glyphSvg=(name:keyof typeof glyphs)=>`<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${glyphs[name]}</svg>`;
