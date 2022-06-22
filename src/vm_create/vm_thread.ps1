$fullPathIncFileName = $MyInvocation.MyCommand.Definition     
$currentScriptName = $MyInvocation.MyCommand.Name           
$path = $fullPathIncFileName.Replace($currentScriptName, "") 



$json = $args[0]
$cloud_count = $args[1]
$myJson = Get-Content $json | ConvertFrom-Json
$CLOUD_TYPE = $myJson.cloud[$cloud_count].cloud_type

Write-Output "------ VM Creating ------"


############################################################  GCP Variable ############################################################

if ($CLOUD_TYPE -eq "GCP") { 
    $cnt = $args[2]; # vm index
    $GCP_COUNT = $args[3]; # gcp count (to access different log file) 
    $ACCOUNT_KEY = $path + $myJson.cloud[$cloud_count].vm[$cnt].account_key # account key
    $VM_NAME = $myJson.cloud[$cloud_count].vm[$cnt].vm_name; # vm name
    $USER = $myJson.cloud[$cloud_count].vm[$cnt].userName; # user name
    $CPU = $myJson.cloud[$cloud_count].vm[$cnt].cpu; # cpu
    $MEMORY = $myJson.cloud[$cloud_count].vm[$cnt].memory; # memory
    $OS = $myJson.cloud[$cloud_count].vm[$cnt].os; # os 
    $IMAGE = $myJson.cloud[$cloud_count].vm[$cnt].image; # os image
    $ZONE = $myJson.cloud[$cloud_count].vm[$cnt].zone; # zone
    $DISK_NAME = $myJson.cloud[$cloud_count].vm[$cnt].disk_name; # add_disk name
    $DISK_SIZE = $myJson.cloud[$cloud_count].vm[$cnt].disk_size; # add_disk size
    $DISK_NUM = $myJson.cloud[$cloud_count].vm[$cnt].disk_num; # add_disk number
    $gcp_auth_json = Get-Content $ACCOUNT_KEY | ConvertFrom-Json; # get information from json key file 
    $PROJECT = $gcp_auth_json.project_id; # project id
    $ACCOUNT = $gcp_auth_json.client_email # account email
    $disk_count = 1
    

    Write-Output 'Y' | gcloud auth login --cred-file $ACCOUNT_KEY
    
    ## Error input check

    # Get GCP Server List => check if vm name already exists 
    gcloud compute instances list --account $ACCOUNT --project $PROJECT --format json > "${path}gcp_server_list$GCP_COUNT.json"
    $GCP_SERVER_LIST = Get-Content "${path}gcp_server_list$GCP_COUNT.json" | ConvertFrom-Json
    for ($i = 0; $i -lt $GCP_SERVER_LIST.length; $i++) {
        if ($VM_NAME -eq $GCP_SERVER_LIST[$i].name) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Remove-Item "${path}gcp_server_list$GCP_COUNT.json"
            exit 0 
        }
    }
    
    # Get GCP Disk List => check if disk name already exists 
    gcloud compute disks list --account $ACCOUNT --project $PROJECT --format json > "${path}gcp_disk_list$GCP_COUNT.json"
    $GCP_DISK_LIST = Get-Content "${path}gcp_disk_list$GCP_COUNT.json" | ConvertFrom-Json
    for ($i = 0; $i -lt $GCP_DISK_LIST.length; $i++) {
        if ("$DISK_NAME$disk_count" -eq $GCP_DISK_LIST[$i].name) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same Disk Name Already Exists" ) | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same Disk Name Already Exists" ) | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Remove-Item "${path}gcp_disk_list$GCP_COUNT.json"
            exit 0
        }
        $disk_count++
    }

    $disk_count = 1
    Remove-Item "${path}gcp_server_list$GCP_COUNT.json"
    Remove-Item "${path}gcp_disk_list$GCP_COUNT.json"




    ## GCP OS IMAGES
    if ($IMAGE -eq "centos7") {
        $IMAGE = "centos-7"
        $IMAGE_PROJECT = "centos-cloud"
    }

    if ($IMAGE -eq "ubuntu20") {
        $IMAGE = "ubuntu-2004-lts"
        $IMAGE_PROJECT = "ubuntu-os-cloud"
    }

    if ($IMAGE -eq "ubuntu18") {
        $IMAGE = "ubuntu-1804-lts"
        $IMAGE_PROJECT = "ubuntu-os-cloud"
    }

    if ($IMAGE -eq "win2016") {
        $IMAGE = "windows-2016"
        $IMAGE_PROJECT = "windows-cloud"
    }

    if ($IMAGE -eq "win2019") {
        $IMAGE = "windows-2019"
        $IMAGE_PROJECT = "windows-cloud"
    }
        
}


