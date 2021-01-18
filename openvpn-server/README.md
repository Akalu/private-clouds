
About 
======

A detail description of how to setup a secure vpn network on the basis of OpenVPN. 

Overview
================
A properly designed VPN tunnel provides a direct connection between remote clients and a server in a way that hides data as it’s transferred across an insecure network.
Tunnels built with the open source OpenVPN package use the same TLS/SSL encryption you’ve already seen in use elsewhere. OpenVPN is not the only available choice for tunneling, but it’s among the best known. And it’s widely assumed to be a bit faster and more secure than the alternative Layer 2 Tunnel Protocol using IPsec encryption.


Manual approach
================

Steps (1) and (2) can be omitted if you are already on Linux

1) Builds image with Ubuntu distribution and tag linux:20.04. Note the dot at the end of the command.
```
docker build -f Dockerfile -t linux-vpn:20.04 .
```

2) Instantiates container and connects it to standard console.
```
docker run --cap-add=NET_ADMIN -p 14403:22 -p 8194:1194 -it linux-vpn:20.04 /bin/bash
```

3) (Optional) Then inside the container, set up a user, admin, and added it to the sudo group:
```
adduser admin
adduser admin sudo
```

Then set user to user1:
```
su - admin
```

Check admin's sudo permissions:
```
sudo -l
```

Check if they can access iptables via sudo:
```
sudo iptables -L -n
```

4) Preparing server for openvpn (preliminary steps: environment):
```
ufw enable
ufw allow 22
ufw allow 1194/udp
ufw allow 1194/tcp
```
To permit internal routing between network interfaces on the server, you’ll need to uncomment a single line (net.ipv4.ip_forward=1) in the /etc/sysctl.conf file. This allows remote clients to be redirected as needed once they’re connected. 
To load the new setting, run sysctl -p:
```
nano /etc/sysctl.conf
sysctl -p
```

5) Generate a set of public key infrastructure (PKI) encryption keys on the server using scripts that come with the easy-rsa package. Effectively, an OpenVPN server also acts as its own Certificate Authority (CA). 

The final configuration must be as a following one.
Server side must have the following keys:
```
dh.pem server.crt server.key
```

Client side must have the following keys:
```
client.crt client.key
```

Both sides must have a ca file:
```
ca.crt
```

Copy the easy-rsa template directory from /usr/share/ to /etc/openvpn/ and then change to the easy-rsa/ directory:
```
cp -r /usr/share/easy-rsa/ /etc/openvpn 
cd /etc/openvpn/easy-rsa
```
The whole list of commands of easyrsa script:
```
  init-pki
  build-ca [ cmd-opts ]
  gen-dh
  gen-req <filename_base> [ cmd-opts ]
  sign-req <type> <filename_base>
  build-client-full <filename_base> [ cmd-opts ]
  build-server-full <filename_base> [ cmd-opts ]
  revoke <filename_base> [cmd-opts]
  renew <filename_base> [cmd-opts]
  build-serverClient-full <filename_base> [ cmd-opts ]
  gen-crl
  update-db
  show-req <filename_base> [ cmd-opts ]
  show-cert <filename_base> [ cmd-opts ]
  show-ca [ cmd-opts ]
  import-req <request_file_path> <short_basename>
  export-p7 <filename_base> [ cmd-opts ]
  export-p12 <filename_base> [ cmd-opts ]
  set-rsa-pass <filename_base> [ cmd-opts ]
  set-ec-pass <filename_base> [ cmd-opts ]
```

6) Generate a PKI directory and a set of certificates:
```
./easyrsa init-pki
./easyrsa build-ca
```
A newly generated CA certificate file for publishing will be pushed at /etc/openvpn/easy-rsa/pki/ca.crt
Usually you have to provide domain name for ca, a base certificate name (I used cloud.com, test_server) and the passphrase.

7) Generate a keys pair:  because it uses the same pkitool script along with the new root certificate, you’ll be asked the same confirmation questions to generate a key pair. 
```
./easyrsa build-server-full
```
A newly generated key will be pushed into /etc/openvpn/pki/{private,issued}  directories

