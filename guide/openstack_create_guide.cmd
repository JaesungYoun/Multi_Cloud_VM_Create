@echo off

set OS_AUTH_URL=http://192.168.1.195:5000/v3
set OS_USERNAME=admin
set OS_PASSWORD=ZConp@ssw0rd
set OS_REGION_NAME=RegionOne
set OS_PROJECT_NAME=admin
set OS_USER_DOMAIN_NAME=Default
set OS_PROJECT_DOMAIN_NAME=Default

set INSTANCE_NAME=%2
set FLAVOR=%3
set DISKNAME=%4
set DISKSIZE=%5
set FLOATINGOX=%6
set SECURITY_GROUP=6120dab2-3e6a-423d-8fa2-cc35c9022b75
set NETWORK=cb362bea-6cd6-4b16-a212-bac953461aae
set KEYPAIR=adminkey


@rem 인스턴스 id값 설정
if "%1"=="w2016" (
	SET AMID=7d681761-a842-4797-8702-f05e39127411
	goto windows
)

if "%1"=="w2012R2" (
	SET AMID=704cb217-a7d3-47f7-a830-a4151c931311
	goto windows
)

if "%1"=="w2008R2" (
	SET AMID=cbb7caf1-c0bd-4766-806d-2451b49006d5
	goto windows
)

if "%1"=="cent6" (
	SET AMID=d85b7401-2201-4756-9299-aadf2ce311be
	goto linux
)

if "%1"=="cent7" (
	SET AMID=fda7b7f2-66a5-4ace-9054-8a7d9977771d
	goto linux
)


@rem  설명문
if "%1"=="--help" goto HELP
if "%1"=="/?" goto HELP
if "%1"=="flavorlist" goto FLAVORLIST
if "%1"=="networklist" goto NETWORKLIST
if "%1"=="securitylist" goto SECURITYLIST
if "%1"=="imagelist" goto IMAGELIST
if "%1"=="floatinglist" goto FLOATINGLIST



@rem 인스턴스 유형 선택
if "%3"=="1","m1.tiny" (
	SET FLAVOR=m1.tiny
)
if "%3"=="2","m1.small" (
	SET FLAVOR=m1.small
)
if "%3"=="3","m1.medium" (
	SET FLAVOR=m1.medium
)
if "%3"=="4","m1.large" (
	SET FLAVOR=m1.large
)
if "%3"=="5","m1.xlarge" (
	SET FLAVOR=m1.xlarge
)




@rem 인스턴스 생성
:windows
openstack server create --flavor %FLAVOR% --image %AMID% --security-group %SECURITY_GROUP% --network %NETWORK% %INSTANCE_NAME%
echo "인스턴스를 정상적으로 생성했습니다."
echo.

goto addDisk


:linux
openstack server create --flavor %FLAVOR% --image %AMID% --security-group %SECURITY_GROUP% --network %NETWORK% --key-name %KEYPAIR% %INSTANCE_NAME%
echo "인스턴스를 정상적으로 생성했습니다."
echo.

goto addDisk




@rem 인스턴스에 추가디스크 장착 및 floating id 추가
:addDisk

@rem 추가디스크 생성 및 추가
if "%4"=="x" (
	echo.
	echo "추가 디스크를 생성하지 않습니다."
	goto addFloatingip
)

openstack volume create %DISKNAME% --size %DISKSIZE%
echo "추가디스크를 정상적으로 생성했습니다."
echo.

openstack server add volume %INSTANCE_NAME% %DISKNAME%

goto addFloatingip


@rem floating ip 생성 및 추가
:addFloatingip

if "%6"=="x" (
	echo.
	echo "Floatin IP을 생성하지 않습니다."
	goto :EOF
)

openstack floating ip create public | findstr floating_ip_address > c:\exam.log
for /f "tokens=2 delims=|" %%a in (c:\exam.log) do (
	set FLO_IP=%%a	
	echo.
	echo "Floatin IP을 정상적으로 생성했습니다."
)
openstack server add floating ip %INSTANCE_NAME% %FLO_IP%




echo.
echo Done.
goto :EOF




@rem query 설명
:FLAVORLIST
openstack flavor list

echo Done.
goto :EOF

:NETWORKLIST
openstack network list

echo Done.
goto :EOF

:SECURITYLIST
openstack security group list

echo Done.
goto :EOF

:IMAGELIST
openstack image list

echo Done.
goto :EOF

:FLOATINGLIST	
openstack floating ip list

echo Done.
goto :EOF




:HELP
echo.
echo.
echo CLI를 통해서 OpenStack Instance 를 자동으로 생성합니다.
echo.
echo.
echo Windows , Linux
echo					       [		 생성하지 않을 시 'x' 표시	       ]
echo 프로그램.exe [/A] [인스턴스 이름] [/B] [추가디스크 이름] [추가디스크 크기(GB] [Floating ip 유뮤]
echo.									      [ 생성시 생략가능]
echo.
echo.
echo /A			운영체제 종류를 선택합니다.
echo.			Windows 2016	 -	 w2016
echo.			Windows 2012R2	 -	 w2012R2
echo.			Windows 2008R2	 -	 w2008R2
echo.			CentOS6		 -	 cent6
echo.			CentOS7  	 -	 cent7
echo.
echo /B			인스턴스 유형을 선택합니다.
echo.			m1.tiny		-	1
echo.			m1.small	-	2
echo.			m1.medium	-	3
echo.			m1.large	-	4
echo.			m1.xlarge	-	5
echo.
echo.
echo. ex) 프로그램.exe w2012R2 myWin2012R2 3 Repository 50 
echo 	   - 인스턴스 이름 : myWin2012R2
echo. 	   - 인스턴스 유형 : m1.medium
echo. 	   - 추가디스크 이름 / 용량(GB) : Repository / 50GB
echo. 	   - Floating IP 유무 : o
echo.
echo. ex) 프로그램.exe cent7 myCentos7 m1.large x x x
echo. 	   - 인스턴스 이름 : myCentos7
echo. 	   - 인스턴스 유형 : m1.large
echo. 	   - 추가디스크 이름 / 용량(GB)  : x / x
echo. 	   - Floating IP 유무 : x
echo.
echo.
echo.
echo /인스턴스 이름	 	 OpenStack에서 표기될 인스턴스 이름을 설정합니다.
echo /추가디스크이름		 Windows, Linux에서 추가 할 디스크 이름을 설정합니다.(생성하지 않을시 x)
echo /추가디스크B 크기(GB)	 Windows, Linux에서 추가로 등록할 디스크 용량을 설정합니다. (숫자 입력)
echo./Floating IP 유뮤	 Floating IP 생성할 시 생략하고, 생성하지 않을 시 x을 입력합니다.
echo.
echo.
echo.
echo 프로그램.exe [flaovrlist]	Openstack내 존재하는 flavor 리스트를 가져옵니다.
echo 프로그램.exe [imagerlist]	Openstack내 존재하는 image 리스트를 가져옵니다.
echo 프로그램.exe [neworklist]	Openstack내 존재하는 network 리스트를 가져옵니다.
echo 프로그램.exe [securitylist]	Openstack내 존재하는 security-group 리스트를 가져옵니다.
echo 프로그램.exe [floatinglist]	Openstack내 존재하는 floating-ip 리스트를 가져옵니다.
echo.
echo.


pause
goto :EOF



















