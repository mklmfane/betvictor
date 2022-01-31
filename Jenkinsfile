pipeline {    
  agent { label "linux" }
  
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
    
     stage("build") {
        steps {    
            sh """ 
               docker build -t registry .    
            """
                
             script {
               dockerImage = docker.build registry
             } 
        }
     }
    
     stage("run") {
        steps {
           	sh """
              	   docker run -d -p 8081:8181 registry 
           	"""
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
