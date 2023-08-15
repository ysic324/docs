# Kubernetes 설치

* 2023.08.11 작성
* ubuntu 버전 : Ubuntu 22.04.3 LTS
* Kubernetes 버전 : v1.27.4

Master Node와 Worker Node로 구성, 각각의 노드는 최소한 1개씩 필요

Master Node : 작업을 할당, 스케줄링 등의 메인역할

Worker Node : Pod를 할당받고 실제 Pod들을 띄워주는 역할, 네트워크나 볼륨에 대한 기능도 컨트롤

## 최소 Spec
2CPU, 2GB RAM

## 기본 설정
> 모든 서버에서 작업


### /etc/hosts 에 Master Node, Worker Node 추가
```shell
vi /etc/hosts
````
```text
192.168.0.51    server-01
192.168.0.52    server-02
192.168.0.53    server-03
```

### br_netfilter 모듈 적재
```shell
lsmod | grep br_netfilter
```
```text
br_netfilter           32768  0
bridge                307200  1 br_netfilter
```

적재된 모듈이 없는 경우
```shell
modprobe br_netfilter
```

재시작시 자동 반영을 위한 설정 추가
```shell
vi /etc/modules-load.d/modules.conf
```
```text
...
...
br_netfilter
...
...
```

### swap disable
kubernetes는 Pod를 생성할 때,
필요한 만큼의 리소스(Core, Memory등)를 할당받아 사용하며, swap은 고려하지 않으므로 비활성화.
[swap disable](../../swap제거.md).

### 커널 파라미터 수정

```shell
vi /etc/sysctl.conf
```

커널 파라미터 추가
```text
...
...
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
...
...
```

수정된 커널 파라미터 적용
```shell
sysctl -p
```


### docker의 cgroup driver 변경(cgroupfs ->  systemd)
#### 변경 전
```
docker info | grep -i cgroup
```
```
 Cgroup Driver: cgroupfs <- 여기 확인
 Cgroup Version: 2
  cgroupns
```

#### daemon.json 파일 생성
```
vi /etc/docker/daemon.json
```
```
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
```

#### docker 재시작
```shell
systemctl restart docker
```

#### 변경된 cgroup driver 확인
```
docker info | grep -i cgroup
```
```
 Cgroup Driver: systemd <- systemd로 변경되었는지 확인
 Cgroup Version: 2
  cgroupns
```

## Kubernetes 공식 GPG key 추가 및 Repository 등록
#### GPG key 추가
```shell
# keyrings 디렉토리 생성 (docker 설정시 생성한 경우 불필요)
install -m 0755 -d /etc/apt/keyrings

# GPG key 파일 download
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes.gpg

# GPG 파일 속성 변경(모든 사용자 read 권한 부여)
chmod a+r /etc/apt/keyrings/kubernetes.gpg
```

#### Repository 등록
```shell
echo "deb [signed-by=/etc/apt/keyrings/kubernetes.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
```

#### 패키지 업데이트
```shell
apt update
```

## Kubernetes 설치
```shell
apt install kubelet kubeadm kubectl
```
#### 패키지가 자동으로 설치, 업그레이드, 제거되지 않도록 hold
```shell
apt-mark hold kubelet kubeadm kubectl
```

#### 설치 확인
```shell
kubeadm version
kubelet --version
kubectl version
```

## 쿠버네티스 구성
### 쿠버네티스 리셋
쿠버네티스 관련 데몬 중지 및 설정 초기화
```shell
kubeadm reset
```

### 쿠버네티스 초기화 (Master Node)
옵션 --pod-network-cidr 에 대한 의견
* 192.168.0.x 망을 쓰는 경우 pod-network-cidr은 10.244.0.0/16 이용 (집 공유기인 경우)
* 10.x.x.x 망을 쓰는 경우 pod-network-cidr은 192.168.0.0/16 이용 (회사 내부망이 10.x.x.x 인 경우)

```shell
kubeadm init --apiserver-advertise-address 192.168.0.51 \
             --pod-network-cidr=10.244.0.0/16
