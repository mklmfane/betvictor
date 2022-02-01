
## Betvictor Interview Task - DevOps ##

<p>As Docker usage has greatly increased, it has become increasingly important to gain a better understanding of how to securely configure and deploy Dockerized applications.
The Center for Internet Security published a Docker Benchmark, which provides consensus based guidance by subject matter experts for users and organizations to achieve secure Docker usage and configuration that u can find here
(https://www.cisecurity.org/benchmark/docker/), and that can be a good guideline on what to follow.
</p>


![Screenshot from 2022-02-01 23-24-22](https://user-images.githubusercontent.com/52984455/152053898-b7bc51cb-7dd6-4bbe-b400-baf68509970e.png)


The main objective of this exercise is for you to create a pipeline to do a security
inspection over newly created container images.


# Environment used
* To install this environment, install vagrant and run vagrant up by runing these commands.
   Vagrant can 
   git clone https://github.com/mklmfane/betvictor.git
   cd betvictor
   vagrant up
   
* Two virtual machines such as jenkins and ubuntu will be installed to host the pipeline. 

* The pipeline is hosted in the environment created by vagrant
   * Jenkins master VM with ubuntu 
   * Ubuntu VM called aqua which is using the ssh agent to connect to jenkins VM.
     ![Screenshot from 2022-02-01 23-44-36](https://user-images.githubusercontent.com/52984455/152056628-9f1c2e2d-ca2a-4504-9fb9-2ce51b3cb6c6.png)
     the folloiwng linux 
     Maven is installed on ubuntu VM which acts as a slave with ssh agent connected to jenkin master virtual machine.
     ![node vm](https://user-images.githubusercontent.com/52984455/152055382-ba801090-b807-4ea3-9085-d8f6e1efe102.png)
     The actual code of the pipeline is running on aqua virtul machine labeled as linux in the pipeline code provided by Jenkinsfile. 
     pipeline {    
      agent { label "linux" }
     



# The stages of the Pipeline:
*  Src code - Prepare a basic java spring boot web application. You can generate one
from (https://start.spring.io/) and necessary Dockerfile to build it.
   
  
  
   One common example of spring applicaiton is Petclinic applicaiton which can be build using maven by using the following Dockerfile.
   # Alpine Linux with OpenJDK JRE
   FROM openjdk:8-jre-alpine
   EXPOSE 8181
   # copy jar into image
   COPY target/spring-petclinic-2.2.0.BUILD-SNAPSHOT.jar /usr/bin/spring-petclinic.jar
   # run application with this command line 
   ENTRYPOINT ["java","-jar","/usr/bin/spring-petclinic.jar","--server.port=8181"]

   The pipeline will be built with these parameters
     parameters {
         choice  choices: ["Baseline", "APIS", "Full"],
                 description: 'Type of scan that is going to perform inside the container',
                 name: 'SCAN_TYPE'
 
         string defaultValue: "http://10.0.0.10:8086",
                 description: 'Target URL to scan',
                 name: 'TARGET'
 
         booleanParam defaultValue: true,
                 description: 'Parameter to know if wanna generate report.',
                 name: 'GENERATE_REPORT'
  } 
   
  The ip address 10.0.0.10 is for the virtual machine which is hosting the spring application required to be built and scanned.
   
  
      * Build - Create your docker image.

        This code will built petclinic spring application
        stages {
           stage("Build image for spring app") {
              steps {
                  sh """
                     mvn clean install
                  """ 
              }
           }

           stage("Build container") {
              steps {    
                  sh """ 
                     docker build -t registry .    
                  """

                  script {
                     dockerImage = docker.build registry
                  } 
              }
           }

           stage("Run container from an image") {
              steps {
                  sh """
                         docker run -d -p 8086:8181 registry 
                  """
              }
           }

   After building the pipeline, the spring application will be up and running.
   ![Screenshot from 2022-02-01 23-56-41](https://user-images.githubusercontent.com/52984455/152058313-65a6d1fa-9b1f-4161-b6c4-5937c8ee2daa.png)
 
    To access the endpoint you can run on the physical machine launch these linux commands as by default docker0 interface crated through installation of docker does not allow any communication coming from the virtual machine.   
    sudo sysctl net.ipv4.conf.all.forwarding=1
    sudo iptables -P FORWARD ACCEPT




* **Inspection**
  * Implement a mechanism to run a series of test to inspect the newly created
image for security issues.
  * Define clear policies for your container environment. (4-5 basic examples
are enough for this exercise)
  * Given some examples: kernel version bigger than N, openssl libs bigger than
version X, Users running container cannot go into privileged mode.

* **Decision** - Little decision making stage, if one of security tests fails the pipeline is
aborted, if all tests pass, pipeline should progress to next stage.

* **Registry** - If all test had passed you can upload the image to final docker registry.

* **Report** - All Builds should produce a report of the tests ran and their result.
