# 04. 리소스 계획 (GNS3 VM 22GB)

## 1. 측정값 (실제 RSS, 2026-10-21 측정)

GNS3 VM 쉘에서 `ps -eo rss,args --sort=-rss | grep qemu-system` 결과. 노드를 켠 직후 부팅이 끝난 상태의 값

| 노드 종류 | 노드당 실제 사용 | 대수 | 소계 |
|---|---|---|---|
| Arista vEOS | 첫 측정 약 2,040MB(할당 2048MB), RAM 축소 후 약 500 ~ 600MB | 8 | 약 16,300MB 또는 약 4,300MB (8대로 환산한 계산값) |
| Aruba CX | 약 1,750 ~ 1,850MB (할당 4096MB) | 3 | 약 5,350MB |
| Cisco IOSv (DSW1, DSW2, ASW1, MGMT-SW1, MGMT-SW2) | 약 400 ~ 440MB (MGMT-SW2는 할당 1024MB) | 5 | 약 2,100MB (5대로 환산한 계산값) |
| c7200 (Dynamips) (PE 3, Hub 2, BGW 2, MGMT-RTR) | 미측정 (대당 400MB로 가정, MGMT-RTR 할당 512MB) | 8 | 약 3,200MB (추정) |
| GNS3 VM 기본 | 약 1,000MB | - | 약 1,000MB |
| 호스트(Ubuntu Docker) (Host A~G, MGMT-PC1·2) | 미측정 | 9 | 미측정 |

- Arista의 낮은 값(500 ~ 600MB)은 RAM을 줄인 뒤의 측정. 설정(BGP, EVPN)을 넣은 뒤에도 유지되는지 확인되기 전에는 높은 값(2,040MB)으로 계획
- 안전하게 쓰려면 사용 합계를 약 19GB 이하로 유지하고, `available`이 2GB 아래로 내려가면 노드를 끔.
- 스왑 8GB를 만들어 두었음(`/etc/fstab` 등록). 스왑을 쓰기 시작하면 매우 느려지므로 안전장치로만 봄
- Juniper vQFX는 제외됨(측정값: PFE 약 1,120MB, RE 약 500MB).

- 2026-11-14 GNS3 VM 측정: 총 메모리 19,033MB 중 사용 17,608MB(약 92%), 스왑 4,260MB 사용, CPU 유휴 약 5%(`dynamips`와 `qemu-system-x86` 2개가 각각 약 90% 이상). 위 계획의 19GB 이하 기준을 넘은 상태
- 관리 노드(MGMT-SW1·SW2, MGMT-RTR, MGMT-PC1·2)는 관리망 구성과 검증 때만 켬. 평소에 켜 두면 자원이 부족해짐

## 2. 단계별로 켜는 노드

Arista를 높은 값(2,040MB)으로 가정한 보수적 계획

| 단계 | 켜는 노드 | 예상 합계 |
|---|---|---|
| 1. DC1 패브릭 | Arista 6, 호스트 A·B·C | 약 14GB |
| 2. 코어와 DC1 연동 | Arista 6, PE1·PE2·PE3, Host A·B·C | 약 15GB |
| 3. DC1 + DC2 | Arista 4(spine1, leaf1, leaf2, leaf3), PE1~PE3, Aruba 3 | 약 16GB |
| 4. Branch | Arista 3(spine1, leaf3, leaf4), c7200 7, IOSv 3 | 약 12GB |
| 5. 관리망(구성과 검증 때만) | MGMT-SW1·SW2, MGMT-RTR, MGMT-PC1·2를 해당 단계 노드에 더해서 켬 | 약 1.5GB 추가(IOSv 2, c7200 1, 호스트 2) |

- Arista RAM 축소가 안정적으로 확인되면 3단계에서 Arista 6대를 모두 켜는 것도 가능
- 단계가 바뀔 때는 이전 단계 노드를 모두 정지한 뒤 켬. 정지하지 않은 노드가 메모리를 계속 차지

## 3. 운영 규칙

1. 한 번에 2~3개씩 켜고, `watch -n 2 free -m`으로 `available`을 확인
2. `available`이 2GB 아래면 새 노드를 켜지 않음
3. 저장되지 않은 설정은 노드를 끄면 사라지므로 끄기 전에 `write memory`를 하고 설정을 파일로 저장
4. OOM이 발생했을 때의 징후: 콘솔에 "Out of memory: Killed process (qemu-system-x86)" 메시지. 이 경우 노드가 강제로 꺼진 것이므로 켜 둔 노드를 줄임
5. 호스트(Windows) 메모리는 VM이 미리 통째로 잡아 두므로 노드를 켠다고 늘지 않지만, 호스트에 여유가 적으니 무거운 프로그램은 피함

## 4. 이전 추정의 정정

- 처음에 "RAM 사용률 20%"라는 이전 프로젝트의 수치로 메모리가 병목이 아니라고 봤으나, 이번 구성은 vEOS가 할당 2GB를 거의 다 쓰는 구간이 있어 **메모리가 큰 제약**. (이전 프로젝트는 IOU와 c7200 위주였음.)
- 직전 OOM 로그에서 죽은 약 2.08GB짜리 QEMU 프로세스는 vQFX PFE가 아니라 **vEOS 노드**였을 가능성이 높음

- DC1에 border-leaf1, border-leaf2(vEOS, 각 2048MB 할당)가 추가되어 vEOS 노드가 8대가 됨. border leaf는 DC1 구축 단계에서 spine과 함께 켬