############################################################  NCP Variable ############################################################



elseif ($CLOUD_TYPE -eq "NCP") {
    $cnt = $args[2] 
    $NCP_COUNT = $args[3] # Count for each VM (to create and access each other file)
    $VPC_NO = $args[5] # Vpc Number
    $SUBNET_NO = $args[6] # Subnet Number
    $ACL_NO = $args[7] # Access Control List Number
    $ACG_NO = $args[8] # Access Conterol Group Number
    $LOGINKEY = $myJson.cloud[$cloud_count].auth.login_key; # loginkey name
    $VM_NAME = $myJson.cloud[$cloud_count].vm[$cnt].vm_name; # VM Name
    $OS = $myJson.cloud[$cloud_count].vm[$cnt].os; # OS
    $IMAGE = $myJson.cloud[$cloud_count].vm[$cnt].image; # OS Image
    $SCRIPT_NAME = $myJson.cloud[$cloud_count].vm[$cnt].scriptName; # Script Name
    $PUBLICIP = "true" # always be true for remote access
    $ZONE = "KR" # Zone

    # Error input Check (Script, Key) // Same name already exists
    
    # Script check if same name already exists
    cmd /c "cd $path && .\ncloud vserver getInitScriptList > ncp_script_list$NCP_COUNT.json"
    $NCP_SCRIPT_LIST = Get-Content "${path}ncp_script_list$NCP_COUNT.json" | ConvertFrom-Json
    for ($i = 0; $i -lt $NCP_SCRIPT_LIST.getInitScriptListResponse.totalRows; $i++) {
        if ($SCRIPT_NAME -eq $NCP_SCRIPT_LIST.getInitScriptListResponse.initScriptList[$i].initScriptName) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same Script Name Already Exists") | Out-File -Encoding UTF8 "${path}ncp_result$NCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same Script Name Already Exists") | Out-File -Encoding UTF8 "${path}ncp_created$NCP_COUNT.txt"
            Remove-Item "${path}ncp_script_list$NCP_COUNT.json"
            exit 0 
        }   
    }
    Remove-Item "${path}ncp_script_list$NCP_COUNT.json"


    # Key check if same name already exists
    if ($NCP_COUNT -eq 1) {
    cmd /c "cd $path && .\ncloud vserver getLoginKeyList > ncp_key_list$NCP_COUNT.json"
    $NCP_KEY_LIST = Get-Content "${path}ncp_key_list$NCP_COUNT.json" | ConvertFrom-Json
    for ($i = 0; $i -lt $NCP_KEY_LIST.getLoginKeyListResponse.totalRows; $i++) {
        if ($LOGINKEY -eq $NCP_KEY_LIST.getLoginKeyListResponse.loginKeyList[$i].keyName) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same LoginKey Name Already Exists") | Out-File -Encoding UTF8 "${path}ncp_result$NCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same LoginKey Name Already Exists") | Out-File -Encoding UTF8 "${path}ncp_created$NCP_COUNT.txt"
            Remove-Item "${path}ncp_key_list$NCP_COUNT.json"
            exit 0 
        }   
    }
    Remove-Item "${path}ncp_key_list$NCP_COUNT.json"
    }
       

    # Linux Image set and script create
    if ($OS -eq "linux") {
        if ($IMAGE -eq "centos7") { #centos7
            $IMAGE = "SW.VSVR.OS.LNX64.CNTOS.0708.B050"
        }
        elseif ($IMAGE -eq "ubuntu16") { # ubuntu16
            $IMAGE = "SW.VSVR.OS.LNX64.UBNTU.SVR1604.B050"
        }
        elseif ($IMAGE -eq "ubuntu18") { # ubuntu18
            $IMAGE = "SW.VSVR.OS.LNX64.UBNTU.SVR1804.B050"
        }
        elseif ($IMAGE -eq "ubuntu20") { #ubuntu20
            $IMAGE = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
        }

        $NCP_LIN_COUNT = $args[4]
          
        if ($SCRIPT_NAME -ne "") { # init script create

        cmd /c ${path}ncloud vserver createInitScript --regionCode $ZONE --initScriptName $SCRIPT_NAME --osTypeCode LNX --initScriptContent "#! /bin/bash" | Out-Null
            
          
        cmd /c ${path}ncloud vserver getInitScriptList > ${path}naver-lin-script$NCP_LIN_COUNT.json
          
        # Get Script Number
        $script_info = Get-Content "${path}naver-lin-script$NCP_LIN_COUNT.json" | ConvertFrom-Json
        for ($i = 0; $i -lt $script_info.getInitScriptListResponse.totalRows; $i++) {
            if ($script_info.getInitScriptListResponse.initScriptList[$i].initScriptName -eq $SCRIPT_NAME) {
                $SCRIPT_NO = $script_info.getInitScriptListResponse.initScriptList[$i].initScriptNo
                break
            }
        }
        Remove-Item "${path}naver-lin-script$NCP_LIN_COUNT.json"
        }
    }


    # Windows image set and script create
    elseif ($OS -eq "windows") {
        if ($IMAGE -eq "win2016") {
            $IMAGE = "SW.VSVR.OS.WND64.WND.SVR2016EN.B100"
        }
        elseif ($IMAGE -eq "win2019") {
            $IMAGE = "SW.VSVR.OS.WND64.WND.SVR2019EN.B100"
        }
        $NCP_WIN_COUNT = $args[4]
          
        if ($SCRIPT_NAME -ne "") { # init script create 
        cmd /c ${path}ncloud vserver createInitScript --regionCode $ZONE --initScriptName $SCRIPT_NAME --osTypeCode WND --initScriptContent "#! /bin/bash" | Out-Null
          
        cmd /c "cd $path && .\ncloud vserver getInitScriptList > naver-win-script$NCP_WIN_COUNT.json"
          
        # Get Script Number
        $script_info = Get-Content "${path}naver-win-script$NCP_WIN_COUNT.json" | ConvertFrom-Json
        for ($i = 0; $i -lt $script_info.getInitScriptListResponse.totalRows; $i++) {
            if ($script_info.getInitScriptListResponse.initScriptList[$i].initScriptName -eq $SCRIPT_NAME) {
                $SCRIPT_NO = $script_info.getInitScriptListResponse.initScriptList[$i].initScriptNo
                break
            }
        }
          
        Remove-Item "${path}naver-win-script$NCP_WIN_COUNT.json"
    }

    }
         
    # first thread create key file for login
    if ($NCP_COUNT -eq 1) {
        cmd /c "cd $path && .\ncloud vserver createLoginKey --keyName $LOGINKEY > .\$LOGINKEY.json"
        $ncpkey = Get-Content "${path}$LOGINKEY.json" | ConvertFrom-Json
        $ncpkey.createLoginKeyResponse.privateKey | Out-File -Encoding ASCII "${path}$LOGINKEY.pem"
        Remove-Item "${path}$LOGINKEY.json"

    }
    
}

