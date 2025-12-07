# Network Monitor Pro v2
A portable Windows tool for ping, traceroute, and route stability monitoring.


## Overview
Network Monitor Pro is a Windows batch script that builds a PowerShell monitoring engine on the fly. It gives you an easy way to check for packet loss, route changes, latency spikes, unstable hops, and general network problems.

There is no installation. You just run the file and go. It works on all modern Windows systems and stays fully portable.

## Screenshots
### Path Monitor Running
![Path Monitor Running](https://github.com/user-attachments/assets/38529219-05ad-4677-99c0-83f7e1339c10)

### Path Monitor Summary
![Path Monitor Summary](https://github.com/user-attachments/assets/2f06e081-6d88-4693-a5aa-cbeffc63b25a)

### Sample CSV Output
![CSV Sample](https://github.com/user-attachments/assets/ff1ebee3-5814-4be5-a069-4b4b2193980b)

### Stability Graph Light
![PathGraph_Final_8 8 8 8_light_20251207_110924](https://github.com/user-attachments/assets/1ba03a1c-4d85-4c67-83c4-a33c9b3f874d)

### Stability Graph Dark
![PathGraph_Final_8 8 8 8_dark_20251207_110924](https://github.com/user-attachments/assets/f494c992-de1e-4fbd-8071-f8729f260e04)


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

