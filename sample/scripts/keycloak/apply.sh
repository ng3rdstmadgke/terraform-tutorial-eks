#!/bin/bash

set -eu

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR/../..; pwd)

cd $SCRIPT_DIR


SECURITY_GROUP_NAME=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/charts output -raw alb_ingress_sg)
NAMESPACE=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/keycloak output -raw namespace)
SERVICE_ACCOUNT=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/keycloak output -raw service_account)
USER_SECRET_NAME=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/keycloak output -raw keycloak_user_secret)
DB_SECRET_NAME=$(terraform -chdir=$PROJECT_DIR/terraform/envs/dev/keycloak output -raw keycloak_db_secret)

mkdir -p ${SCRIPT_DIR}/tmp

cat <<EOF > ${SCRIPT_DIR}/tmp/app.yaml
---
#
# Keycloakのデータベース接続情報をSecrets Managerから取得する
#
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: keycloak-db-spc
  namespace: ${NAMESPACE}
spec:
  provider: aws
  secretObjects:
    - secretName: keycloak-db-secret
      type: Opaque
      data:
        - key: kc_db_host
          objectName: alias_db_host
        - key: kc_db_port
          objectName: alias_db_port
        - key: kc_db_user
          objectName: alias_db_user
        - key: kc_db_password
          objectName: alias_db_password
        - key: kc_db_name
          objectName: alias_db_name
  parameters:
    # jmesPathを利用する場合JSONの値はString型である必要がある
    objects: |
        - objectName: "${DB_SECRET_NAME}"
          objectType: "secretsmanager"
          jmesPath:
            - path: db_host
              objectAlias: alias_db_host
            - path: db_port
              objectAlias: alias_db_port
            - path: db_user
              objectAlias: alias_db_user
            - path: db_password
              objectAlias: alias_db_password
            - path: db_name
              objectAlias: alias_db_name
---
#
# Keycloakの管理ユーザログイン情報をSecrets Managerから取得する
#
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: keycloak-user-spc
  namespace: ${NAMESPACE}
spec:
  provider: aws
  secretObjects:
    - secretName: keycloak-user-secret
      type: Opaque
      data:
        - key: keycloak_admin
          objectName: alias_user
        - key: keycloak_admin_password
          objectName: alias_password
  parameters:
    objects: |
        - objectName: "${USER_SECRET_NAME}"
          objectType: "secretsmanager"
          jmesPath:
            - path: user
              objectAlias: alias_user
            - path: password
              objectAlias: alias_password
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: ${NAMESPACE}
  labels:
    app: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      serviceAccountName: ${SERVICE_ACCOUNT}

      volumes:
        - name: keycloak-user-secret-volume
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: keycloak-user-spc
        - name: keycloak-db-secret-volume
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: keycloak-db-spc
      containers:
        - name: keycloak
          image: quay.io/keycloak/keycloak:25.0.1
          args: ["start"]
          env:
            # All Configuration | Keycloak: https://www.keycloak.org/server/all-config
            - name: KC_PROXY_HEADERS  # リバースプロキシを利用する場合の設定: https://www.keycloak.org/server/reverseproxy
              value: "xforwarded"
            - name: KEYCLOAK_ADMIN
              valueFrom:
                secretKeyRef:
                  name: keycloak-user-secret
                  key: keycloak_admin
            - name: KEYCLOAK_ADMIN_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-user-secret
                  key: keycloak_admin_password
            - name: KC_DB
              value: "mysql"
            - name: KC_DB_URL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: keycloak-db-secret
                  key: kc_db_name
            - name: KC_DB_URL_HOST
              valueFrom:
                secretKeyRef:
                  name: keycloak-db-secret
                  key: kc_db_host
            - name: KC_DB_URL_PORT
              valueFrom:
                secretKeyRef:
                  name: keycloak-db-secret
                  key: kc_db_port
            - name: KC_DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: keycloak-db-secret
                  key: kc_db_user
            - name: KC_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: keycloak-db-secret
                  key: kc_db_password
            - name: KC_HOSTNAME_STRICT
              value: "false"
            - name: KC_HTTP_ENABLED  # プロダクションモードではHTTPが無効になるので、明示的にHTTPを有効にする
              value: "true"
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /realms/master
              port: 8080
          volumeMounts:
            - name: keycloak-user-secret-volume
              mountPath: /mnt/keycloak-user-secret-store
              readOnly: true
            - name: keycloak-db-secret-volume
              mountPath: /mnt/keycloak-db-secret-store
              readOnly: true
---
apiVersion: v1
kind: Service
metadata:
  name: keycloak-svc
  namespace: ${NAMESPACE}
  labels:
    app: keycloak
spec:
  ports:
    - name: http
      port: 8080
      targetPort: 8080
  selector:
    app: keycloak
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-alb
  namespace: ${NAMESPACE}
  # Ingress annotations - AWS Load Balancer Controller
  # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/annotations/
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/tags: "PROJECT=TERRAFORM_TUTORIAL_EKS"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/security-groups: ${SECURITY_GROUP_NAME}
    alb.ingress.kubernetes.io/manage-backend-security-group-rules: "true"
    alb.ingress.kubernetes.io/healthcheck-path: /realms/master
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: keycloak-svc
                port:
                  number: 8080
EOF