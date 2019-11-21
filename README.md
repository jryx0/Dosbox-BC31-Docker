﻿# DOSBOX IN A CONTAINER WITH VNC CLIENT AND BORLAND C++ 3.1

1. Create a folder.
1. Place a copy of your program  in the folder. 
1. In that folder, create a file called `dockerfile`, paste in the following code.

  ````
  FROM ubuntu:18.04
ENV USER=root
#images and vnc password
ENV PASSWORD=123456
ENV DEBIAN_FRONTEND=noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN=true
#change sources
RUN sed -i "s/ports.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list
#copy local bc/BORLANDC to images /home/dos/bc31, dosbox will mount /home/dos as c  
COPY bc/BORLANDC /home/dos/bc31
#copy user defined dosbox config, dosbox will mount /home/projects  as d
COPY dosbox.bc31.conf  /home/projects/dosbox.bc31.conf
RUN apt-get update && \
	echo "tzdata tzdata/Areas select America" > ~/tx.txt && \
	echo "tzdata tzdata/Zones/America select New York" >> ~/tx.txt && \
	debconf-set-selections ~/tx.txt && \
	apt-get install -y tightvncserver ratpoison dosbox novnc websockify && \
	mkdir ~/.vnc/ && \
	mkdir ~/.dosbox && \	
	mv  /home/projects/dosbox.bc31.conf ~/.dosbox/dosbox.bc31.conf &&\
	echo $PASSWORD | vncpasswd -f > ~/.vnc/passwd && \
	chmod 0600 ~/.vnc/passwd && \
	echo "set border 0" > ~/.ratpoisonrc  && \
	echo "exec dosbox -conf ~/.dosbox/dosbox.bc31.conf -fullscreen  -c 'C:'">> ~/.ratpoisonrc && \
	export DOSCONF=$(dosbox -printconf) && \
	cp $DOSCONF ~/.dosbox/dosbox.conf && \
	sed -i 's/usescancodes=true/usescancodes=false/' ~/.dosbox/dosbox.conf && \
	openssl req -x509 -nodes -newkey rsa:2048 -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"
EXPOSE 80
CMD vncserver && websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 80 localhost:5901 && tail -f /dev/null
  ````

1. Replace the COPY BC /dos/bc31 with your  application (ie. COPY Borland C++/wolf3d /dos/wolf3d). 
1. You can also change the default password, or override it with a -e parameter when you run the image.
1. In dosbox.bc31.conf file, add mount info in [autoexec] section:
  ````
[autoexec]
# Lines in this section will be run at startup.
# You can put your MOUNT lines here.
mount c: /home/dos
mount d: /home/projects
path z:;c:\bc31\bin
  ````
Now, with Docker, build the image. CD to the directory in a console and run the command…
  ````
  docker build -t dosbox-bc31:v1 .
  ````
Run the image.
  ```` 
   docker run -p 80:80 dosbox-bc31:v1
   ````
   
1. Open a browser and point it to http://localhost/vnc.html.
1. You should see a prompt for the password. Type it in, and you should be able to connect to your container with DosBox running. You can now use the command prompt to start your games.
1. Once your image is built, you can push it to your image repository with docker push, but you’ll need to tag it appropriately.

# USE WITH KUBERNETES
Kubernetes is another part of the equation when it comes to container apps. Containers on Kubernetes are deployed into pods, which are then usually a part of a part of a deployment, which will have one or more pods associated with it. Deployments can also be used for creating scalable sets of pods for high availability too on a Kubernetes cluster. If you’re not familiar with Kubernetes, check out this webinar below where I go in depth on the matter.

Deployments and services can be defined declaratively with a YAML file. Below is a Kuberenetes YAML file that defines a deployment and a service for my retro gaming container.

The deployment is simple – it points to a single container image called blaize/keen and then tells Kubernetes what ports to expose for the container. The service defines how the deployment will be exposed on a network. In this case, it’s using a TCP load balancer, where it is exposing port 80 and mapping that to the port exposed by the deployment. The service uses selectors on the label app to match the service with the deployment.

````
apiVersion: v1
kind: Service
metadata:
  name: keen-service
  labels:
    app: keen-deployment
spec:
  ports:
  - port: 80
    targetPort: 6080
  selector:
    app: keen-deployment
  type: LoadBalancer
---
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: keen-deployment
spec:
  selector:
    matchLabels:
      app: keen-deployment
  replicas: 1
  template:
    metadata:
      labels:
        app: keen-deployment
    spec:
      containers:
      - name: master
        image: blaize/keen
        ports:
        - containerPort: 6080
````

To connect use this, first create a file called keen.yaml file, configure your instance kubectl to work with your instance of Kubernetes, then run deploy the sample.

````
kubectl create -f keen.yaml
````

When this is deployed to Kubernetes, Kubernetes will configure the external network to open on port 80 to listen to incoming requests. When used on Azure Kubernetes Services, AKS will create and map a public IP address (htttp://[your ip address]/vnc.html) for the service. Once connected, you can point your browser to the IP address of your cluster and have fun playing your retro games!
