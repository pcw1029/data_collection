# 1. DATA Collection 모듈
Data Collection 모듈은 rx_data[7:0] 핀으로부터 1바이트씩 들어온 데이터를 설정된 길이 만큼 모아 데이터를 분석하고, Block Memory의 특정 주소에 기록하는 모듈이다.

## 1.1. DATA Collection tracking_mode
DATA Collection tracking_mode는 총 4가지이며 아래와 같다.

* TRACKING_MODE 1	= 1
* TRACKING_MODE 2	= 2
* TRACKING_MODE 3  = 3
* TRACKING_MODE 4	= 4

## 1.2. DATA Collection input_data_length
DATA Collection input_data_length은 1바이트씩 들어오는 데이터를 얼마큼 모아 처리할지 결정하는 데이터 길이값이다.

추적 모드에 따라 설정 길이가 달라진다.

## 1.3. DATA Collection H/W Designe
<img src="./images/data_collection2.PNG?raw=true" width="150%"/>

## 1.4. DATA Collection simulation
DATA Collection 시뮬레이션 하기 전 single_bram_controller 모듈이 반드시 필요하며, github(https://github.com/pcw1029/single_bram_controller.git)에서 다운받을수 있다.

data_collection/create_project.tcl 실행 전 다운받은 single_bram_controller의 create_project.tcl을 실행 완료해야 한다.

## 1.5. DATA Collection simulation 결과
추적 모드는 1이며, 데이터 길이는 18이다.

데이터 길이만큼 데이터를 모으고, 모은 데이터의 특정 데이터를 Block Memory에 저장하며, 일정 시간 후 Block Memory에 저장된 데이터를 읽어온 결과이다.

<img src="./images/data_collection1.PNG?raw=true" width="150%"/>
