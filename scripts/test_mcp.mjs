import {Client} from '../.tools/godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/client/index.js';
import {StdioClientTransport} from '../.tools/godot-mcp/node_modules/@modelcontextprotocol/sdk/dist/client/stdio.js';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
const root=resolve(fileURLToPath(new URL('..',import.meta.url)));
const transport=new StdioClientTransport({command:'node',args:[resolve(root,'.tools/godot-mcp/build/index.js')],env:{PATH:process.env.PATH,GODOT_PATH:resolve(root,'.tools/godot/Godot_v4.7.2-stable_linux.x86_64'),READ_ONLY_MODE:'true'},stderr:'pipe'});
const client=new Client({name:'godot-course-smoke',version:'1.0.0'},{capabilities:{}});
try{
 await client.connect(transport);
 const list=await client.listTools();console.log(JSON.stringify({tools:list.tools.map(t=>t.name)}));
 for(const [name,args] of [['get_godot_version',{}],['get_project_info',{projectPath:resolve(root,'examples/2d/05-final')}]] ){
 const result=await client.callTool({name,arguments:args});console.log(JSON.stringify({name,result}));if(result.isError)process.exitCode=1;
 }
 if(list.tools.some(t=>['create_scene','remove_node','edit_node','add_node'].includes(t.name)))throw new Error('read-only mode unexpectedly exposes scene-editing tools');
}finally{await client.close();}
