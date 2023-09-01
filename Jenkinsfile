pipeline {
    agent any

    environment {
        HYOBIN_DOCKER_HUB_USER_NAME = 'hellmir'
        EC2_DEPLOY_PATH = '/home/ubuntu'
        EC2_IP = '13.125.242.255'
    }

    stages {

        stage('Check Branch') {
            steps {
                script {
                    if (env.GIT_BRANCH != 'origin/dev_hyobin') {
                        currentBuild.result = 'ABORTED'
                        error("Build is not for the 'dev_hyobin' branch. Aborting.")
                    }
                }
            }
        }

        stage('Environment Setup') {
            steps {
                script {
                    sh 'chmod +x ./gradlew'
                    def projectName = sh(script:'./gradlew -q printProjectName', returnStdout:true).trim()
                    def projectVersion = sh(script:'./gradlew -q printProjectVersion', returnStdout:true).trim()
                    env.PROJECT_NAME = projectName
                    env.PROJECT_VERSION = projectVersion
                    env.JAR_PATH = "${WORKSPACE}/build/libs/${env.PROJECT_NAME}-${env.PROJECT_VERSION}.jar"
                }
                echo 'Environment variables set'
            }
        }

        stage('Test') {
            steps {
                dir("${WORKSPACE}") {
                    sh './gradlew test'
                }
                echo 'Tests complete'
            }
        }

        stage('Build') {
            steps {
                sh "chmod u+x ${WORKSPACE}/gradlew"
                dir("${WORKSPACE}") {
                    sh './gradlew clean build'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def dockerImageTag = "${env.PROJECT_NAME}:${env.PROJECT_VERSION}"
                    sh "docker build -t ${dockerImageTag} -f ${WORKSPACE}/Dockerfile ${WORKSPACE}"
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'HYOBIN_DOCKER_HUB_ACCESS_TOKEN', variable: 'HYOBIN_DOCKER_HUB_ACCESS_TOKEN')]) {
                        sh '''
                        echo $HYOBIN_DOCKER_HUB_ACCESS_TOKEN | docker login -u $HYOBIN_DOCKER_HUB_USER_NAME --password-stdin
                        '''
                    }

                    def dockerImageTag = "${env.PROJECT_NAME}:${env.PROJECT_VERSION}"
                    sh "docker tag ${dockerImageTag} $HYOBIN_DOCKER_HUB_USER_NAME/${dockerImageTag}"
                    sh "docker push $HYOBIN_DOCKER_HUB_USER_NAME/${dockerImageTag}"
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    withCredentials([
                        sshUserPrivateKey(credentialsId: 'EC2_DEPLOY_KEY', keyFileVariable: 'EC2_DEPLOY_KEY'),
                        string(credentialsId: 'HYOBIN_DB_ROOT_PASSWORD', variable: 'HYOBIN_DB_ROOT_PASSWORD'),
                        string(credentialsId: 'HYOBIN_DB_USER_NAME', variable: 'HYOBIN_DB_USER_NAME'),
                        string(credentialsId: 'HYOBIN_DB_USER_PASSWORD', variable: 'HYOBIN_DB_USER_PASSWORD')
                    ]) {
                        sh '''
                        scp -i "$EC2_DEPLOY_KEY" set-up-docker.sh ubuntu@"$EC2_IP":"$EC2_DEPLOY_PATH"
                        '''
                        sh '''
                        scp -i "$EC2_DEPLOY_KEY" "$JAR_PATH" ubuntu@"$EC2_IP":"$EC2_DEPLOY_PATH"
                        '''
                        sh '''
                        scp -i "$EC2_DEPLOY_KEY" deploy.sh check-and-restart.sh ubuntu@"$EC2_IP":"$EC2_DEPLOY_PATH"
                        '''
                        sh '''
                        ssh -i "$EC2_DEPLOY_KEY" ubuntu@"$EC2_IP" "chmod +x ${EC2_DEPLOY_PATH}/deploy.sh"
                        '''
                        sh '''
                        ssh -i "$EC2_DEPLOY_KEY" ubuntu@"$EC2_IP" "export HYOBIN_DB_ROOT_PASSWORD='$HYOBIN_DB_ROOT_PASSWORD'; export HYOBIN_DB_USER_NAME='$HYOBIN_DB_USER_NAME'; export HYOBIN_DB_USER_PASSWORD='$HYOBIN_DB_USER_PASSWORD'; export PROJECT_NAME='$PROJECT_NAME'; chmod +x ${EC2_DEPLOY_PATH}/set-up-docker.sh && ${EC2_DEPLOY_PATH}/set-up-docker.sh"
                        '''
                        sh '''
                        ssh -i "$EC2_DEPLOY_KEY" ubuntu@"$EC2_IP" "export HYOBIN_DOCKER_HUB_USER_NAME='$HYOBIN_DOCKER_HUB_USER_NAME'; export HYOBIN_DB_USER_NAME='$HYOBIN_DB_USER_NAME'; export HYOBIN_DB_USER_PASSWORD='$HYOBIN_DB_USER_PASSWORD'; export PROJECT_NAME='$PROJECT_NAME'; export PROJECT_VERSION='$PROJECT_VERSION'; ${EC2_DEPLOY_PATH}/deploy.sh"
                        '''
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts:"build/libs/*.jar", fingerprint:true
                echo 'Artifacts archived'
            }
        }

    }
}
