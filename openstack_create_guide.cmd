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


@rem �ν��Ͻ� id�� ����
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


@rem  ����
if "%1"=="--help" goto HELP
if "%1"=="/?" goto HELP
if "%1"=="flavorlist" goto FLAVORLIST
if "%1"=="networklist" goto NETWORKLIST
if "%1"=="securitylist" goto SECURITYLIST
if "%1"=="imagelist" goto IMAGELIST
if "%1"=="floatinglist" goto FLOATINGLIST



@rem �ν��Ͻ� ���� ����
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




@rem �ν��Ͻ� ����
:windows
openstack server create --flavor %FLAVOR% --image %AMID% --security-group %SECURITY_GROUP% --network %NETWORK% %INSTANCE_NAME%
echo "�ν��Ͻ��� ���������� �����߽��ϴ�."
echo.

goto addDisk


:linux
openstack server create --flavor %FLAVOR% --image %AMID% --security-group %SECURITY_GROUP% --network %NETWORK% --key-name %KEYPAIR% %INSTANCE_NAME%
echo "�ν��Ͻ��� ���������� �����߽��ϴ�."
echo.

goto addDisk




@rem �ν��Ͻ��� �߰���ũ ���� �� floating id �߰�
:addDisk

@rem �߰���ũ ���� �� �߰�
if "%4"=="x" (
	echo.
	echo "�߰� ��ũ�� �������� �ʽ��ϴ�."
	goto addFloatingip
)

openstack volume create %DISKNAME% --size %DISKSIZE%
echo "�߰���ũ�� ���������� �����߽��ϴ�."
echo.

openstack server add volume %INSTANCE_NAME% %DISKNAME%

goto addFloatingip


@rem floating ip ���� �� �߰�
:addFloatingip

if "%6"=="x" (
	echo.
	echo "Floatin IP�� �������� �ʽ��ϴ�."
	goto :EOF
)

openstack floating ip create public | findstr floating_ip_address > c:\exam.log
for /f "tokens=2 delims=|" %%a in (c:\exam.log) do (
	set FLO_IP=%%a	
	echo.
	echo "Floatin IP�� ���������� �����߽��ϴ�."
)
openstack server add floating ip %INSTANCE_NAME% %FLO_IP%




echo.
echo Done.
goto :EOF




@rem query ����
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
echo CLI�� ���ؼ� OpenStack Instance �� �ڵ����� �����մϴ�.
echo.
echo.
echo Windows , Linux
echo					       [		 �������� ���� �� 'x' ǥ��	       ]
echo ���α׷�.exe [/A] [�ν��Ͻ� �̸�] [/B] [�߰���ũ �̸�] [�߰���ũ ũ��(GB] [Floating ip ����]
echo.									      [ ������ ��������]
echo.
echo.
echo /A			�ü�� ������ �����մϴ�.
echo.			Windows 2016	 -	 w2016
echo.			Windows 2012R2	 -	 w2012R2
echo.			Windows 2008R2	 -	 w2008R2
echo.			CentOS6		 -	 cent6
echo.			CentOS7  	 -	 cent7
echo.
echo /B			�ν��Ͻ� ������ �����մϴ�.
echo.			m1.tiny		-	1
echo.			m1.small	-	2
echo.			m1.medium	-	3
echo.			m1.large	-	4
echo.			m1.xlarge	-	5
echo.
echo.
echo. ex) ���α׷�.exe w2012R2 myWin2012R2 3 Repository 50 
echo 	   - �ν��Ͻ� �̸� : myWin2012R2
echo. 	   - �ν��Ͻ� ���� : m1.medium
echo. 	   - �߰���ũ �̸� / �뷮(GB) : Repository / 50GB
echo. 	   - Floating IP ���� : o
echo.
echo. ex) ���α׷�.exe cent7 myCentos7 m1.large x x x
echo. 	   - �ν��Ͻ� �̸� : myCentos7
echo. 	   - �ν��Ͻ� ���� : m1.large
echo. 	   - �߰���ũ �̸� / �뷮(GB)  : x / x
echo. 	   - Floating IP ���� : x
echo.
echo.
echo.
echo /�ν��Ͻ� �̸�	 	 OpenStack���� ǥ��� �ν��Ͻ� �̸��� �����մϴ�.
echo /�߰���ũ�̸�		 Windows, Linux���� �߰� �� ��ũ �̸��� �����մϴ�.(�������� ������ x)
echo /�߰���ũB ũ��(GB)	 Windows, Linux���� �߰��� ����� ��ũ �뷮�� �����մϴ�. (���� �Է�)
echo./Floating IP ����	 Floating IP ������ �� �����ϰ�, �������� ���� �� x�� �Է��մϴ�.
echo.
echo.
echo.
echo ���α׷�.exe [flaovrlist]	Openstack�� �����ϴ� flavor ����Ʈ�� �����ɴϴ�.
echo ���α׷�.exe [imagerlist]	Openstack�� �����ϴ� image ����Ʈ�� �����ɴϴ�.
echo ���α׷�.exe [neworklist]	Openstack�� �����ϴ� network ����Ʈ�� �����ɴϴ�.
echo ���α׷�.exe [securitylist]	Openstack�� �����ϴ� security-group ����Ʈ�� �����ɴϴ�.
echo ���α׷�.exe [floatinglist]	Openstack�� �����ϴ� floating-ip ����Ʈ�� �����ɴϴ�.
echo.
echo.


pause
goto :EOF



















