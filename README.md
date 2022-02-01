
# Betvictor Interview Task - DevOps #

<p>As Docker usage has greatly increased, it has become increasingly important to gain a better understanding of how to securely configure and deploy Dockerized applications.
The Center for Internet Security published a Docker Benchmark, which provides consensus based guidance by subject matter experts for users and organizations to achieve secure Docker usage and configuration that u can find here
(https://www.cisecurity.org/benchmark/docker/), and that can be a good guideline on what to follow.
</p>


![Screenshot from 2022-02-01 23-24-22](https://user-images.githubusercontent.com/52984455/152053898-b7bc51cb-7dd6-4bbe-b400-baf68509970e.png)


The main objective of this exercise is for you to create a pipeline to do a security
inspection over newly created container images.


## Environment used ##
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
     



## The stages of the Pipeline: ##
*  Src code - Prepare a basic java spring boot web application. You can generate one
from (https://start.spring.io/) and necessary Dockerfile to build it.
   
  
  
   One common example of spring applicaiton is Petclinic applicaiton which can be build using maven by using the following Dockerfile.
   ### Alpine Linux with OpenJDK JRE ###
   FROM openjdk:8-jre-alpine
   EXPOSE 8181
   ### copy jar into image ###
   COPY target/spring-petclinic-2.2.0.BUILD-SNAPSHOT.jar /usr/bin/spring-petclinic.jar
   ### run application with this command line ###
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
  * Implement a mechanism to run a series of test to inspect the newly created image for security issues.
    Trivy can be used as tool to scan container images on teh virtual machien aqua label as linux 
    
    sudo apt-get install wget apt-transport-https gnupg lsb-release
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install trivy
   
   There are four stages of inspection in the pipeline performing security testing by using trivy and OWASP ZAP.
    *Report existing vulnerabilities using trivy installed locally by following the installation steps mentioined above 
   
    stage('Report existing vulnerabilities') {  
        steps {
            script {    
                node ('linux'){
                    def result = sh(script: "trivy image --no-progress --severity MEDIUM,HIGH,CRITICAL registry", returnStatus: true)
                    if (result == null) {
                       echo 'The returned command is succesfull!' 
                       execute = true
                    } else {
                       echo 'The returned command is failed!' 
                       execute = false
                    }
                }
            } 
        }
    }
    
    * Reporting information about the current status of scanning  
      It is important to displaye parameter initialized 
      ![Screenshot from 2022-02-02 00-13-13](https://user-images.githubusercontent.com/52984455/152060403-c529f92a-0051-44d8-8fee-65e1a4c92183.png)

      
    stage('Pipeline Info') {
         steps {
             script {
                 echo "<--Parameter Initialization-->"
                 echo """
                         The current parameters are:
                             Scan Type: ${params.SCAN_TYPE}
                             Target: ${params.TARGET}
                             Generate report: ${params.GENERATE_REPORT}
                 """
                     }
          }
     }
    
    * Setting up OWASP ZAP docker container just temporarely without reuqiring to keep the docker image on the virtual machine 

    ![Screenshot from 2022-02-02 00-13-13](https://user-images.githubusercontent.com/52984455/152060580-bc2cda3b-13cc-491d-b25d-0352e787e668.png)

    
    stage('Setting up OWASP ZAP docker container') {
           steps {
             script {
                   echo "Pulling up last OWASP ZAP container --> Start"
                   sh 'docker pull owasp/zap2docker-stable'
                   echo "Pulling up last VMS container --> End"
                   echo "Starting container --> Start"
                   sh """
                         docker run -dt --name owasp \
                         owasp/zap2docker-stable \
                         /bin/bash
                   """
             }
           }
    }
    
    * Work directory for OWASP ZAP is /zap/wrk to define the location of the report
    ![Screenshot from 2022-02-02 00-16-49](https://user-images.githubusercontent.com/52984455/152061055-ab44fbdf-2060-4f18-93ff-a7bb91255c69.png)

    stage('Prepare wrk directory') {
             when {
                         environment name : 'GENERATE_REPORT', value: 'true'
             }
             steps {
                 script {
                         sh """
                             docker exec owasp \
                             mkdir /zap/wrk
                         """
                     }
                 }
         }
  
     * Scanning target on owasp container is neccessary for the type of scanning performed
       To report all information it can be a better choice to choose full scanning. 
     ![Screenshot from 2022-02-02 00-21-05](https://user-images.githubusercontent.com/52984455/152061295-17e404b5-4708-4f70-8141-ebbcadc7bfbc.png)

         stage('Scanning target on owasp container') {
             steps {
                 script {
                     scan_type = "${params.SCAN_TYPE}"
                     echo "----> scan_type: $scan_type"
                     target = "${params.TARGET}"
                     if(scan_type == "Baseline"){
                         sh """
                             docker exec owasp \
                             zap-baseline.py \
                             -t $target \
                             -x report.xml \
                             -I
                         """
                     }
                     else if(scan_type == "APIS"){
                         sh """
                             docker exec owasp \
                             zap-api-scan.py \
                             -f openapi \
                             -t $target \
                             -x report.xml \
                             -I
                         """
                     }
                     else if(scan_type == "Full"){
                         sh """
                             docker exec owasp \
                             zap-full-scan.py \
                             -t $target \
                             -x report.xml \
                             -I
                         """
                         //-x report-$(date +%d-%b-%Y).xml
                     }
                     else{
                         echo "Something went wrong..."
                     }
                 }
             }
         }
         
         ** Copy the report in the home folder of the virtual machine
         
         ![Screenshot from 2022-02-02 00-23-21](https://user-images.githubusercontent.com/52984455/152061691-aa71bd98-5134-4c8d-ac75-9e607ebdf116.png)

         stage('Copy Report to Workspace'){
             steps {
                 script {
                     sh '''
                         docker cp owasp:/zap/wrk/report.xml ${WORKSPACE}/report.xml
                     '''
                 }
             }
         }
   }


  * Define clear policies for your container environment. (4-5 basic examples
are enough for this exercise)
  * Given some examples: kernel version bigger than N, openssl libs bigger than
version X, Users running container cannot go into privileged mode.

   Trivy can detetc a lot of vulenrabilities of the following spring docker image "saragoza68/spring-petclinic-hub"
![Screenshot from 2022-02-02 00-25-41](https://user-images.githubusercontent.com/52984455/152061884-662f24f9-8db3-41ea-9865-39aeff5d0b13.png)

* **Decision** - Little decision making stage, if one of security tests fails the pipeline is
aborted, if all tests pass, pipeline should progress to next stage.



This stage called 'Report existing vulnerabilities' is used to report vulnerabilities created through trivy.
  stage('Report existing vulnerabilities') {  
        steps {
            script {    
                node ('linux'){
                    def result = sh(script: "trivy image --no-progress --severity MEDIUM,HIGH,CRITICAL registry", returnStatus: true)
                    if (result == null) {
                       echo 'The returned command is succesfull!' 
                       execute = true
                    } else {
                       echo 'The returned command is failed!' 
                       execute = false
                    }
                }
            } 
        }
    }
    
    
//      In the post phase OWASP ZAP image will be removed as it is not necesary to be rpesent because it can be very dififculy to configured through the jenkins //plugins. Additionally, it is not effective to set OWASP ZAP throug jenkins plugin. that is why it is better to used OWASP ZAP to scan teh endpoint application //and then remove it.
   
   post { 
        always {
            echo 'This is the result of the vulnerability test'
            echo "Removing container"
            sh '''
                 docker stop owasp
                 docker rm owasp
            '''
        } 
        
 //  The variable execute is false because teh vulenebility scan report created by trivy containins too many vulnerabilities. That is the reason why the pieple //will be aborted  
 ![Screenshot from 2022-02-02 00-35-51](https://user-images.githubusercontent.com/52984455/152063112-efdfd615-013e-49b9-b912-423a0c7b4001.png)
        success {
            script {
              if (execute == true) {
                  echo 'Security tests passed succesfully! The image willl be attempted ot be deployed to Docker Hub.'
                  docker.withRegistry( '', registryCredential ) {
                  dockerImage.push("$BUILD_NUMBER")
                  dockerImage.push('latest')
                  }
              } else {
                  echo 'Security tests failed to pass! We do not deploy the image to the Docker Hub, and the pipeline will be aborted.'  
                  currentBuild.result = 'ABORTED' 
              }
            }
    }  

     


* **Registry** - If all test had passed you can upload the image to final docker registry.
The variable execute is used to checked whether the trivy vulenrability report is empty. Only in case the trivy vulnerability report is empty, the docker image will be uplaoded to private dockerhub set up on aqua virtual machine by using this command "docker login"
 success {
            script {
              if (execute == true) {
                  echo 'Security tests passed succesfully! The image willl be attempted ot be deployed to Docker Hub.'
                  docker.withRegistry( '', registryCredential ) {
                  dockerImage.push("$BUILD_NUMBER")
                  dockerImage.push('latest')
                  }

* **Report** - All Builds should produce a report of the tests ran and their result.
 There are two reports 
  ***The first report is generated by trivy ***
 ![trivy](https://user-images.githubusercontent.com/52984455/152064561-86e71330-f55b-47fc-8a8a-dd6f535ce731.png)
 
  *** The second report is created by OWASP ZAP ***
  ![Screenshot from 2022-02-02 00-45-54](https://user-images.githubusercontent.com/52984455/152064449-9a4579cf-b255-4ae0-b414-837887d6434d.png)
