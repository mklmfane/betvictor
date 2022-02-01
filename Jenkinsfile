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
            script {    
                def result = sh(script: "trivy image --no-progress --severity MEDIUM,HIGH,CRITICAL registry", returnStatus: true)
                if (result == null) {
                   exit 0 
                } else {
                   exit 1
                }
            } 
        }
    }
   }
 
   post { 
        always {
            echo 'This is the result of the vulenrability test '
        }
     
        success {
            echo 'Security tests passed succesfully!'
            script {
                docker.withRegistry( '', registryCredential ) {
                dockerImage.push("$BUILD_NUMBER")
                dockerImage.push('latest')
            }
        }
          
        failure {
                echo 'Security tests failed to pass succesfully!' 
        }
    }
}
}
