# IP 변경

## Ubuntu Linux

#### 설정파일 수정
```shell
sudo vi /etc/netplan/00-installer-config.yaml
```
```yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    enp2s0:
      addresses:
      - 192.168.0.53/24
      nameservers:
        addresses:
        - 192.168.0.1
        - 192.168.0.1
        search: []
      routes:
      - to: default
        via: 192.168.0.1
  version: 2
```

### 변경사항 적용
```shell
sudo netplan apply
```
