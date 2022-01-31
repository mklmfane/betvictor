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
  
  def build_ok = true
  
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
    
     try{
        stage('Scan for vulnerabilities') {
          steps {
            sh 'trivy image --no-progress --exit-code 1 --severity MEDIUM,HIGH,CRITICAL registry'
          }
        }
      } catch (e) {
             build_ok = false
             echo e.toString()  
        }
    
     if(build_ok) { 
        currentBuild.result = "SUCCESS" 
        stage('Deploy Image') {
           steps {
             script {
                docker.withRegistry( '', registryCredential ) {
                dockerImage.push("$BUILD_NUMBER")
                dockerImage.push('latest')
             }
           }  
        }
      } else {
           currentBuild.result = "FAILURE"
           echo "Image failed and we do not deploy unsecure image to the repository" 
      }
     }
  }
}
}