############################################################  OpenStack  ############################################################


elseif ($CLOUD_TYPE -eq "OPENSTACK") { 

    # auth
    $env:OS_AUTH_URL = $myJson.cloud[$cloud_count].auth.os_auth_url;
    $env:OS_USERNAME = $myJson.cloud[$cloud_count].auth.os_username
    $env:OS_PASSWORD = $myJson.cloud[$cloud_count].auth.os_password
    $env:OS_REGION_NAME = $myJson.cloud[$cloud_count].auth.os_region_name
    $env:OS_PROJECT_NAME = $myJson.cloud[$cloud_count].auth.os_project_name
    $env:OS_USER_DOMAIN_NAME = $myJson.cloud[$cloud_count].auth.os_user_domian_name
    $env:OS_PROJECT_DOMAIN_NAME = $myJson.cloud[$cloud_count].auth.os_project_domain_name
 


    $cnt = $args[2]
    $OPS_COUNT = $args[3]
    $VM_NAME = $myJson.cloud[$cloud_count].vm[$cnt].vm_name;
    $FLAVOR = $myJson.cloud[$cloud_count].vm[$cnt].flavor;
    $OS = $myJson.cloud[$cloud_count].vm[$cnt].os;
    $IMAGE = $myJson.cloud[$cloud_count].vm[$cnt].image;
    $KEY_NAME = $myJson.cloud[$cloud_count].vm[$cnt].key_name;
    $DISK_NAME = $myJson.cloud[$cloud_count].vm[$cnt].disk_name;
    $DISK_SIZE = $myJson.cloud[$cloud_count].vm[$cnt].disk_size;
    $FLOATING_IP = $myJson.cloud[$cloud_count].vm[$cnt].floatingIp;
    $SECURITY_GROUP = "WRA";
    $NETWORK = "private-network"
    

    #Openstack Server List
    openstack server list -f json > ops_server_list$OPS_COUNT.json
    $OPS_SERVER_LIST = Get-Content ops_server_list$OPS_COUNT.json | ConvertFrom-Json
    for ($i = 0; $i -lt $OPS_SERVER_LIST.length; $i++) {
        if ($VM_NAME -eq $OPS_SERVER_LIST[$i].Name) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            Remove-Item .\ops_server_list$OPS_COUNT.json
            exit 0
        }
    }

    #Openstack Disk List
    openstack volume list -f json > ops_volume_list$OPS_COUNT.json
    $OPS_VOLUME_LIST = Get-Content ops_volume_list$OPS_COUNT.json | ConvertFrom-Json
    for ($i = 0; $i -lt $OPS_VOLUME_LIST.length; $i++) {
        if ($DISK_NAME -eq $OPS_VOLUME_LIST[$i].Name) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $DISK_NAME + " ----------> Fail: Same Disk Name Already Exists") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $DISK_NAME + " ----------> Fail: Same Disk Name Already Exists") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            Remove-Item .\ops_volume_list$OPS_COUNT.json
            exit 0
        }
    }

    #Openstack KeyPair List
    openstack keypair list -f json > ops_key_list$OPS_COUNT.json
    $OPS_KEY_LIST = Get-Content ops_key_list$OPS_COUNT.json | ConvertFrom-Json
    for ($i = 0; $i -lt $OPS_KEY_LIST.length; $i++) {
        if ($KEY_NAME -eq $OPS_KEY_LIST[$i].Name) {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $KEY_NAME + " ----------> Fail: Same Key Name Already Exists") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $KEY_NAME + " ----------> Fail: Same Key Name Already Exists") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            Remove-Item .\ops_key_list$OPS_COUNT.json
            exit 0
        }
    }

    Remove-Item .\ops_server_list$OPS_COUNT.json
    Remove-Item .\ops_volume_list$OPS_COUNT.json
    Remove-Item .\ops_key_list$OPS_COUNT.json
   

    # Flavor
    if ($FLAVOR -eq 1) {
        $FLAVOR = "m1.tiny"
    }
    elseif ($FLAVOR -eq 2) {
        $FLAVOR = "m1.small"
    }
    elseif ($FLAVOR -eq 3) {
        $FLAVOR = "m1.medium"
    }
    elseif ($FLAVOR -eq 4) {
        $FLAVOR = "m1.large"
    }
    elseif ($FLAVOR -eq 5) {
        $FLAVOR = "m1.xlarge"
    }


    # Linux
    if ($OS -eq "linux") {

        openstack keypair create $KEY_NAME --private-key ops-key.pem

        if ($IMAGE -eq "centos7") {
            $IMAGE = "centos7"
        }
              
              
        openstack server create --flavor $FLAVOR --image $IMAGE --network $NETWORK --key-name $KEY_NAME --user-data linux.sh $VM_NAME | Out-File -Encoding UTF8 output_ops$OPS_COUNT.txt
              
    }

    # Windows
    elseif ($OS -eq "windows") {
        if ($IMAGE -eq "win2012") {
            $IMAGE = "win2012"
        }
        openstack server create --flavor $FLAVOR --image $IMAGE --security-group $SECURITY_GROUP --network $NETWORK --user-data win.ps1 $VM_NAME | Out-File -Encoding UTF8 output_ops$OPS_COUNT.txt
        $pass = (Get-Content -Path .\win.ps1) | findstr PASSWORD=
        $PASSWORD = $pass.Replace("`"", "").split("=")[1]
	
    }
    openstack volume create $DISK_NAME --size $DISK_SIZE
    openstack server add volume $VM_NAME $DISK_NAME
        
          
    if ($FLOATING_IP -eq "O") {
        openstack floating ip create --subnet public-sub public-network | findstr floating_ip_address | Out-File -Encoding UTF8 ops_ip$OPS_COUNT.txt
            (Get-Content -Path .\ops_ip$OPS_COUNT.txt) | foreach {	$token = $_ -split ' +' }
        $FLO_IP = $token[3]
              
        openstack server add floating ip $VM_NAME $FLO_IP
              
        if ($IMAGE -eq "centos7") {
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created) {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user : centos   ") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user : centos   ") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            
            }
            else {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
                  
                  
        }
        elseif ($OS -eq "windows") {
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created) {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user: Administrator    password: " + $PASSWORD) | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user: Administrator    password: " + $PASSWORD) | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
            else {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $FLO_IP + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
        }
          		
        Remove-Item ops_ip$OPS_COUNT.txt   
    }
          
    else {
        if ($IMAGE -eq "centos7") {
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created) {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user : centos   ") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user : centos   ") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
           
            }
            else {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> FAIL") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
        }
        elseif ($OS -eq "windows") {
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created) {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user: Administrator    password: ") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user: Administrator    password: ") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
            else {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") | Out-File -Encoding UTF8 ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") | Out-File -Encoding UTF8 ops_created$OPS_COUNT.txt
            }
        }
    }   
    Remove-Item output_ops$OPS_COUNT.txt
              
}
          
    

