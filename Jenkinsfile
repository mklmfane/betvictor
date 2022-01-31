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
     stage("build preparation") {
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
            sh 'trivy image --no-progress --exit-code 0 --severity MEDIUM,HIGH,CRITICAL registry'
        }
    }
   }
 
   post { 
        always { 
            sh 'trivy image --no-progress --exit-code 1 --severity MEDIUM,HIGH,CRITICAL registry'
        }
        success {
            echo "Security tests passed succesfully!"
            script {
                  docker.withRegistry( '', registryCredential ) {
                  dockerImage.push("$BUILD_NUMBER")
                  dockerImage.push('latest')
                  }
            }
        }
          
        failure {
             catchError(buildResult: 'SUCCESS', postResult: 'ABORTED') { 
                    echo "Security tests failed to pass succesfully!"
                    sleep(time: 5, unit: "SECONDS")
             }
        }
    }
}
