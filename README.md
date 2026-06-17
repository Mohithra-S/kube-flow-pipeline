# 🚀 Kubernetes CI/CD Pipeline — Complete Project

A production-style GitOps pipeline using **GitHub Actions → Docker Hub → ArgoCD → Minikube**.

---

## 📁 Project Structure

```
k8s-cicd-project/
├── app/
│   ├── main.py            ← Flask web app
│   ├── requirements.txt   ← Python deps
│   └── Dockerfile         ← Container image
├── k8s/
│   ├── deployment.yaml    ← K8s Deployment (2 replicas)
│   ├── service.yaml       ← K8s Service (NodePort)
│   └── argocd-app.yaml    ← ArgoCD Application config
├── .github/
│   └── workflows/
│       └── ci.yaml        ← GitHub Actions pipeline
├── setup.sh               ← One-shot local setup script
└── README.md
```

---

## ✅ Prerequisites (install before anything)

| Tool | Install |
|------|---------|
| Docker Desktop | https://www.docker.com/products/docker-desktop/ |
| Minikube | https://minikube.sigs.k8s.io/docs/start/ |
| kubectl | https://kubernetes.io/docs/tasks/tools/ |
| Git | https://git-scm.com/downloads |

---

## 🏁 AFTER DOWNLOADING — Follow these steps exactly

### STEP 1 — Push this project to your own GitHub repo

```bash
# Go into the project folder
cd k8s-cicd-project

# Initialize git and push to YOUR GitHub
git init
git add .
git commit -m "initial: k8s cicd project"

# Create a new EMPTY repo on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/k8s-cicd-project.git
git branch -M main
git push -u origin main
```

---

### STEP 2 — Edit 2 files with your details

**File 1: `k8s/deployment.yaml`**
Find this line and replace `YOUR_DOCKERHUB_USERNAME`:
```yaml
# BEFORE:
image: YOUR_DOCKERHUB_USERNAME/k8s-cicd-app:latest

# AFTER (example):
image: johndoe/k8s-cicd-app:latest
```

**File 2: `k8s/argocd-app.yaml`**
Find this line and replace with your GitHub repo URL:
```yaml
# BEFORE:
repoURL: https://github.com/YOUR_GITHUB_USERNAME/k8s-cicd-project

# AFTER (example):
repoURL: https://github.com/johndoe/k8s-cicd-project
```

Then commit and push:
```bash
git add k8s/
git commit -m "config: set my docker and github details"
git push
```

---

### STEP 3 — Add GitHub Secrets

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** and add:

| Secret Name | Value |
|-------------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub token (get from hub.docker.com → Account Settings → Security → New Access Token) |

---

### STEP 4 — Run the setup script

```bash
# From inside the project folder:
bash setup.sh
```

This script will:
- ✅ Install Minikube + kubectl if missing
- ✅ Start your local Kubernetes cluster
- ✅ Install ArgoCD into the cluster
- ✅ Deploy the app
- ✅ Print your ArgoCD password and app URL
- ✅ Forward ArgoCD UI to https://localhost:8080

> **Keep that terminal open** for the ArgoCD UI. Open a new terminal for other commands.

---

### STEP 5 — Connect ArgoCD to your GitHub repo

After setup.sh finishes and ArgoCD is running:

```bash
# In a NEW terminal — apply the ArgoCD app config
kubectl apply -f k8s/argocd-app.yaml
```

Now open https://localhost:8080 in your browser:
- Username: `admin`
- Password: (printed by setup.sh — also run: `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode`)

You'll see your app appear and sync automatically! 🎉

---

### STEP 6 — Trigger the full CI/CD pipeline

Make a change to the app and push:

```bash
# Edit the app version
sed -i 's/Hello from Kubernetes!/Hello from Kubernetes! - Updated!/g' app/main.py

git add app/main.py
git commit -m "feat: update welcome message"
git push
```

**Watch what happens:**
1. GitHub Actions runs (go to your repo → **Actions** tab to watch live)
2. Docker image is built and pushed to Docker Hub
3. `deployment.yaml` is updated with the new image tag
4. ArgoCD detects the change and deploys automatically
5. Your app updates with zero downtime

---

## 🔍 Useful Commands

```bash
# See all running pods
kubectl get pods

# Watch pods in real time
kubectl get pods -w

# See pod logs
kubectl logs -l app=k8s-cicd-app --tail=50

# Get your app URL
minikube service k8s-cicd-app --url

# See ArgoCD app status
kubectl get applications -n argocd

# Describe a pod (debugging)
kubectl describe pod -l app=k8s-cicd-app

# Scale to 3 replicas manually
kubectl scale deployment k8s-cicd-app --replicas=3

# Restart all pods (rolling restart)
kubectl rollout restart deployment/k8s-cicd-app

# Check rollout status
kubectl rollout status deployment/k8s-cicd-app

# Stop Minikube (save resources when done)
minikube stop

# Delete everything and start fresh
minikube delete
```

---

## 🔁 How the Pipeline Works

```
You push code
     ↓
GitHub Actions triggers
     ↓
Tests run (pytest)
     ↓
Docker image built → pushed to Docker Hub
     ↓
deployment.yaml updated with new image tag
     ↓
ArgoCD detects Git change (polls every 3 min)
     ↓
ArgoCD syncs → Rolling update on Kubernetes
     ↓
New pods come up → Old pods terminate
     ↓
Zero-downtime deployment ✅
```

---

## 🛠 Troubleshooting

**Pods stuck in `Pending`:**
```bash
kubectl describe pod -l app=k8s-cicd-app
# Usually a resource issue — check: minikube status
```

**Pods stuck in `ImagePullBackOff`:**
```bash
# Your Docker Hub image doesn't exist yet — either:
# 1. Build it locally first:
cd app && docker build -t YOUR_USERNAME/k8s-cicd-app:latest .
docker push YOUR_USERNAME/k8s-cicd-app:latest
# 2. Or trigger the GitHub Actions pipeline first
```

**ArgoCD shows `OutOfSync`:**
```bash
# Manually sync:
kubectl patch application k8s-cicd-app -n argocd \
  --type merge -p '{"operation":{"sync":{}}}'
```

**Can't reach app URL:**
```bash
minikube service k8s-cicd-app --url
# If that fails:
kubectl port-forward svc/k8s-cicd-app 8888:80
# Then visit http://localhost:8888
```

---

## 🚀 Next Steps

- Add **Prometheus + Grafana** monitoring
- Add **staging namespace** for pre-prod testing
- Replace NodePort with **Ingress + TLS**
- Add **Helm charts** instead of raw YAML
- Add **Slack notifications** to the GitHub Actions workflow
