# https://mcr.microsoft.com/en-us/product/devcontainers/base/about
FROM mcr.microsoft.com/devcontainers/base:dev-ubuntu-24.04

RUN apt-get update && \
    apt-get install -y \
      sudo \
      locales \
      net-tools \
      iputils-ping \
      dnsutils \
      bash-completion \
      less \
      curl \
      wget \
      tar \
      xz-utils \
      unzip \
      make \
      gcc \
      git \
      vim \
      tmux \
      jq \
      yq \
      fzf \
      groff \
      procps \
      default-mysql-client \
      python3 \
      python3-pip

# ロケール設定
RUN echo 'ja_JP.UTF-8 UTF-8' >> /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=ja_JP.UTF-8
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# terraform インストール
# https://developer.hashicorp.com/terraform/install#linux
ENV TERRAFORM_VERSION=1.10.3
RUN wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
mv terraform /usr/local/bin/ && \
terraform -install-autocomplete

# aws cli インストール
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# kubectl インストール
# https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
RUN curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# helmインストール
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Argo CD CLI インストール
# https://argo-cd.readthedocs.io/en/stable/cli_installation/#download-with-curl
RUN curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 && \
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd && \
    rm argocd-linux-amd64