################################################################## GCP INSTANCE CREATE ###################################################################

if ($CLOUD_TYPE -eq "GCP") {

    #Linux
    if ($OS -eq "linux") {

        # Instance Create
        gcloud compute instances create $VM_NAME --metadata-from-file=startup-script="${path}linux.sh" --image-family=$IMAGE --image-project=$IMAGE_PROJECT --custom-cpu=$CPU --custom-memory=$MEMORY --zone=$ZONE --account $ACCOUNT --project $PROJECT --format json | Out-File -Encoding UTF8 ${path}output_gcp$GCP_COUNT.json
       
        # ssh key create and load to gcloud metadata (for login)
        if (-not (Test-Path ${path}$USER-gcp-key)) {
            ssh-keygen -t rsa -f ${path}$USER-gcp-key -C $USER -b 2048 -P """"
        }

        # if ssh key file already exists in folder => overwrite 
        else {
            Write-Output "y" | ssh-keygen -t rsa -f ${path}$USER-gcp-key -C $USER -b 2048 -P """"
        }

        $key_file_name = "${path}$USER-gcp-key.pub"
        $key_content = Get-Content $key_file_name
        gcloud compute project-info add-metadata --metadata=ssh-keys=$USER":"$key_content --account $ACCOUNT --project $PROJECT # add key content to gcp metadata

        # adding disk
        for ($j = 1; $j -lt $DISK_NUM + 1; $j++) {
            $dd = $DISK_NAME + $disk_count
            $disk_count++
            gcloud compute disks create $dd --zone=$ZONE --size=$DISK_SIZE --account $ACCOUNT --project $PROJECT --user-output-enabled=false # disk create
            gcloud compute instances attach-disk $VM_NAME --disk $dd --zone $ZONE --account $ACCOUNT --project $PROJECT # attach to instance
        }

       
        # Get GCP VM Info
        $info = Get-Content ${path}output_gcp$GCP_COUNT.json | ConvertFrom-Json

        $name_info = $info.name
        $ip_info = $info.networkInterfaces.accessConfigs.natIP

        # Success if Status Running
        if ($info.status -eq "RUNNING") {
            Write-Output ($CLOUD_TYPE + "  " + $name_info + " " + $ip_info + "  ----------> SUCCESS    " + "user : $USER   ") | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $name_info + " " + $ip_info + "  ----------> SUCCESS    " + "user : $USER   ") | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"
        }

        # Fail if Status not Running
        else {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"
        }
  
    }
    
    
    # Windows
    elseif ($OS -eq "windows") {

        # Instance Create
        gcloud compute instances create $VM_NAME --metadata-from-file=windows-startup-script-ps1="${path}win.ps1" --image-family=$IMAGE --image-project=$IMAGE_PROJECT --custom-cpu=$CPU --custom-memory=$MEMORY --zone=$ZONE --account $ACCOUNT --project $PROJECT --format json | Out-File -Encoding UTF8 ${path}output_gcp$GCP_COUNT.json
       

        ## adding disk
        for ($j = 1; $j -lt $DISK_NUM + 1; $j++) {
            $dd = $DISK_NAME + $disk_count
            $disk_count++
            gcloud compute disks create $dd --zone=$ZONE --size=$DISK_SIZE --account $ACCOUNT --project $PROJECT --user-output-enabled=false # disk create
            gcloud compute instances attach-disk $VM_NAME --disk $dd --zone $ZONE --account $ACCOUNT --project $PROJECT # attach to instance
        }

        $info = Get-Content ${path}output_gcp$GCP_COUNT.json | ConvertFrom-Json

        $name_info = $info.name
        $ip_info = $info.networkInterfaces.accessConfigs.natIP
       
        # windows password reset for login
        while ($true) {
            Write-Output 'Y' | gcloud compute reset-windows-password $VM_NAME --zone=$ZONE --user=$USER --account $ACCOUNT --project $PROJECT --format json | Out-File -Encoding UTF8 "${path}gcp_password$GCP_COUNT.json"
            $PASSWORD_INFO = Get-content "${path}gcp_password$GCP_COUNT.json" | ConvertFrom-Json
            if ($PASSWORD_INFO.password) {
                break
            }
 
        }   
       
        # Get Password and user name
        $PASSWORD = $PASSWORD_INFO.password
        $VM_USER_NAME = $PASSWORD_INFO.username
       
        # Success if Status Running
        if ($info.status -eq "RUNNING") {
            Write-Output ($CLOUD_TYPE + "  " + $name_info + " " + $ip_info + " " + "  ----------> SUCCESS    " + "user : $VM_USER_NAME   " + "password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $name_info + " " + $ip_info + " " + "  ----------> SUCCESS    " + "user : $VM_USER_NAME   " + "password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"

        }
        # Fail if Status not Running
        else {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + " " + "  ----------> FAIL") | Out-File -Encoding UTF8 "${path}gcp_created$GCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + " " + "  ----------> FAIL") | Out-File -Encoding UTF8 "${path}gcp_result$GCP_COUNT.txt"
        }
        Remove-Item "${path}gcp_password$GCP_COUNT.json"
    }
    
    
    Remove-Item "${path}output_gcp$GCP_COUNT.json"
}

