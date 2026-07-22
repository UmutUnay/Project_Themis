# Remote Plugin for Project Themis

## How to set up?

### Build from scratch
First cheeck the README filee at the project root to set up your build.conf files accordingly.

For the remote plugin, you need to run (at the project root)
```sh
cmake -S . -B build-remote_access_tool_plugin -D_TARGET_NAME=remote_access_tool_plugin
cmake --build build-remote_access_tool_plugin
```
and then, 
```sh
cmake -S plugins/remote_access_tool_plugin/client_agent -B build-client-agent
cmake --build build-client-agent
```
for the client agent of the plugin.

### Setting the Metadata
At "/etc/themis/plugins/", you should have 
- bin_name.csv,
- brief.json and
- service_details.json.

Add the line 
```
remote_access_tool,Remote_Access_Tool_Plugin_x86_v0.1.4
```
to bin_name.csv.

Add the block
```
  {
    "pluginId": "remote_access_tool",
    "pluginVersion": "0.1.4",
    "title": "Remote Plugin",
    "subtitle": "Remote Plugin"
  }
```
to brief.json.

Add the line 
```
"remote_access_tool": "remote_access_tool"
```
to service_details.json.

After those modifications, 
```sh
sudo cd /etc/themis/plugins/
sudo mkdir remote_access_tool
sudo cd remote_access_tool
```
Copy the contents of 
```
/Project_Themis/plugins/remote_access_tool_plugin/meta/
```
and
```
/Project_Themis/bin/Remote_Access_Tool_Plugin_x86_v0.1.4
/Project_Themis/build-client-agent/client_agent
```
to
```
/etc/themis/plugins/remote_access_tool
```
and check/edit the clients.json file as needed. Make sure that the SSH keys of the clients are already configured.

### At last
Run the Project Themis Server process as usual. 

## For any requests/bug reports etc.
## Contact me at yigitalpalakoc@gmail.com

