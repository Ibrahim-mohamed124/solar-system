# 🌍 Solar System CI/CD Pipeline

A fully integrated DevSecOps environment leveraging Jenkins, SonarQube, Gitea, AWS, Kubernetes, and ArgoCD for automated testing, deployment, and delivery.

---

## 🛠️ Required Infrastructure

This setup assumes the following components are provisioned and accessible:

### 🧩 Core Components

| Component                          | Description                                 |
|-----------------------------------|---------------------------------------------|
| Jenkins Server                    | CI pipeline orchestrator                    |
| Linux Machine                     | Agent with essential tools installed        |
| ⬜ Docker                         | Container runtime                           |
| ⬜ Trivy CLI                      | Security scanning tool                      |
| ⬜ Java 21                        | Java runtime for plugins/tools              |
| ⬜ AWS CLI                        | Command-line access to AWS services         |
| ⬜ Git                            | Source code management                      |
| SonarQube Server                 | Static code analysis                        |
| Gitea Server                     | Lightweight Git hosting                     |
| AWS EC2 Instance                 | Continuous deployment target                |
| Kubernetes Cluster w/ ArgoCD     | Continuous delivery platform                |
| AWS Lambda Function              | Production logic (for learning purposes)    |

---

## 🔌 Jenkins Configuration

### 🔧 Plugins Used

| Plugin Name                          | Purpose                                |
|-------------------------------------|----------------------------------------|
| AWS Steps / Credentials             | AWS integrations                       |
| Bitbucket Branch Source             | Branch discovery                       |
| Copy Artifact                       | Artifact handling                      |
| Docker Pipeline                     | Docker workflows                       |
| Gitea Plugin                        | Git hosting integration                |
| GitHub Authentication               | Auth support                           |
| HTML Publisher                      | Test result visualization              |
| JUnit Plugin                        | JUnit test reporting                   |
| Kubernetes DevOps Steps             | K8s operations within pipelines        |
| OWASP Dependency-Check              | Vulnerability detection                |
| S3 Publisher                        | Artifact storage                       |
| SonarQube Scanner                   | Code quality checks                    |
| SSH Agent / SSH Plugin              | Secure remote execution                |
| Timestamper                         | Log timestamping                       |

### 🧰 Jenkins Tools Installed

| Tool Name                  | Description                                |
|---------------------------|--------------------------------------------|
| Node.js v18.20.8          | For running JavaScript-based components    |
| SonarQube
