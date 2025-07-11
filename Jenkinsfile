pipeline {
    agent {
        label 'Build_Test_Node'
    }
    environment {
     MONGO_URI = "mongodb://192.168.0.104:27017"
     MONGO_USERNAME = credentials('mongodb_username')
     MONGO_PASSWORD = credentials('mongodb_pass')
     GLOBAL_MONGO_URI = 'your_global_mongodb_instance_uri'
     SONAR_SCANNER_HOME = tool 'sonarqubescanner';
     GITEA_TOKEN =  credentials('gitea_token')
    }
    tools {
      nodejs 'nodejs' 
    }
    options {
      disableConcurrentBuilds abortPrevious: true
      disableResume()
    }
    stages {
        stage('Installing app dependancies') {
            options { timestamps() }
            steps {
                sh 'npm install --no-audit'
                sh 'npm install mocha-junit-reporter@latest'
            }
        }
        stage('Dependecies static scanning') {
            when {
              branch 'feature/*'
            }
            parallel {
                stage('NPM Dependency Audit') {
                    steps {
                      sh '''
                      npm audit --audit-level=critical
                      echo $?
                      '''
                    }
                }
                stage('OWASP Dependency Check')  {
                    steps {
                      dependencyCheck additionalArguments: '''
                      --scan \'./\'
                      --out \'./\'
                      --format \'ALL\'
                      --disableYarnAudit
                      --prettyPrint''', odcInstallation: 'owasp-deepcheck'
                    }
                }
            }
        }
        stage('Unit testing using npm test') {
            when {
              branch 'feature/*'
            }
            options { retry(2) }
            steps {
                sh 'npm test'
            }
        }
        stage('Code Coverage using npm run coverage') {
            when {
              branch 'fearture/*'
            }
            steps { 
                    catchError(buildResult: 'SUCCESS', message: 'error', stageResult: 'UNSTABLE') {
                          sh 'npm run coverage'
                          sh 'mkdir reports-$BUILD_ID'
                          sh 'cp -rf coverage/ reports-$BUILD_ID'
                    }
                    
            }
        }
        stage('Checking Code Quaity Using SonarQube quality_gate') {
            when {
              branch 'feature/*'
            }
            steps {
                sh 'echo $SONAR_SCANNER_HOME'
                withSonarQubeEnv(installationName: 'sq1') { 
                   sh ''' 
                      $SONAR_SCANNER_HOME/bin/sonar-scanner   -Dsonar.projectKey=solar-system   -Dsonar.sources=app.js 
                    '''
                }
                sh 'sleep 30'
                timeout(time: 1, unit: 'MINUTES') {
                      waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Docker images building') {
            when {
                anyOf {
                   branch 'feature/*'
                   branch 'PR*'
                }
            }
            steps {
              sh 'docker build -t ibrahimmohamed2/solar-system:$GIT_COMMIT .'
            }
        }
        stage('Trivy image scanning for filesystem vulnerabilities') {
            when {
                anyOf {
                   branch 'feature/*'
                   branch 'PR*'
                }
            }
            steps {
              sh 'trivy image --skip-db-update --skip-version-check --timeout 10m  --severity LOW,MEDIUM --format json -o trivy-image-MEDIUM-results.json --exit-code 0 ibrahimmohamed2/solar-system:$GIT_COMMIT'
              sh 'trivy image --skip-db-update --skip-version-check --timeout 10m  --severity CRITICAL --format json -o trivy-image-CRITICAL-results.json --exit-code 1 ibrahimmohamed2/solar-system:$GIT_COMMIT'
            }
            post {
                always {
                    sh 'trivy convert --format template --template "@//usr/local/share/trivy/templates/html.tpl"   --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json'
                    sh 'trivy convert --format template --template "@//usr/local/share/trivy/templates/html.tpl"   --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json'
                    sh 'trivy convert --format template --template "@//usr/local/share/trivy/templates/junit.tpl"  --output trivy-image-MEDIUM-results.xml trivy-image-MEDIUM-results.json'
                    sh 'trivy convert --format template --template "@//usr/local/share/trivy/templates/junit.tpl"  --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json'
                }

            }
        }
        stage('Docker image push') {
            when {
                anyOf {
                   branch 'feature/*'
                   branch 'PR*'
                }
            }
            steps {
                withDockerRegistry(credentialsId: 'docker', url: '') {
                  sh 'docker push ibrahimmohamed2/solar-system:$GIT_COMMIT'
                }
            }
        }
        stage('Continous deployment in dev env on aws ec2 docker instance') {
            when {
              branch 'feature/*'
            }
            steps {
                script {
                    sh 'echo $GLOBAL_MONGO_URI'
                    sshagent(['ec2']) {
                        sh '''
                            ssh -o  StrictHostKeyChecking=no ec2-user@157.175.148.33"
                            if sudo docker ps -a  | grep -qw "solar-system-app"; then
                                echo "container is already deployed..stopping.."
                                sudo docker stop solar-system-app && sudo docker rm solar-system-app
                                echo "cleaned up"
                            fi
                            echo $GLOBAL_MONGO_URI > test.txt
                            sudo docker run -p 80:3000 --name solar-system-app -e MONGO_URI=$GLOBAL_MONGO_URI -e MONGO_USERNAME=$MONGO_USERNAME -e MONGO_PASSWORD=$MONGO_PASSWORD -d ibrahimmohamed2/solar-system:$GIT_COMMIT
                            "
                        '''
                    }
                }
            }
        }
        stage('Intergation testing in aws ec2') {
            when {
              branch 'feature/*'  
            }
            steps {
                withAWS(region: 'me-south-1',credentials: 'aws') {
                    sh 'printenv | grep -i branch'
                    sh '''
                      bash ./Intergartion-test.sh
                    '''
                    sh "cp test-results.xml reports-$BUILD_ID"
                    s3Upload(file:"reports-$BUILD_ID", bucket:'securityreportsjenkins1', path:'/coverage-intergration-reports/')
                }
            }
        }
        stage('Updating the image tag in deployment.yaml file') {
            when {
                branch 'PR*'
            }
            steps {
                sh 'git clone -b main http://192.168.0.104:3000/myorg/solar-system-gitops-argocd-gitea'
                dir("solar-system-gitops-argocd-gitea/kubernetes") {
                    sh '''
                    git checkout main
                    git checkout -b feature-$BUILD_ID
                    sed -i "s#ibrahimmohamed2.*#ibrahimmohamed2/solar-system:$GIT_COMMIT#g" deployment.yml
                    git config --global user.email "sci.ibrahimmohamed@gmail.com"
                    git config --global user.name "ibrahim"
                    git remote set-url origin http://$GITEA_TOKEN@192.168.0.104:3000/myorg/solar-system-gitops-argocd-gitea
                    git add .
                    git commit -m "'after changing the tag'"
                    git push -u origin feature-$BUILD_ID
                    '''
                }
            }
        }
        stage('Raise PR in K8S repo') {
            when {
                branch 'PR*'
            }
            steps {
                sh """
                        curl -X 'POST' \
                        'http://192.168.0.104:3000/api/v1/repos/myorg/solar-system-gitops-argocd-gitea/pulls' \
                        -H 'accept: application/json' \
                        -H "Authorization: token $GITEA_TOKEN" \
                        -H 'Content-Type: application/json' \
                        -d '{
                        "base": "main",
                        "body": "This is a pull request to deploy the new container image",
                        "head": "feature-$BUILD_ID",
                        "title": "deploy update into k8s cluster"
                        }'
                """
            }
        }
        stage('confirmation of successful app deployment') {
            when {
                branch 'PR*'
            }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Has the solar-system app deployed ?', ok: 'Yes'
                }
            }
        }
        stage('DAST scan on the runnning app') {
             when {
                 branch 'PR*'
             }
            steps {
                sh '''
                chmod 777 $(pwd)
                docker run -v $(pwd):/zap/wrk:rw ghcr.io/zaproxy/zaproxy zap-api-scan.py \
                -t http://192.168.0.6:30000/api-docs \
                -f openapi \
                -r zap_report.html \
                -w zap_report.md \
                -J zap_report.json \
                -x zap_report.xml \
                -c zap_ignore_rules
                '''
                sh """
                mkdir reports-$BUILD_ID
                cp trivy-image* zap_report*  reports-$BUILD_ID/
                ls -l reports-$BUILD_ID/
                """
                withAWS(region: 'me-south-1',credentials: 'aws') {
                  sh "ls -al reports-$BUILD_ID"
                  s3Upload(file:"reports-$BUILD_ID", bucket:'securityreportsjenkins1', path:'/zap-reports/')
                }
            }
        }
        stage('confirmation to deploy into production') {
            when {
                branch 'main'
            }
            steps {
                timeout(time: 1, unit: 'DAYS') {
                    input message: 'Deploy to prod?', ok: 'Are you sure?', submitter: 'ibrahim_mohamed'
                }
            }
        }
        stage('Deploy to production') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                npm install
                tail -5 app.js
                sed -i "/^app\\.listen(3000/ s/^/\\/\\//" app.js
                sed -i 's/^module.exports = app;/\\/\\/module.exports = app;/g' app.js
                tail -5 app.js
                sed -i 's|//module.exports.handler|module.exports.handler|' app.js
                tail -5 app.js
                '''
                sh '''
                zip -qr solar-system-$BUILD_ID.zip  app* package*  node_modules/ index.html 
                ls -tlr solar-system-$BUILD_ID.zip
                '''
                withAWS(region: 'me-south-1',credentials: 'aws') {
                  s3Upload(file: "solar-system-${BUILD_ID}.zip", bucket:'solar-system-ibrahim')
                
                sh """
                aws lambda update-function-configuration \
                --function-name solar-system \
                --environment='{"Variables":{ "MONGO_USERNAME": "${MONGO_USERNAME}", "MONOGO_PASSWORD": "${MONGO_PASSWORD}", "MONGO_URI": "${GLOBAL_MONGO_URI}"}}'

                """
                sh '''
                aws lambda update-function-code --region me-south-1\
                --function-name solar-system \
                --s3-bucket solar-system-ibrahim \
                --s3-key solar-system-$BUILD_ID.zip
                '''
                }
            }
        }
        stage('Unit testing in production') {
            when {
                branch 'main'
            }
            steps {
                withAWS(region: 'me-south-1',credentials: 'aws') {
                sh '''
                sleep 30
                data=$(aws lambda get-function-url-config --region me-south-1 --function-name solar-system) 
                url=$(echo $data | jq -r '.FunctionUrl | sub("/$"; "")')
                curl -Is $url | grep -i "200 OK"
                '''
                }
            }
        }

    }
    post {
       always {
           script {
             if(fileExists('solar-system-gitops-argocd-gitea')) {
                sh 'rm -rf solar-system-gitops-argocd-gitea'
             }
           }
           junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
           publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'coverage', reportTitles: '', useWrapperFileDirectly: true])
           junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
           junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
           junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
           dependencyCheckPublisher failedTotalCritical: 1, failedTotalLow: 0, pattern: 'dependency-check-report.xml', stopBuild: true, unstableTotalCritical: 0, unstableTotalHigh: 0
           publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'dependency-check-report.html', reportName: 'deb check', reportTitles: '', useWrapperFileDirectly: true])
           publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'medium trivy report', reportTitles: '', useWrapperFileDirectly: true])
           publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'critical trivy report', reportTitles: '', useWrapperFileDirectly: true])
           publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST analysis', reportTitles: '', useWrapperFileDirectly: true])
       }
    }   
} 
