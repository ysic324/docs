# Docker 설치

* 2023.08.11 작성
* ubuntu 버전 : Ubuntu 22.04.3 LTS
* Docker : 24.0.5

## 참고
* 참고사이트 : https://docs.docker.com/engine/install/ubuntu/#set-up-the-repository

## 필수 패키지 설치(skip)
```shell
sudo apt update
```
```shell
# sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
sudo apt-get install ca-certificates curl gnupg
```

## docker 공식 GPG key 추가 및 Repository 등록
#### GPG key 추가
```shell
# keyrings 디렉토리 생성
sudo install -m 0755 -d /etc/apt/keyrings

# GPG key 파일 download
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# GPG 파일 속성 변경(모든 사용자 read 권한 부여)
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

#### Repository 등록 
```shell
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 패키지 업데이트
```shell
sudo apt update
```


## docker 설치
```shell
sudo apt install docker-ce docker-ce-cli containerd.io
```

## docker service 상태 확인
```shell
sudo systemctl status docker
```

## docker reboot 시 자동 시작
```shell
sudo systemctl enable docker
```

## docker 실행
```shell
sudo systemctl start docker
```

## docker 중지
```shell
sudo systemctl stop docker
```

## docker 테스트
```shell
sudo docker run hello-world
```
```text
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
719385e32844: Pull complete
Digest: sha256:dcba6daec718f547568c562956fa47e1b03673dd010fe6ee58ca806767031d1c
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```