8) The following command generates pem file
```
./easyrsa gen-dh
```

9) Finally, you have to copy all keys to /etc/openvpn/ directory.
The reason is: all server-side keys will now have been written to the /etc/openvpn/easy-rsa/pki/ directory, but OpenVPN doesn’t know that. 
By default, OpenVPN will look for them in /etc/openvpn/, so copy them over:
```
cp -R /etc/openvpn/easy-rsa/pki/private/test* /etc/openvpn/server
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn
```

10) Generate a client keys bundle:
```
./easyrsa build-client-full
```

11) Create a server configuration file using template:
```
nano /etc/openvpn/test_server.conf
```

12) Create a TUN device:
```
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun
```

13) (re)start openvpn server 
```
service openvpn start
```
The command ```ip a``` should show the new network interface with name tun0:
```
4: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UNKNOWN group default qlen 100
    link/none
    inet 10.8.0.1 peer 10.8.0.2/32 scope global tun0
       valid_lft forever preferred_lft forever
```

in case of any errors the details of issue can be found in /etc/openvpn/openvpn.log file

14) Updating Firewall Configuration
To allow OpenVPN through the firewall, you’ll need to enable masquerading, an iptables concept that provides on-the-fly dynamic network address translation (NAT) to correctly route client connections.

Before opening the firewall configuration file to add the masquerading rules, you must first find the public network interface of your machine. To do this, type:
```
ip route list default
```

public interface is the string found within this command’s output that follows the word 'dev', f.e.
```
default via 172.17.0.1 dev eth0
```

When you have the interface associated with your default route, open the /etc/ufw/before.rules file to add the relevant configuration:

```
nano /etc/ufw/before.rules
```
 
UFW rules are typically added using the ufw command. Rules listed in the before.rules file, though, are read and put into place before the conventional UFW rules are loaded. Towards the top of the file, add the lines below. This will set the default policy for the POSTROUTING chain in the nat table and masquerade any traffic coming from the VPN. Remember to replace eth0 in the -A POSTROUTING line below with the interface you found in the above command:
```
# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES
```

Next, tell UFW to allow forwarded packets by default as well. To do this, open the /etc/default/ufw file:
```
nano /etc/default/ufw
```

Inside, find the DEFAULT_FORWARD_POLICY directive and change the value from DROP to ACCEPT:

```
DEFAULT_FORWARD_POLICY="ACCEPT"
```

After adding those rules, disable and re-enable UFW to restart it and load the changes from all of the files you’ve modified:
```
ufw disable
ufw enable
```

