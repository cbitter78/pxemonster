# PXE Monster

Utility to manage PXE files via web service call

If you dont want a huge PXE server like Foreman or Cobbler you can just run this little docker container to allow web calls in post kick start to remove pxelinux.cfg files so on next boot the pxelinux.cfg/default (where you can chain boot the hard drive) will be used.


## Problem this solves

When setting up my home lab for OpenStack I wanted a way I could rebuild all the hosts without touching them.  The issue is I used [consumer grade hosts](http://www.amazon.com/Gigabyte-i3-4010U-Barebones-Thickness-GB-BXi3H-4010/dp/B00I05NH9S?ie=UTF8&psc=1&redirect=true&ref_=oh_aui_detailpage_o08_s01) which do not have an IPMI interface.  They do have a PXE boot option and can be set to PXE boot on every boot.  

To accomplish my goal I set the hosts to PXE boot on every boot.   This way the host will PXE boot every time.  I then set up the PXE server up with a pxelinux.cfg/default file that will chain load the local hard drive.   

I can use PXE Monster to create a pxelinux.cfg file set to the hex value of the ip address of the host that on first reboot will start the OS install.  Then by adding a post install curl call to PXE Monster as a post OS install call I can remove the ip hex file forcing the next boot to chain load via the pxelinux.cfg/default.

The defult file should look something liek this:

```
default local

LABEL local
     MENU LABEL (local)
     MENU DEFAULT
     LOCALBOOT 0

```

This offers a REST based way to set up for a build then simply reboot the target host.   This gives me 99% of the functionality of a IPMI enabled host at 1/10 the price.


## Design

Pxe Monister will run as a docker container where you use the -v option to mount the local pxelinux folder under /pxelinux.cfg like this

```
-v /Users/cbitte000/Dev/pxemonster/spec/pxelinux.cfg:/pxelinux.cfg
```

It is assumed you will set up your dhcp server to boot a given mac to the same ip address.  All the pxelinux.cfg files will be based on ip address ([as hex](http://www.syslinux.org/wiki/index.php?title=PXELINUX#Configuration)) not mac.  


## Usage

```
docker pull cbitter78/pxemonister:0.0.3-0
run --rm -ti -p 192.168.1.1:8080:80 -v /var/lib/tftpboot/pxelinux.cfg:/pxelinux.cfg cbitter78/pxemonister:0.0.3-0

```

*NOTE:* Adjuest the localtion of your pxelinxu.cfg folder and the tag verion of the docker container. 

This will start pxemonister listing on your host on port 8080 and it will manage the local folder of /var/lib/pxelinux/pxelinux.cfg

## Deamon

You can run pxemonister in the background with this

```
docker run -ti -d -p 192.168.1.1:8080:80 -v /var/lib/tftpboot/pxelinux.cfg:/pxelinux.cfg cbitter78/pxemonister:0.0.3-0
```

You could add it to /etc/rc.local or a start up script.

You can get the logs by using docker log [container id]


## Config

A pxemonister.yml file must exits itn the mounted pxelinux.cfg folder.  It should look like this

```
---
- ip: 192.168.1.20
  pxe_template: ubuntu_1404.erb
  kickstart_url: http://192.168.1.1/ubuntu_1404/ubuntu.ks
- ip: 192.168.1.21
  pxe_template: ubuntu_1404.erb
  kickstart_url: http://192.168.1.1/ubuntu_1404/ubuntu.ks

```

Each elemet in the yaml array must have the ip, and pxe_template keys.  Entire hash is passed to the pxe_template ERB.  You can feel free to add extta key / values to be used in the ERB that creates the pxelinux.cfg file per ip.

The referanced pxe_template erb file must also exist in the same folder.


## Example

Take a look at the spec/pxelinux.cfg folder for an example of how you should set yours up.


### Pxe Files script

Here is an easy way to create pxe files

```
for i in 21 22; do 
curl -X POST "http://192.168.1.1:8080/pxe?spoof=192.168.1.$i"
done

```


### Post KickStart delete command.

This is the command I put in the post kick start to remove the pxe file.

```
curl -X DELETE "http://192.168.1.1:8080/pxe"
```



# License (MIT)

Copyright (c) 2016 Charles Bitter 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.