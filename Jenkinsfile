pipeline {    
  agent { label "linux" }
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
                node ('linux'){
                    def result = sh(script: "trivy image --no-progress --severity MEDIUM,HIGH,CRITICAL registry", returnStatus: true)
                    if (result == null) {
                       echo 'The returned command is succesfull!' 
                       execute = true
                    } else {
                       echo 'The returned command is failed!' 
                    }
                }
            } 
        }
    }
   }
 
   post { 
        always {
            echo 'This is the result of the vulnerability test'
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
                echo 'Security tests failed to pass!'    
              }
            }
    }
}
}
