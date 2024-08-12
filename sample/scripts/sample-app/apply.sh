#!/bin/bash

set -eu

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR/../..; pwd)

cd $SCRIPT_DIR


SECURITY_GROUP_NAME=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/charts output -raw alb_ingress_sg)

mkdir -p ${SCRIPT_DIR}/tmp

cat <<EOF > ${SCRIPT_DIR}/tmp/app.yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ingress-test-deploy
spec:
  selector:
    matchLabels:
      run: ingress-test-app
  template:
    metadata:
      labels:
        run: ingress-test-app
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: 128Mi
            cpu: 200m  # 1000m = 1 core
          requests:
            memory: 128Mi
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: ingress-test-svc
spec:
  ports:
  - port: 80
  selector:
    run: ingress-test-app
---
# Ingress | AWS Load Balancer Controller:
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-test-alb
  # Ingress annotations - AWS Load Balancer Controller
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/
  annotations:
    # インターネットに公開されるALB (kubernetes.io/role/elb=1 のタグが付与されているサブネットにALBが作成される)
    alb.ingress.kubernetes.io/scheme: internet-facing
    # ALBからのトラフィックをClusterIPを利用して直接Podにルーティングする (EKS Fargateの場合は ip でなければならない)
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/tags: "PROJECT=TERRAFORM_TUTORIAL_EKS"
    # リスナーのポートにhttp:80を指定
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    # ALBに設定するセキュリティグループ
    alb.ingress.kubernetes.io/security-groups: ${SECURITY_GROUP_NAME}
    # ALBに追加のバックエンドsgを追加する。Node, Podのセキュリティグループはバックエンドsgからのインバウンドトラフィックを許可する。
    alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ingress-test-svc
                port:
                  number: 80
EOF

kubectl apply -f ${SCRIPT_DIR}/tmp/app.yaml