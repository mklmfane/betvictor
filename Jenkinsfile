pipeline {    
  agent { label "linux" }
  options {
     buildDiscarder(logRotator(numToKeepStr: '5'))
  }
  
  environment {
     registry = 'saragoza68/spring-petclinic-hub'
     registryCredential = 'dockerHub'
     dockerImage = ''
  }
  
  stages {
     stage("Build preparation") {
        steps {
            sh """
               mvn clean install
            """ 
        }
     }
    
     stage("Build spring application image") {
        steps {    
            sh """ 
               docker build -t registry .    
            """
                
            //script {
            //   dockerImage = docker.build registry
            //} 
        }
     }
    
     stage("Run container") {
        steps {
           	sh """
              	   docker run -d -p 8081:8181 registry 
           	"""
        }
     }
    
     stage('Scan for vulnerabilities') {
        steps {
            sh 'trivy image --no-progress --exit-code 1 --severity MEDIUM,HIGH,CRITICAL registry'
        }
     }
    
     stage('Deploy Image') {
         steps{
             script {
                docker.withRegistry( '', registryCredential ) {
                dockerImage.push("$BUILD_NUMBER")
                dockerImage.push('latest')
             }
         }
     }
  }
}
}
