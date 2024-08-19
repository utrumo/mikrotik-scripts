# Mikrotik scripts for configuration with dual wan failover and load balancing

## 1. Update firmware

1. Download firmware from <https://mikrotik.com/product/RB2011UiAS-2HnD-IN#fndtn-downloads>

```
routeros-7.15.3-mipsbe.npk
wireless-7.15.3-mipsbe.npk
```

2. In winbox go files and drag end drop here all three files
3. System => Reboot
4. System => Router BOARD => Update to 7.15.3 => Reboot

## 2. Reset Configuration

No Default Configuration: Check => Reset Configuration

## 3. Add new user and remove default

1. System => Users => Add =><br>
   Name: _newMikrotikRouterAdmin_<br>
   Group: full<br>
   Password: _someStrongPassword_
2. Remove admin

```
/user add name=newMikrotikRouterAdmin password=someStrongPassword group=full
/user remove admin
```

## 4. Add comments to ports

Interfaces => Interface:<br>
ehter2 => ISP1<br>
ether3 => ISP2

```
/interface ethernet
set | find default-name=ether2 | comment=ISP1
set | find default-name=ether3 | comment=ISP2
```

## 5. Add lan bridge

1. Bridgge => Add:<br>
   name: br-lan
2. => Ports tab => Add to bridge 1: eth1, eth4, eth5, eth6, eth7, eth8, eth9, eth10, spf1, wlan1

```
/interface bridge port
add bridge=br-lan interface=ether1
add bridge=br-lan interface=ether4
add bridge=br-lan interface=ether5
add bridge=br-lan interface=ether6
add bridge=br-lan interface=ether7
add bridge=br-lan interface=ether8
add bridge=br-lan interface=ether9
add bridge=br-lan interface=ether10
add bridge=br-lan interface=sfp1
add bridge=br-lan interface=wlan1
```

## 6. Set static ip

IP => Addresses => Add:<br>
Adrdress: 192.168.9.1/24<br>
Interface: br-lan

```
/ip address add address=192.168.9.1/24 interface=br-lan
```

## 7. Enable dhcp client

IP => DHCP Client<br>
=> Add<br>
Interface: ether2<br>
=> Add<br>
Interface: ether3

## 8. DNS

IP => DNS:<br>
Allow Remote Requests: check

## 9. Time syncronization

System => NTP Client:<br>
Enable: true<br>
NTP Servers: pool.ntp.org

```
/system clock
set time-zone-name=Europe/Moscow
/system note
set show-at-login=no
/system ntp client
set enabled=yes
/system ntp client servers
add address=pool.ntp.org
```

## 10. DHCP Server

IP => DHCP Server => => DHCP Setup:<br>
DHCP Server Interface: br-lan<br>
DHCP Address Space: 192.168.9.0/24<br>
Gateway for DHCP Network: 192.168.9.1<br>
Adresses to Give Out: 192.168.9.2 - 192.168.9.254<br>
DNS Servers: 192.168.9.1<br>
Lease Time: 00:30:00 (default)

## 11. Interface Lists

Interfaces => Interface List<br>
=> Lists => Add => Name: WAN<br>
=> Add<br>
List: WAN<br>
Interface: ether2<br>
=> Add<br>
List: WAN<br>
interface: ether3

```
/interface list
add name=WAN

/interface list member
add interface=ether2 list=WAN
add interface=ether3 list=WAN
```

=> Lists => Add => Name: LAN<br>
=> Add<br>
List: LAN<br>
interface: ether1<br>
=> Add<br>
List: LAN<br>
interface: ether4<br>
=> etc...

```
/interface list
add name=LAN

/interface list member
add interface=ether1 list=LAN
add interface=ether4 list=LAN
add interface=ether5 list=LAN
add interface=ether6 list=LAN
add interface=ether7 list=LAN
add interface=ether8 list=LAN
add interface=ether9 list=LAN
add interface=ether10 list=LAN
add interface=sfp1 list=LAN
add interface=wlan1 list=LAN
```

## 12 Limit neighbor discovery by LAN interface list

IP => Neighbors => Discovery settings => Interface => LAN

```
/ip neighbor discovery-settings
set discover-interface-list=LAN
```

## 12. NAT

IP => Firewall => NAT<br>
=> Add:<br>
Chain: srcnat<br>
Src. Address: 192.168.9.0/24<br>
Out. Interface List: WAN<br>
=> Action<br>
Action: masqurade

```
/ip firewall nat
add action=masquerade chain=srcnat out-interface-list=WAN src-address=192.168.9.0/24
```

## 13. wifi

Wireless => Wireless:<br>
wlan1: enable<br>
=> Security Profiles => default:<br>
Mode: dynamic keys<br>
WPA2 PSK: check<br>
Unicast Ciphers => aes ccm: check<br>
Group Ciphers => aes ccm: check<br>
WPA2 Pre-Shared Key: _someStrongWifiPassword_<br>
=> WiFi Interfaces => wlan1 => Wireless<br>
Mode: ap bridge<br>
Band: 2Ghz-B/G/N<br>
SSID: _wifiName_<br>
Security Profile: default

## 14. Routing table

```
/routing table add disabled=no fib name=to-isp1-table
/routing table add disabled=no fib name=to-isp2-table
```

## 15. Routes

**ISP1**<br>
interface: ether2<br>
gateway: 192.168.1.1<br>
check ip: 192.168.8.1<br>

