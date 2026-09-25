# MSc DE1 - Distributed Systems
## Docker & Local Kubernetes Project

This project demonstrates the containerization, security, publication and local Kubernetes orchestration of an existing Flask REST API.

The original application comes from the following starter repository:

https://github.com/ubc/flask-sample-app

The objective was not to redesign the application, but to build a clean, secure and reproducible Docker and Kubernetes workflow.

---

## 1. Project Objectives

The project covers the following steps:

- Run and test the original Flask application locally
- Containerize the application with Docker
- Apply container security best practices
- Run the application with Docker Compose
- Inspect the Docker image
- Scan the image for vulnerabilities
- Generate a Software Bill of Materials (SBOM)
- Publish the image to Docker Hub
- Deploy the image to a local Kubernetes cluster with kind
- Demonstrate replication, service discovery, self-healing and scaling
- Demonstrate a rolling update and rollback
- Apply Kubernetes security controls

---

## 2. Architecture

```text
Flask REST API
      |
      v
Docker Image
      |
      +------------------+
      |                  |
      v                  v
Docker Compose       Docker Hub
                         |
                         v
                 kind Kubernetes Cluster
                         |
          +--------------+--------------+
          |                             |
   Control Plane                  2 Worker Nodes
                                        |
                                        v
                                Flask Deployment
                                   2 replicas
                                        |
                                        v
                                ClusterIP Service
```

Kubernetes namespace:

```text
msc-de1-project
```

---

## 3. Repository Structure

```text
msc-de1-distributed-systems-docker-k8s/
│
├── app/
│   ├── __init__.py
│   └── routes.py
│
├── tests/
│   ├── __init__.py
│   └── test_app.py
│
├── Dockerfile
├── .dockerignore
├── compose.yaml
├── requirements.txt
├── run.py
│
├── kind/
│   └── kind-config.yaml
│
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── network-policy.yaml
│
├── security/
│   ├── vulnerability-scan.txt
│   └── sbom.spdx
│
├── evidence/
│   └── screenshots
│
├── README.md
├── .gitignore
└── LICENSE
```

---

## 4. Prerequisites

Required tools:

- Git
- Python 3
- Docker Desktop
- Docker Compose
- kubectl
- kind

Verify the tools:

```powershell
git --version
python --version
docker --version
docker compose version
kubectl version --client
kind version
```

---

# Local Application

## 5. Run the Original Application

Create a virtual environment:

```powershell
python -m venv .venv
```

Activate it on Windows:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install the dependencies:

```powershell
python -m pip install -r requirements.txt
```

Run the application:

```powershell
python run.py
```

The application is available at:

```text
http://127.0.0.1:5000
```

---

## 6. API Routes

### Root

```http
GET /
```

Response:

```text
Hello, Flask!
```

### List items

```http
GET /items
```

### Get one item

```http
GET /items/<item_id>
```

Example:

```text
http://127.0.0.1:5000/items/0
```

### Add an item

```http
POST /items
```

The application stores items in memory.

Therefore, application data is reset when the application process or pod restarts.

---

## 7. Unit Tests

Run the tests with:

```powershell
python -m unittest discover tests
```

Expected result:

```text
Ran 4 tests
OK
```

The original application was tested successfully before containerization.

Evidence is stored in:

```text
evidence/baseline-tests.png
```

---

# Docker

## 8. Build the Docker Image

The final image uses:

```text
python:3.12-slim
```

Build:

```powershell
docker build -t abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0 .
```

Run:

```powershell
docker run --name flask-app -p 5000:5000 abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Test:

```text
http://127.0.0.1:5000/
```

```text
http://127.0.0.1:5000/items
```

---

## 9. Docker Security

The Docker image applies the following security practices:

- Official slim Python base image
- Dedicated non-root user
- Application runs as UID/GID `999`
- No secrets included in the image
- pip cache disabled
- Minimal runtime files copied
- `.dockerignore` excludes unnecessary content
- Only port `5000` is exposed
- Docker healthcheck configured

Verify the runtime user:

```powershell
docker exec <container-name> whoami
```

Expected result:

```text
appuser
```

The UID/GID can also be verified with:

```powershell
docker exec <container-name> id
```

---

## 10. Docker Healthcheck

The image includes a Docker healthcheck against the Flask root endpoint.

Check container status:

```powershell
docker ps
```

A healthy container should display:

```text
(healthy)
```

---

## 11. Docker Image Inspection

Check the image size:

```powershell
docker images abdelhadialaouibalghiti/msc-de1-flask-app
```

Inspect image layers:

```powershell
docker history abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Inspect configured user:

