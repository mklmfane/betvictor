pipeline {    
  agent { label "linux" }
  
  parameters {
         choice  choices: ["Baseline", "APIS", "Full"],
                 description: 'Type of scan that is going to perform inside the container',
                 name: 'SCAN_TYPE'
 
         string defaultValue: "http://10.0.0.10:8081",
                 description: 'Target URL to scan',
                 name: 'TARGET'
 
         booleanParam defaultValue: true,
                 description: 'Parameter to know if wanna generate report.',
                 name: 'GENERATE_REPORT'
  }
  
  options {
     buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  
  environment {
     registry = 'saragoza68/spring-petclinic-hub'
     registryCredential = 'dockerHub'
     dockerImage = ''
     def execute = false
  }
  
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
              	   docker run -d -p 8081:8181 registry 
           	"""
        }
     }
    
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
 
   post { 
        always {
            echo 'This is the result of the vulnerability test'
            echo "Removing container"
            sh '''
                 docker stop owasp
                 docker rm owasp
            '''
        }
     
        success {
            script {
              if (execute == true) {
                  echo 'Security tests passed succesfully! We are deploying to dockehub'
                  docker.withRegistry( '', registryCredential ) {
                  dockerImage.push("$BUILD_NUMBER")
                  dockerImage.push('latest')
                  }
              } else {
                  echo 'Security tests failed to pass! We do not deploy the image to the dockerHub and the pipeline will be aborted.'  
                  currentBuild.result = 'ABORTED' 
              }
            }
    }
}
}
