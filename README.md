
About 
=======

This is a collection of recipes demonstrating how to create various on-premises cloud services on the basis of virtualization technologies (using Docker in particular).

Each recipe has two parts:

1) the fully automated approach (using hard typed commands in docker file) 

2) the manual one, describing chosen implementation step by step.
  


Overview
==========


/file-storage - this is an implementation of cloud-based file storage on the basis of Nextcloud server (https://nextcloud.com/), with backup on AWS S3.

/media-wiki - in short, this is just the implementation of content management system (CMS) on the basis of LAMP stack and MediaWiki (https://www.mediawiki.org/wiki/MediaWiki).

/openvpn-server - this recipe describes how to setup a vpn server

/remote-connectivity - this recipe describes how to establish a secure connectivity to containers on the basis of OpenSSH and private-public key pairs.

See the appropriate README files for installation and run details

Notes
======

Useful commands

Get the list of images:
```
docker images -a
```

Get the list of containers:
```
docker ps
```

Clean up local docker registry:
```
docker image prune -a --force --filter "until=2021-01-04T00:00:00"
```

Clean up local docker registry from images with <none> tag:
```
docker rmi --force $(docker images -q --filter "dangling=true")
```


