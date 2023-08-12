# swap disable

#### swap off
```sh
sudo swapoff -a
```

#### /etc/fstab swap mount 제거
/swap.img 주석 처리
```sh
sudo vi /etc/fstab
```
```text
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/sda2 during curtin installation
/dev/disk/by-uuid/e9b86b30-7956-41c1-afae-cf5974dffbe2 / ext4 defaults 0 1
#/swap.img       none    swap    sw      0       0
↑ 주석 추가
```

확인 (MiB Swap 확인)
```sh
top
```
```text
top - 07:52:40 up 16:36,  2 users,  load average: 0.00, 0.00, 0.00
Tasks: 125 total,   1 running, 124 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.1 us,  0.2 sy,  0.0 ni, 99.8 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7927.5 total,   7143.8 free,    210.7 used,    573.0 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   7476.6 avail Mem
               ↑↑↑ 여기

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   1842 root      20   0    7872   3672   3084 R   0.7   0.0   0:00.05 top
   1539 ysic      20   0   17168   8160   5668 S   0.3   0.1   0:00.58 sshd
      1 root      20   0  165908  11396   8376 S   0.0   0.1   0:04.81 systemd
      2 root      20   0       0      0      0 S   0.0   0.0   0:00.02 kthreadd
      3 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 rcu_gp
...
...
```

#### 커널 파라미터 수정
* vm.swappiness=0 : swap 미사용
* vm.swappiness=1 : 스왑사용 최소화
* vm.swappiness=60 : 기본
* vm.swappiness=100 : 적극적으로 스왑 사용

#### 임시 적용
```sh
sudo sysctl vm.swappiness=0
```

#### 영구 적용
```sh
sudo vi /etc/sysctl.conf
```

```text
...
...
vm.swappiness=0
...
...
```

#### 적용 확인
```sh
cat /proc/sys/vm/swappiness
```
```text
0
```
또는
```sh
sysctl -a | grep swappiness
```
```
vm.swappiness = 0
```
