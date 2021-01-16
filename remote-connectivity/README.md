
About 
======

A detail description of secure connectivity to containers on the basis of OpenSSH. 
This guide can be useful in the situation when container is placed on remote host and admin/dev does not have access to the host machine.


Overview
================

Steps (1) and (2) can be used to create a container with linux + ssh toolset

1) Builds image with Ubuntu distribution and tag linux-ssh:20.04. Note the dot at the end of the command.
```
docker build -f Dockerfile-min -t linux-ssh:20.04 .
```

2) Instantiate container and connect it to standard console.
```
docker run -p 14403:22 -it linux-ssh:20.04 /bin/bash
```

3) Check sshd status.
```
service ssh status
```

If not started, one can start it as
```
service ssh start
```

Check open ports:
```
netstat -tulpn | grep LISTEN
```

4) Get IP Address of Container

Get the container’s IP address by using the docker inspect command and filtering out the results:

```
docker inspect -f "{{ .NetworkSettings.IPAddress }}" <container_id>
```
This command should return the ip address of container to ssh into

5) Check availability, optional (this command can return different result on different systems):
```
ping <IP_ADDRESS>
```

6) Directly connect to container via ssh.

Note, it is not a good idea to make root available via ssh. It would be better to add a new user and disable root ssh. We investigate exactly this case and due to this added a new user (webssh).
Open sshd_config file and set line ```PermitRootLogin no```, using the followig command to open file for editing
```
nano /etc/ssh/sshd_config
```

Use the SSH tool to connect to the image (works both on Windows and Linux host machines; for Windows have to install OpenSSH).
For example, if you are using Windows machine for your experiments to run docker containers, the command can be like so:
```
ssh -p 14403 webssh@localhost
```
We are done, one can execute commands as a webssh user.

7) Password-free SSH access 

The alternative to SSH password authentication is to create a special key pair and then copy the public half of the pair to the remote host, which is the computer where you eventually want to log in. 

Using encrypted keys for authentication offers two main benefits:

1) it is convenient as you no longer need to enter a password (unless you encrypt your keys with password protection) if you use public/private keys. 
2) once public/private key pair authentication has been set up on the server, you can disable password authentication completely meaning that without an authorized key you can't gain access - so no more password cracking attempts.

a) Generating a new key pair 
Use the command ```ssh-keygen``` to generate a new rsa key pair. Fro example, one can use test_rsa name, in this case two keys will be generated, test_rsa.pub and test_rsa

b)  Once created, you can move the public key to the file .ssh/authorized_keys on the host computer. That way the OpenSSH software running on the host will be able to verify the authenticity of a cryptographic message created by the private key on the client. Once the message is verified, the SSH session will be allowed to begin. 
```
mkdir /home/webssh/.ssh
mkdir /home/webssh/.ssh/authorized_keys
docker cp test_rsa.pub <container_id>:/home/webssh/.ssh/authorized_keys/test_rsa.pub
```
Set permissions for public key and folders:
```
chmod 700 /home/webssh/.ssh
chmod -R 644 /home/webssh/.ssh/authorized_keys
```

Finally open sshd_config file and set lines: 
```
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile      /home/webssh/.ssh/authorized_keys/test_rsa.pub
```

One can use the following command to edit config file(s):
```
nano /etc/ssh/sshd_config
```

Restart the ssh daemon on host side and we are done.


Recipe to use PuTTY for connection
===================================

1) Download and install PuTTY, PuTTYgen and Pageant

2) Create a PuTTY profile to save your server's settings

Start PuTTY, fill the Host Name and Port fields. 

Select the Connection -> Data sub-category. Specify the username that you plan on using in the Auto-login username field.

Expand the Connection -> SSH sub-category.

Highlight the Auth sub-category and click the Browse button and select your previously-created private key.

Return to the Session Category and enter a name for this profile then click the Save button.

Note: the format of cryptografic keys is different for OpenSSH and those used by PuTTY, so you have to convert private key to .ppk format (use PuTTYgen for that)
