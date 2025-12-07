# Network Monitor Pro
A portable Windows tool for ping, traceroute, and route stability monitoring.

## Overview
Network Monitor Pro is a Windows batch script that builds a PowerShell monitoring engine on the fly. It gives you an easy way to check for packet loss, route changes, latency spikes, unstable hops, and general network problems.

There is no installation. You just run the file and go. It works on all modern Windows systems and stays fully portable.

## Screenshots

### Path Monitor Running
![Path Monitor Running](https://github.com/user-attachments/assets/6258a4e5-0f00-4628-9496-7b18ebe58518)

### Path Monitor Summary
![Path Monitor Summary](https://github.com/user-attachments/assets/3d454f54-772b-4ff1-8af6-68bb7a95b8b7)

### Sample CSV Output
![CSV Sample](https://github.com/user-attachments/assets/9f48cc8d-cc4d-49be-b80c-9401aa9e137e)

### Stability Graph Light
<img width="1600" height="1000" alt="PathGraph_Final_8 8 8 8_light_20251207_110924" src="https://github.com/user-attachments/assets/244526a5-fc35-4861-b5ac-c4185f6365e7" />

### Stability Graph Dark
<img width="1600" height="1000" alt="PathGraph_Final_8 8 8 8_dark_20251207_110924" src="https://github.com/user-attachments/assets/5a09e79d-b5d1-4d27-9061-d6557c8ac487" />

## Features

### Ping Monitoring
- Live color coded ping results  
- Shows latency spikes and packet loss  
- Adjustable intervals  
- Full log export with timestamps  

### Traceroute Monitoring
- Repeated traceroutes  
- Shows hop changes and unstable routes  
- Saves all traceroutes for later review  

### Stability Graphing
- Creates PNG graphs from route data  
- Light and dark mode  
- Helps visualize hop stability  

### Duration System
- Warns that traceroute takes about 10 to 20 seconds to warm up  
- Helps avoid confusion for short or fast tests  

### Logging
- Automatic daily log folder  
- CSV output  
- Ping logs, traceroute logs, and graph files  

### Portable
- Runs from a single file  
- No installers  
- No admin rights  
- Uses PowerShell already built into Windows  

## Who This Helps

### Home Users
- Checking WiFi stability  
- Troubleshooting lag  
- Finding packet loss spikes  

### IT Support
- Quick diagnostics  
- Logging evidence for ISP issues  
- Tracking routing problems  

### Network Engineers
- Field tests  
- Route stability checks  
- Simple automated monitoring  

### Gamers and Streamers
- Finding unstable hops  
- Checking game server routes  
- Verifying if lag is local or provider based  

## How It Works
The batch script writes a PowerShell script into the same directory. That PowerShell file handles:

- Pings  
- Traceroutes  
- Graph generation  
- CSV export  
- Logging
- Stability analysis  

You only interact with the menu in the batch file.

## Feature Comparison

| Feature | Windows Ping | Windows Tracert | Network Monitor Pro |
|--------|--------------|------------------|----------------------|
| Continuous monitoring | Yes | No | Yes |
| Automatic logs | No | No | Yes |
| CSV export | No | No | Yes |
| Color output | No | No | Yes |
| Graphs | No | No | Yes |
| Repeated traceroute | No | No | Yes |
| Route stability tracking | No | No | Yes |
| Single portable file | Kind of | Yes | Yes |
| Menu driven | No | No | Yes |

## Installation
There is no installation. Download the file and run it.

## Usage
Choose an option from the main menu. Pick your target and duration. The script does everything else.

## Notes
Traceroute usually takes about 10 to 20 seconds to start. This is normal for Windows because of hop delays and timeouts.

