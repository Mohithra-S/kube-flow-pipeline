from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "v1.0.0")
POD_NAME = socket.gethostname()

@app.route("/")
def home():
    return f"""
    <html>
    <head>
      <title>K8s CI/CD App</title>
      <style>
        body {{ font-family: sans-serif; display: flex; justify-content: center;
               align-items: center; height: 100vh; margin: 0;
               background: linear-gradient(135deg, #1a1a2e, #16213e); color: white; }}
        .card {{ background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);
                border-radius: 16px; padding: 40px 60px; text-align: center; }}
        h1 {{ font-size: 2.5rem; margin-bottom: 8px; }}
        .badge {{ background: #4ade80; color: #052e16; padding: 4px 14px;
                 border-radius: 99px; font-size: 0.85rem; font-weight: 600; }}
        .info {{ margin-top: 20px; opacity: 0.6; font-size: 0.9rem; }}
      </style>
    </head>
    <body>
      <div class="card">
        <h1>🚀 Hello from Kubernetes!</h1>
        <span class="badge">{APP_VERSION}</span>
        <div class="info">
          <p>Pod: <code>{POD_NAME}</code></p>
          <p>Deployed via ArgoCD + GitHub Actions</p>
        </div>
      </div>
    </body>
    </html>
    """

@app.route("/health")
def health():
    return jsonify({"status": "ok", "version": APP_VERSION, "pod": POD_NAME})

@app.route("/api/info")
def info():
    return jsonify({
        "app": "k8s-cicd-demo",
        "version": APP_VERSION,
        "pod": POD_NAME,
        "message": "Deployed with GitOps!"
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