```powershell
docker inspect --format='User={{.Config.User}}' abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Inspect exposed ports:

```powershell
docker inspect --format='Ports={{json .Config.ExposedPorts}}' abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

---

# Docker Compose

## 12. Local Execution with Compose

The project contains a single-service `compose.yaml`.

Start:

```powershell
docker compose up --build
```

Check status:

```powershell
docker compose ps
```

View logs:

```powershell
docker compose logs
```

Stop and clean:

```powershell
docker compose down
```

The Compose configuration includes:

- Application build
- Image name `flask-sample-app:local`
- Port mapping `5000:5000`
- Healthcheck inherited from the Docker image
- Non-root execution
- `no-new-privileges`
- All Linux capabilities dropped
- No privileged mode
- No Docker socket mount
- No host networking

---

# Container Security

## 13. Vulnerability Scan

Docker Scout was used to scan the final image:

```text
abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Final scan summary:

```text
CRITICAL: 0
HIGH:     2
MEDIUM:   7
LOW:      27
```

The initial image contained more HIGH vulnerabilities.

The Python base image was updated to a newer Python 3.12 slim variant, reducing the HIGH findings.

The remaining HIGH findings were associated with Debian packages for which Docker Scout reported no fixed version at the time of the scan.

Full scan:

```text
security/vulnerability-scan.txt
```

---

## 14. Software Bill of Materials

An SPDX Software Bill of Materials was generated for the final image.

File:

```text
security/sbom.spdx
```

---

# Docker Hub

## 15. Published Image

Docker Hub image:

```text
abdelhadialaouibalghiti/msc-de1-flask-app
```

Published tags:

```text
1.0.0
latest
```

Pull the final image:

```powershell
docker pull abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Run the pulled image:

```powershell
docker run --name dockerhub-test -p 5000:5000 abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

The published image was pulled again from Docker Hub and verified locally.

---

# Kubernetes

## 16. Create the kind Cluster

Cluster configuration:

```text
kind/kind-config.yaml
```

Topology:

```text
1 control-plane
2 worker nodes
```

Create the cluster:

```powershell
kind create cluster --name msc-de1 --config kind/kind-config.yaml
```

Verify:

```powershell
kubectl get nodes -o wide
```

---

## 17. Deploy Kubernetes Resources

Apply all manifests:

```powershell
kubectl apply -f k8s/
```

The project deploys:

- Namespace
- Deployment
- Service
- NetworkPolicy

Verify:

```powershell
kubectl get all -n msc-de1-project
```

Verify NetworkPolicy:

```powershell
kubectl get networkpolicy -n msc-de1-project
```

---

## 18. Deployment

Deployment name:

```text
flask-app
```

Namespace:

```text
msc-de1-project
```

Image:

```text
abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

Replica count:

```text
2
```

The Deployment also includes:

- Readiness probe
- Liveness probe
- CPU request: `100m`
- Memory request: `64Mi`
- CPU limit: `500m`
- Memory limit: `128Mi`
- RollingUpdate strategy
- `maxSurge: 1`
- `maxUnavailable: 0`

Check pods:

```powershell
kubectl get pods -n msc-de1-project -o wide
```

---

## 19. Kubernetes Security

Pod security settings:

```text
runAsNonRoot: true
runAsUser: 999
runAsGroup: 999
seccompProfile: RuntimeDefault
```

Container security settings:

```text
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
```

All Linux capabilities are dropped.

The deployment does not use:

- privileged mode
- host networking
- host PID
- host IPC
- hostPath volumes
- Docker socket mounting

---

## 20. Kubernetes Service

Service:

```text
flask-app-service
```

Type:

```text
ClusterIP
```

Ports:

```text
Service port: 80
Target port: 5000
```

Check:

```powershell
kubectl get svc -n msc-de1-project
```

Check endpoints:

```powershell
kubectl get endpoints -n msc-de1-project
```

---

## 21. Access the Application

Use port forwarding:

```powershell
kubectl port-forward -n msc-de1-project service/flask-app-service 8080:80
```

Open:

```text
http://127.0.0.1:8080/
```

or:

```text
http://127.0.0.1:8080/items
```

Stop port forwarding with:

```text
Ctrl+C
```

---

## 22. NetworkPolicy