**ISP2**<br>
interface: ether3<br>
gateway: 192.168.8.1<br>
check ip: 77.88.8.8/32

### disable default routes

IP => DHCP Client => ether2-wan2:<br>
Add Default Route: no<br>

IP => DHCP Client => ether2-wan2:<br>
Add Default Route: no

### add custom routes

```
/ip route
add comment=isp1-check distance=10 dst-address=77.88.8.1 gateway=192.168.1.1
add comment=isp2-check distance=10 dst-address=77.88.8.8 gateway=192.168.8.1

add comment=isp1-default distance=251 gateway=192.168.1.1
add comment=isp2-default distance=252 gateway=192.168.8.1

add comment=to-isp1-table-default distance=10 gateway=192.168.1.1 routing-table=to-isp1-table
add comment=to-isp2-table-default distance=10 gateway=192.168.8.1 routing-table=to-isp2-table
```

## 16. firewall filter

IP => Firewall filter rules

```
/ip firewall filter
add action=accept chain=input comment="accept establish & related" connection-state=established,related
add action=drop chain=input comment="drop input invalid" connection-state=invalid
add action=drop chain=input comment="drop all other from wan" in-interface-list=WAN

add action=accept chain=forward comment="accept established,related" connection-state=established,related
add action=drop chain=forward comment="drop forward invalid" connection-state=invalid
add action=drop chain=forward comment="drop all not dstnated forward" connection-nat-state=!dstnat connection-state=new in-interface-list=WAN

add action=drop chain=output comment="block ping check isp1 address through isp2" dst-address=77.88.8.1 out-interface=ether3
add action=drop chain=output comment="block ping check isp2 address through isp1" dst-address=77.88.8.8 out-interface=ether2

# for debug
add action=drop chain=output comment="[DEBUG] block isp1-check address to check failover script" disabled=yes dst-address=77.88.8.1 out-interface=ether2
add action=drop chain=output comment="[DEBUG] block isp2-check address to check failover script" disabled=yes dst-address=77.88.8.8 out-interface=ether3
```

## 17. firewall mangle

IP => Firewall => Mangle

```
/ip firewall mangle
add action=mark-connection chain=prerouting comment="from isp1" connection-mark=no-mark in-interface=ether2 new-connection-mark=con-isp1 passthrough=yes
add action=mark-connection chain=prerouting comment="from isp2" connection-mark=no-mark in-interface=ether3 new-connection-mark=con-isp2 passthrough=yes

add action=mark-routing chain=prerouting comment="from lan to isp1" connection-mark=con-isp1 in-interface-list=!WAN new-routing-mark=to-isp1-table passthrough=yes
add action=mark-routing chain=prerouting comment="from lan to isp2" connection-mark=con-isp2 in-interface-list=!WAN new-routing-mark=to-isp2-table passthrough=yes

add action=mark-routing chain=output comment="from router to isp1" connection-mark=con-isp1 new-routing-mark=to-isp1-table passthrough=yes
add action=mark-routing chain=output comment="from router to isp2" connection-mark=con-isp2 new-routing-mark=to-isp2-table passthrough=yes
```

## 18. Add add-routes script

Sytem => Scripts => add:<br>
Name: addRoutes<br>
Source:

```
*content from scripts/add-routes.rsc*
```

### Adds scripts to dhcp clients

IP => DHCP Client =><br>
=> ether2 => Advanced => Script =>

```
*content from scripts/dhcp-client-ether2.rsc*
```

=> ether3 => Advanced => Script =>

```
*content from scripts/dhcp-client-ether3.rsc*
```

## 20. Failover script

System => Scripts => add:<br>
Name: failover<br>
Source:

```
*content from scripts/failover.rsc*
```

To force a switch to one of the providers, just change the script:

```
:local forceUseEnabled false;
```

to

```
:local forceUseEnabled true;
```

and set `isp1` or `isp2` for _forceUseIsp_ variable;

### Add job to scheduler

System => Scheduler => add<br>
Name: failover<br>
Interval: 00:00:15 // 15s<br>
On Event: failover // failover script name

## 21. Balance script

Sytem => Scripts => add:<br>
Name: balance<br>
Source:

```
*content from scripts/balance.rsc*
```

### check download speed and updates speed variables in balance script

#### for isp1 change distance to 251 for isp1-default route

```
/ip route set distance=251 numbers=[find comment="isp1-default"];
```

#### check download speed on <https://www.speedtest.net/>

and set it for _maxSpeedInMbitsIsp1_ variable in balance script:<br>
49.32 Mbps =>

```
:local maxSpeedInMbitsIsp1 49;
```

#### for isp2 change distance to 253 for isp1-default route

```
/ip route set distance=253 numbers=[find comment="isp1-default"];
```

#### check download speed on <https://www.speedtest.net/>

Set it for _maxSpeedInMbitsIsp2_ variable in balance script:<br>
28.45 Mbps =>

```
:local maxSpeedInMbitsIsp2 28;
```

### Add job to scheduler

System => Scheduler => add<br>
Name: balance<br>
Interval: 00:00:5 // 5s<br>
On Event: balance // balance script name

# 22. If you only need failover without balancing

1. In the scheduler, turn off the balance script
2. Manually change the distance for isp1-default route - either 241 - if you need isp1 provider, or 243 if you need isp2 provider
3. In the failover script for the variable<br>
   _forceUseIsp_ change value to true<br>
   and for _forceUseIsp_, specify either "isp1" or "isp2"
