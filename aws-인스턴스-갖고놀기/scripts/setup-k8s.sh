#!/usr/bin/env bash

# k8s setting
swapoff -a # for k8s cluster

function setup_containerd {
  ## install containerd
  yum install -y containerd
  ### change configuration for containerd
  local CONTAINERD_CONFIG_PATH="/etc/containerd/config.toml"
  echo "version = 2" >>$CONTAINERD_CONFIG_PATH

  systemctl start containerd
}

function install_kubectl {
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  if [[ $? -ne 0 ]]; then
    echo "kubectl shasum does not matched!!!!" && exit 1
  fi
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  install bash-completion
  echo 'source /usr/share/bash-completion/bash_completion' >>~/.bashrc && source ~/.bashrc
  echo 'source <(kubectl completion bash)' >>~/.bashrc && source ~/.bashrc
}

# @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
function install_kubeadm {
  local CNI_PLUGINS_VERSION="v1.3.0"
  local ARCH="amd64"
  local DEST="/opt/cni/bin"
  mkdir -p "$DEST"
  curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | tar -C "$DEST" -xz

  DOWNLOAD_DIR="/usr/local/bin"
  mkdir -p "$DOWNLOAD_DIR"

  CRICTL_VERSION="v1.28.0"
  ARCH="amd64"
  curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | tar -C $DOWNLOAD_DIR -xz

  RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
  ARCH="amd64"
  cd $DOWNLOAD_DIR
  curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet}
  chmod +x {kubeadm,kubelet}

  RELEASE_VERSION="v0.16.2"
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
  mkdir -p /etc/systemd/system/kubelet.service.d
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

  systemctl enable --now kubelet
}

setup_containerd
install_kubectl
install_kubeadm