15) Create a client configuration based on sample file test_client.conf and {ca.crt,test_client.crt, test_client.key} bundle and test the vpn connection. The sample log file from the client:
```
Mon Jan 18 13:54:35 2021 Attempting to establish TCP connection with [AF_INET6]::1:8194 [nonblock]
Mon Jan 18 13:54:35 2021 MANAGEMENT: >STATE:1610967275,TCP_CONNECT,,,,,,
Mon Jan 18 13:54:35 2021 TCP connection established with [AF_INET6]::1:8194
Mon Jan 18 13:54:35 2021 TCP_CLIENT link local: (not bound)
Mon Jan 18 13:54:35 2021 TCP_CLIENT link remote: [AF_INET6]::1:8194
Mon Jan 18 13:54:35 2021 MANAGEMENT: >STATE:1610967275,WAIT,,,,,,
Mon Jan 18 13:54:35 2021 MANAGEMENT: >STATE:1610967275,AUTH,,,,,,
Mon Jan 18 13:54:35 2021 TLS: Initial packet from [AF_INET6]::1:8194, sid=fac16299 34020bd5
Mon Jan 18 13:54:35 2021 VERIFY OK: depth=1, CN=cloud.com
Mon Jan 18 13:54:35 2021 VERIFY OK: depth=0, CN=test_server
Mon Jan 18 13:54:35 2021 WARNING: 'link-mtu' is used inconsistently, local='link-mtu 1543', remote='link-mtu 1544'
Mon Jan 18 13:54:35 2021 WARNING: 'comp-lzo' is present in remote config but missing in local config, remote='comp-lzo'
Mon Jan 18 13:54:35 2021 Control Channel: TLSv1.2, cipher TLSv1.2 ECDHE-RSA-AES256-GCM-SHA384, 2048 bit RSA
Mon Jan 18 13:54:35 2021 [test_server] Peer Connection Initiated with [AF_INET6]::1:8194
Mon Jan 18 13:54:36 2021 MANAGEMENT: >STATE:1610967276,GET_CONFIG,,,,,,
Mon Jan 18 13:54:36 2021 SENT CONTROL [test_server]: 'PUSH_REQUEST' (status=1)
Mon Jan 18 13:54:36 2021 PUSH: Received control message: 'PUSH_REPLY,route 10.0.3.0 255.255.255.0,route 10.8.0.1,topology net30,ping 10,ping-restart 120,ifconfig 10.8.0.6 10.8.0.5,peer-id 0,cipher AES-256-GCM'
Mon Jan 18 13:54:36 2021 Data Channel: using negotiated cipher 'AES-256-GCM'
Mon Jan 18 13:54:36 2021 Outgoing Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Mon Jan 18 13:54:36 2021 Incoming Data Channel: Cipher 'AES-256-GCM' initialized with 256 bit key
Mon Jan 18 13:54:36 2021 interactive service msg_channel=0
Mon Jan 18 13:54:36 2021 ROUTE_GATEWAY 172.16.0.3/255.255.240.0 I=16 HWADDR=f4:6d:04:18:41:f9
Mon Jan 18 13:54:36 2021 open_tun
Mon Jan 18 13:54:36 2021 TAP-WIN32 device [Ethernet 2] opened: \\.\Global\{08EC22C6-33AD-401E-8E51-3DD64DCE7095}.tap
Mon Jan 18 13:54:36 2021 TAP-Windows Driver Version 9.21 
Mon Jan 18 13:54:36 2021 Notified TAP-Windows driver to set a DHCP IP/netmask of 10.8.0.6/255.255.255.252 on interface {08EC22C6-33AD-401E-8E51-3DD64DCE7095} [DHCP-serv: 10.8.0.5, lease-time: 31536000]
Mon Jan 18 13:54:36 2021 Successful ARP Flush on interface [3] {08EC22C6-33AD-401E-8E51-3DD64DCE7095}
Mon Jan 18 13:54:36 2021 MANAGEMENT: >STATE:1610967276,ASSIGN_IP,,10.8.0.6,,,,
Mon Jan 18 13:54:41 2021 TEST ROUTES: 2/2 succeeded len=2 ret=1 a=0 u/d=up
Mon Jan 18 13:54:41 2021 MANAGEMENT: >STATE:1610967281,ADD_ROUTES,,,,,,
Mon Jan 18 13:54:41 2021 C:\windows\system32\route.exe ADD 10.0.3.0 MASK 255.255.255.0 10.8.0.5
Mon Jan 18 13:54:41 2021 ROUTE: CreateIpForwardEntry succeeded with dwForwardMetric1=35 and dwForwardType=4
Mon Jan 18 13:54:41 2021 Route addition via IPAPI succeeded [adaptive]
Mon Jan 18 13:54:41 2021 C:\windows\system32\route.exe ADD 10.8.0.1 MASK 255.255.255.255 10.8.0.5
Mon Jan 18 13:54:41 2021 ROUTE: CreateIpForwardEntry succeeded with dwForwardMetric1=35 and dwForwardType=4
Mon Jan 18 13:54:41 2021 Route addition via IPAPI succeeded [adaptive]
Mon Jan 18 13:54:41 2021 Initialization Sequence Completed
Mon Jan 18 13:54:41 2021 MANAGEMENT: >STATE:1610967281,CONNECTED,SUCCESS,10.8.0.6,::1,8194,::1,61304

```


References
===========
More about OpenVPN: [https://openvpn.net/]