```

containerd.sock 파일을 직접 지정 하는 경우 
```shell
kubeadm init --apiserver-advertise-address 192.168.0.51 \
             --pod-network-cidr=10.244.0.0/16 \
             --cri-socket unix:///var/run/containerd/containerd.sock
```

정상적으로 실행되면 아래와 같은 명령어가 출려됨. 이를 어딘가에 잘 적어둠
```text
...
...
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.51:6443 --token fmna8s.z0zorxiemsjg5b2s \
        --discovery-token-ca-cert-hash sha256:536d050b4df6b20e2c2fd5ac2369ec0148961ae0551f7e6273d87a776b39f904
```

### Worker-node 추가
각 Worker-node 에서 실행
```shell
kubeadm join 192.168.0.51:6443 --token fmna8s.z0zorxiemsjg5b2s \
        --discovery-token-ca-cert-hash sha256:536d050b4df6b20e2c2fd5ac2369ec0148961ae0551f7e6273d87a776b39f904
```


```
kubectl get nodes
kubectl get nodes --kubeconfig /etc/kubernetes/admin.conf

```



### CNI(Container Network Interface) plugin 추가









TODO 이건 뭔내용이냐?

cluster 관리를 위한 kubeadm initialize 및 kubectl 사용을 위한 config
```shell
kubeadm init
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```





--- ----------------------------------------------------------------------------



### Pod 네트워크 애드온 설치
쿠버네티스 1.24부터는 Docker Container Runtime이 쿠버네티스와 호환되지 않아 cri-dockerd 설치가 추가로 필요하다.
cri-dockerd



#### 마스터 노드 생성 및 실행
```shell
# --apiserver-advertise-address = 현재 서버의 IP주소
# --pod-network-cidr=10.244.0.0/16
kubeadm init --apiserver-advertise-address=192.168.0.51 --pod-network-cidr=10.244.0.0/16
```

아래와 같은 에러가 발생하는 경우 docker 대신에 containerd 로 기본 값이 잡힌 것으로 추측? 
```text
[init] Using Kubernetes version: v1.27.4
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR CRI]: container runtime is not running: output: time="2023-08-12T23:32:51+09:00" level=fatal msg="validate service connection: CRI v1 runtime API is not implemented for endpoint \"unix:///var/run/containerd/containerd.sock\": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService"
, error: exit status 1
[preflight] If you know what you are doing, you can make a check non-fatal with `--ignore-preflight-errors=...`
To see the stack trace of this error execute with --v=5 or higher
```



--- ----------------------------------------------------------------------------
systemctl stop docker
 vi /etc/containerd/config.toml

/etc/containerd/config.toml에서 disabled_plugins 라인을 비활성화하여 CRI 인터페이스를 활성화합니다.
#disabled_plugins = ["cri"]


systemctl restart containerd



```shell
kubeadm init
```
```text
[init] Using Kubernetes version: v1.27.4
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'


W0813 12:16:09.056657   39115 checks.go:835] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm. It is recommended that using "registry.k8s.io/pause:3.9" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local server-01] and IPs [10.96.0.1 192.168.0.51]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [localhost server-01] and IPs [192.168.0.51 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [localhost server-01] and IPs [192.168.0.51 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 28.012529 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node server-01 as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node server-01 as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: hd21ct.0z8yrpqel2192s20
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.51:6443 --token hd21ct.0z8yrpqel2192s20 \
        --discovery-token-ca-cert-hash sha256:c998410d6e4d1a49d6d6ca08ca98236b580904f8bab8fa646692e2c336831ff4
```

```shell
kubeadm join 192.168.0.51:6443 --token hd21ct.0z8yrpqel2192s20 \
        --discovery-token-ca-cert-hash sha256:c998410d6e4d1a49d6d6ca08ca98236b580904f8bab8fa646692e2c336831ff4
```