The NetworkPolicy selects:

```text
app: flask-app
```

It allows ingress traffic to:

```text
TCP port 5000
```

Other ingress ports to the selected pods are not allowed by this policy.

### Limitation

The default kind networking configuration may not enforce Kubernetes NetworkPolicy.

A NetworkPolicy-aware CNI such as Calico or Cilium would be required for full enforcement.

---

# Distributed Systems Demonstrations

## 23. Replication and Service Discovery

The application runs with two replicas.

Verify:

```powershell
kubectl get pods -n msc-de1-project -o wide
```

The Kubernetes Service selects the application pods and provides a stable service abstraction.

---

## 24. Self-Healing

Delete one running pod:

```powershell
kubectl delete pod <pod-name> -n msc-de1-project
```

Watch the state:

```powershell
kubectl get pods -n msc-de1-project -w
```

The Deployment automatically creates a replacement pod to restore the desired replica count.

This demonstrates Kubernetes desired-state reconciliation and self-healing.

---

## 25. Scaling

Scale from 2 replicas to 3:

```powershell
kubectl scale deployment flask-app --replicas=3 -n msc-de1-project
```

Verify:

```powershell
kubectl get pods -n msc-de1-project
```

Return to the final replica count:

```powershell
kubectl scale deployment flask-app --replicas=2 -n msc-de1-project
```

---

## 26. Rolling Update

A temporary `1.0.1` version of the application was created specifically to demonstrate Kubernetes rolling updates.

Update the Deployment:

```powershell
kubectl set image deployment/flask-app flask-app=abdelhadialaouibalghiti/msc-de1-flask-app:1.0.1 -n msc-de1-project
```

Monitor:

```powershell
kubectl rollout status deployment/flask-app -n msc-de1-project
```

View history:

```powershell
kubectl rollout history deployment/flask-app -n msc-de1-project
```

The `1.0.1` application change was temporary and used only for the rolling-update demonstration.

---

## 27. Rollback

Rollback to the previous revision:

```powershell
kubectl rollout undo deployment/flask-app -n msc-de1-project
```

Verify:

```powershell
kubectl rollout status deployment/flask-app -n msc-de1-project
```

The final deployment uses:

```text
abdelhadialaouibalghiti/msc-de1-flask-app:1.0.0
```

The repository application source was also restored to the final `1.0.0` behavior after the demonstration.

---

# Cleanup

## 28. Delete Kubernetes Resources

Delete all project manifests:

```powershell
kubectl delete -f k8s/
```

Or delete the namespace:

```powershell
kubectl delete namespace msc-de1-project
```

---

## 29. Delete the kind Cluster

```powershell
kind delete cluster --name msc-de1
```

---

# Evidence

Technical evidence is stored in:

```text
evidence/
```

It contains screenshots covering:

- baseline execution
- unit tests
- Docker build
- container execution
- container logs
- non-root execution
- healthcheck
- image inspection
- vulnerability scans
- Docker Compose
- Docker Hub publication
- kind cluster
- Kubernetes Deployment
- Kubernetes Service
- service discovery
- security context
- NetworkPolicy
- self-healing
- scaling
- rolling update
- rollback

---

# Known Limitations

This project is designed for local academic demonstration rather than production use.

Current limitations include:

- Flask's built-in development server is used instead of a production WSGI server
- Application data is stored only in memory
- Data is lost when the process or pod restarts
- Data is not shared between replicas
- No persistent database is configured
- The Kubernetes Service is `ClusterIP`
- Host access requires port forwarding
- NetworkPolicy restricts the destination port but not the source
- kind may require a different CNI for actual NetworkPolicy enforcement
- No external secrets manager is configured
- No Ingress or TLS termination is configured

---

# Conclusion

This project demonstrates the complete lifecycle of a simple REST API from local execution to secure containerization and local Kubernetes orchestration.

The main concepts demonstrated include:

- Docker image creation
- Layer optimization
- Non-root execution
- Container health checks
- Docker Compose
- Vulnerability analysis
- SBOM generation
- Docker Hub publication
- Kubernetes multi-node orchestration
- Replication
- Service discovery
- Desired-state reconciliation
- Self-healing
- Resource management
- Security contexts
- NetworkPolicy
- Scaling
- Rolling updates
- Rollback

For a production deployment, possible improvements would include a production WSGI server, persistent database, Ingress with TLS, centralized observability, external secrets management and a NetworkPolicy-aware CNI.