####################################################### NCP Instance Create #############################################################


elseif ($CLOUD_TYPE -eq "NCP") {
      
    # Instance create
    cmd /c ${path}ncloud vserver createServerInstances --regionCode $ZONE --serverImageProductCode $IMAGE --vpcNo $VPC_NO --subnetNo $SUBNET_NO --serverName $VM_NAME --networkInterfaceList "networkInterfaceOrder='0', accessControlGroupNoList=['$ACG_NO']" --initScriptNo $SCRIPT_NO --loginKeyName $LOGINKEY --associateWithPublicIp $PUBLICIP > ${path}output_ncp$NCP_COUNT.json
   
    # Get Instance list to get Public Ip
    cmd /c ${path}ncloud  vserver getServerInstanceList | Out-File -Encoding UTF8 "${path}ncp_instance_list$NCP_COUNT.json"
    $NCP_INSTANCE_LIST = Get-Content "${path}ncp_instance_list$NCP_COUNT.json" | ConvertFrom-Json

    # Get Public Ip 
    for ($k = 0; $k -lt $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows; $k++) {
        if ($NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k].serverName -eq $VM_NAME) {
            $total = $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows;
            while ($true) {
                cmd /c ${path}ncloud vserver getServerInstanceList | Out-File -Encoding UTF8 "${path}ncp_instance_list$NCP_COUNT.json"
                $NCP_INSTANCE_LIST = Get-Content "${path}ncp_instance_list$NCP_COUNT.json" | ConvertFrom-Json
                if ($NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k + $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows - $total].publicIp -ne "") {
                    $INSTANCE_NO = $NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k + $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows - $total].serverInstanceNo 
                    $PUBLIC_IP = $NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k + $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows - $total].publicIp
                           
                    break
                }
            }
            break
        }
    }
    Remove-Item "${path}ncp_instance_list$NCP_COUNT.json"
      

    # Get Password from Key File Created
    cmd /c ${path}ncloud vserver getRootPassword --regionCode $ZONE --serverInstanceNo $INSTANCE_NO --privateKey "file://${path}/$LOGINKEY.pem" | Out-File -Encoding UTF8 "${path}naver-password$NCP_COUNT.json"
    $password_info = Get-Content "${path}naver-password$NCP_COUNT.json" | ConvertFrom-Json
    $PASSWORD = $password_info.getRootPasswordResponse.rootPassword
    Remove-Item "${path}naver-password$NCP_COUNT.json"
    
    # Instance Create Success
    if (Get-Content "${path}output_ncp$NCP_COUNT.json" | findstr serverName) {
        if ($OS -eq "linux") {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: root    password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}ncp_created$NCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: root    password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}ncp_result$NCP_COUNT.txt"
        }
        elseif ($OS -eq "windows") {
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: Administrator    password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}ncp_created$NCP_COUNT.txt"
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: Administrator    password: " + $PASSWORD) | Out-File -Encoding UTF8 "${path}ncp_result$NCP_COUNT.txt"
        }
    }

    # Instance Create Fail
    else {
        Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  -----------> FAIL ") | Out-File -Encoding UTF8 "${path}ncp_created$NCP_COUNT.txt"
        Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  -----------> FAIL ") | Out-File -Encoding UTF8 "${path}ncp_result$NCP_COUNT.txt"
    }
   
    
    Remove-Item "${path}output_ncp$NCP_COUNT.json"
    
}




