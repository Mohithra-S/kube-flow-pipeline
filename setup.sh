#!/usr/bin/env bash
# =============================================================
#  setup.sh — One-shot local Kubernetes CI/CD environment setup
#  Run this AFTER downloading the project folder.
# =============================================================
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error() { echo -e "${RED}[ERR]${NC}   $1"; exit 1; }
step()  { echo -e "\n${GREEN}━━━ $1 ━━━${NC}"; }

# ── Detect OS ─────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[[ "$ARCH" == "x86_64" ]] && ARCH="amd64"
[[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]] && ARCH="arm64"

step "1/6  Checking prerequisites"

need() {
  command -v "$1" &>/dev/null && info "$1 found" || {
    warn "$1 not found — installing..."
    install_$1
  }
}

install_docker() {
  if [[ "$OS" == "linux" ]]; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    warn "Docker installed. You may need to log out and back in, or run: newgrp docker"
  else
    error "Please install Docker Desktop from https://www.docker.com/products/docker-desktop/"
  fi
}

install_minikube() {
  info "Installing Minikube..."
  if [[ "$OS" == "linux" ]]; then
    curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}"
    sudo install "minikube-linux-${ARCH}" /usr/local/bin/minikube
    rm "minikube-linux-${ARCH}"
  elif [[ "$OS" == "darwin" ]]; then
    brew install minikube || curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-${ARCH}" && sudo install "minikube-darwin-${ARCH}" /usr/local/bin/minikube
  else
    error "Windows: install Minikube from https://minikube.sigs.k8s.io/docs/start/"
  fi
}

install_kubectl() {
  info "Installing kubectl..."
  KUBECTL_VER=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VER}/bin/${OS}/${ARCH}/kubectl"
  sudo install kubectl /usr/local/bin/kubectl
  rm kubectl
}

need docker
need minikube
need kubectl

step "2/6  Starting Minikube"
if minikube status | grep -q "Running"; then
  info "Minikube already running"
else
  minikube start \
    --cpus=2 \
    --memory=4096 \
    --disk-size=20g \
    --driver=docker
  info "Minikube started ✓"
fi

minikube addons enable ingress 2>/dev/null || true

step "3/6  Installing ArgoCD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

info "Waiting for ArgoCD pods (this takes ~2 minutes)..."
kubectl wait --for=condition=Ready pods \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd --timeout=180s

step "4/6  Deploying the app directly to Kubernetes"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
info "Waiting for app pods..."
kubectl wait --for=condition=Ready pods \
  -l app=k8s-cicd-app --timeout=120s || {
  warn "Pods not ready yet — they may still be pulling the image. Run:"
  echo "  kubectl get pods -w"
}

step "5/6  Getting access info"

ARGOCD_PASS=$(kubectl get secret argocd-initial-admin-secret \
  -n argocd -o jsonpath="{.data.password}" | base64 --decode)

APP_URL=$(minikube service k8s-cicd-app --url 2>/dev/null || echo "run: minikube service k8s-cicd-app --url")

echo ""
echo -e "${GREEN}┌──────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│           🎉  Setup Complete!                        │${NC}"
echo -e "${GREEN}├──────────────────────────────────────────────────────┤${NC}"
echo -e "${GREEN}│${NC}  App URL      : ${YELLOW}${APP_URL}${NC}"
echo -e "${GREEN}│${NC}  ArgoCD UI    : ${YELLOW}https://localhost:8080${NC}"
echo -e "${GREEN}│${NC}  ArgoCD user  : ${YELLOW}admin${NC}"
echo -e "${GREEN}│${NC}  ArgoCD pass  : ${YELLOW}${ARGOCD_PASS}${NC}"
echo -e "${GREEN}└──────────────────────────────────────────────────────┘${NC}"

step "6/6  Forwarding ArgoCD UI (keep this terminal open)"
echo ""
echo "  ArgoCD is available at → https://localhost:8080"
echo "  Press Ctrl+C to stop port-forwarding"
echo ""
kubectl port-forward svc/argocd-server -n argocd 8080:443
