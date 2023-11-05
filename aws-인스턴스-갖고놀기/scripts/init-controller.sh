#!/usr/bin/env bash

# this script is for Amazon Linux 2023 (may comfortable with RHEL)

hostnamectl set-hostname controller

PACKAGE_MANAGER=${PACKAGE_MANAGER:-"yum"}

${PACKAGE_MANAGER} update -y

# utility
${PACKAGE_MANAGER} install -y git htop

## Install oh-my-bash
curl -o install-omb.sh -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh

# k8s setting
swapoff -a # for k8s cluster

function setup_containerd {
  ## install containerd
  ${PACKAGE_MANAGER} install -y containerd
  ### change configuration for containerd
  mkdir -p /etc/containerd
  containerd config default | tee /etc/containerd/config.toml
  sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
  systemctl restart containerd
}

function install_kubectl {
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
  if [[ $? -ne 0 ]]; then
    echo "kubectl shasum does not matched!!!!" && exit 1
  fi
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  ${PACKAGE_MANAGER} install -y bash-completion
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

function some_setups {
  # some setups for fix 'kubeadm init'
  # warnings
  ${PACKAGE_MANAGER} install -y ethtool socat iproute-tc # 뭔지 하나도 모름
  ${PACKAGE_MANAGER} install -y conntrack iptables       # 이게 왜 없지...?

  modprobe br_netfilter # 여기부터 먼지 몰겟음 ㅋㅋ;;
  modprobe overlay

  cat <<-EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
  net.bridge.bridge-nf-call-iptables = 1
  net.ipv4.ip_forward = 1
  net.bridge.bridge-nf-call-ip6tables = 1
EOF
  sysctl --system

  # kubelet enable cgroup
  systemctl daemon-reload
  systemctl restart kubelet
}

function create_cluster {
  # get public ip
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/public-ipv4)

  # create cluster
  kubeadm init                                                              # --pod-network-cidr=10.0.0.0/24 --apiserver-advertise-address=$IP
  echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >>$HOME/.bash_profile # for root user kubectl

  # Install calico (network plugin) - 먼지 모름; https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
}

setup_containerd
install_kubectl
install_kubeadm

some_setups
