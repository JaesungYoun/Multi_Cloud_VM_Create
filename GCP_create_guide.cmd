@echo off


@rem 계정 인증
if "%1" == "login" (
goto auth
)

@rem 운영체제에 따른 이미지 이름
SET centos6=centos-6
SET centos7=centos-7
SET ubuntu16=ubuntu-1604-lts
SET ubuntu18=ubuntu-1804-lts
SET w2012r2=windows-2012-r2
SET w2016=windows-2016

@rem 입력값 순서
SET INSTANCE_NAME=%1
SET PROJECT=%3
SET ZONE=%4
SET DISKA=%5


@rem 추가 디스크 생성, 붙이기
SET DISK_NAME=%6
SET DISKB=%7


@rem HELP
if "%1" == "/?" goto HELP


@rem 인스턴스 IMAGE 값 설정
if "%2"=="centos6" (
   SET IMAGE=centos-6
   goto create
)


if "%2"=="centos7" (
   SET IMAGE=centos-7
   goto create
)


if "%2"=="ubuntu16" (
   SET IMAGE=ubuntu-1604-lts
   goto create
)


if "%2"=="ubuntu18" (
   SET IMAGE=ubuntu-1804-lts
   goto create
)


if "%2"=="w2012r2" (
   SET IMAGE=windows-2012-r2
   goto create
)


if "%2"=="w2016" (
   SET IMAGE=windows-2016
   goto create
)


@rem 키파일 인증
:auth
gcloud auth activate-service-account 952188033199-compute@developer.gserviceaccount.com --key-file=C:my-project-1-271506-51692fdbc7af.json --project=my-project-1-271506


echo Done.
goto :EOF



:create

@rem                [인스턴스 생성]                          [시작 스크립트 실행파일]             [OS 이미지]                 [프로젝트]       [지역]       [부트디스크 크기]
call cmd.exe /c "gcloud compute instances create %INSTANCE_NAME% --metadata-from-file startup-script=test.sh --image-family=%IMAGE% --image-project=%PROJECT% --zone=%ZONE% --boot-disk-size=%DISKA%"
call cmd.exe /c "gcloud compute disks create %DISK_NAME% --zone=%ZONE% --size=%DISKB%"
call cmd.exe /c "gcloud compute instances attach-disk %INSTANCE_NAME% --disk %DISK_NAME%"
call cmd.exe /c "gcloud compute instances add-metadata %INSTANCE_NAME% --metadata block-project-ssh-keys=FALSE"
call cmd.exe /c "gcloud compute scp ZConverter_CloudTargetClient_Setup_V3.3_Build_3049.tar.gz %INSTANCE_NAME%:/tmp"
call cmd.exe /c "gcloud compute ssh %INSTANCE_NAME%"



@rem --machin-type=n1-standard-1

echo Done.
goto :EOF


:HELP
echo.
echo.
echo CLI를 통해서 GCP Instance 를 자동으로 생성합니다.
echo.
echo linux
echo 프로그램.exe [인스턴스 이름] [이미지 이름] [프로젝트 이름] [Zone] [부트디스크 크기(GB)]
echo.
echo ubuntu
echo 프로그램.exe [인스턴스 이름] [이미지 이름] [프로젝트 이름] [Zone] [부트디스크 크기(GB)]
echo.
echo Windows 
echo 프로그램.exe [인스턴스 이름] [이미지 이름] [프로젝트 이름] [Zone] [부트디스크 크기(GB)]
echo.
echo  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo  ::     운영체제 종류와 이미지, 프로젝트를 선택합니다.                     ::
echo  ::                                       ::
echo  ::   운영체제       이미지         프로젝트 이름      지역         ::
echo  ::   CentOS6       -    centos6   -   centos-cloud     -   asia-northeast3-a   ::
echo  ::   CentOS7      -    centos7   -   centos-cloud     -   asia-northeast3-a   ::
echo  ::   Ubuntu16     -    ubuntu16   -   ubuntu-os-cloud     -   asia-northeast3-a   ::
echo  ::   Ubuntu18    -     ubuntu18   -   ubuntu-os-cloud     -   asia-northeast3-a   ::
echo  ::   Windows 2016    -    w2016      -   windows-cloud     -   asia-northeast3-a   ::
echo  ::   Windows 2012R2    -    w2012R2   -   windows-cloud     -   asia-northeast3-a   ::
echo  :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.
echo   ex) GCP_create.bat [1]centos7example(Instance_이름) [2]centos7(이미지) [3]centos-cloud(프로젝트) [4]asia-northeast3-a(지역) [5]20GB(Bootdisk_size)
echo                [6]disk-1(추가디스크이름) [7]30GB(추가디스크사이즈)
echo       -----------------------------------------------------------------------------------------------------------------------------------------------------   
echo.
echo.
echo /인스턴스 이름      GCP에서 표기될 인스턴스 이름을 설정합니다.
echo /이미지 이름      GCP에서 사용할 이미지 이름을 지정합니다.
echo /프로젝트 이름      GCP에서 사용할 운영체제에 따른 프로젝트 이름을 지정합니다.
echo /부트디스크 크기(GB)   Windows, Linux에서 추가로 등록할 디스크 용량을 설정합니다. (숫자 입력)
echo /추가디스크 크기(GB)   Windows, Linux에서 추가로 등록할 디스크 용량을 설정합니다. (숫자 입력)
echo.
echo      ::::::::::::::::::::::::::::::::::::::::::::::::::::
echo    :: First step: GCP_create.bat login을 입력합니다. ::
echo    ::::::::::::::::::::::::::::::::::::::::::::::::::::
echo.
pause
goto :EOF


