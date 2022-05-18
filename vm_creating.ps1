$json = $args[0]
$cloud_count = $args[1]
$myJson = Get-Content $json | ConvertFrom-Json
$CLOUD_TYPE = $myJson.cloud[$cloud_count].cloud_type

Write-Output "------ VM Creating ------"


############################################################  GCP  ############################################################

if ($CLOUD_TYPE -eq "GCP"){ 
    $cnt = $args[2];
    $GCP_COUNT= $args[3];
    $ACCOUNT_KEY = $myJson.cloud[$cloud_count].auth.account_key;
    $VM_NAME = $myJson.cloud[$cloud_count].vm[$cnt].vm_name;
    $USER = $myJson.cloud[$cloud_count].vm[$cnt].userName;
    $CPU = $myJson.cloud[$cloud_count].vm[$cnt].cpu;
    $MEMORY = $myJson.cloud[$cloud_count].vm[$cnt].memory;
    $OS = $myJson.cloud[$cloud_count].vm[$cnt].os;
    $IMAGE = $myJson.cloud[$cloud_count].vm[$cnt].image;
    $ZONE = $myJson.cloud[$cloud_count].vm[$cnt].zone;
    $DISK_NAME = $myJson.cloud[$cloud_count].vm[$cnt].disk_name;
    $DISK_SIZE = $myJson.cloud[$cloud_count].vm[$cnt].disk_size;
    $DISK_NUM= $myJson.cloud[$cloud_count].vm[$cnt].disk_num;
    $gcp_auth_json = Get-Content $ACCOUNT_KEY | ConvertFrom-Json;
    $PROJECT = $gcp_auth_json.project_id;
    $ACCOUNT = $gcp_auth_json.client_email
    $disk_count = 1


    # GCP SERVER LIST 
    gcloud compute instances list --format json > gcp_server_list$GCP_COUNT.json
    $GCP_SERVER_LIST = Get-Content gcp_server_list$GCP_COUNT.json | ConvertFrom-Json
    for ($i =0; $i -lt $GCP_SERVER_LIST.length; $i++) {
        if ($VM_NAME -eq $GCP_SERVER_LIST[$i].name){
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") > gcp_result$GCP_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") > gcp_created$GCP_COUNT.txt
            Remove-Item .\gcp_server_list$GCP_COUNT.json
            exit 0 
        }
    }
    
    #GCP DISK LIST
    gcloud compute disks list --format json > gcp_disk_list$GCP_COUNT.json
    $GCP_DISK_LIST = Get-Content gcp_disk_list$GCP_COUNT.json | ConvertFrom-Json
    for ($i =0; $i -lt $GCP_DISK_LIST.length; $i++) {
        if ("$DISK_NAME$disk_count" -eq $GCP_DISK_LIST[$i].name){
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME +  "  ----------> Fail: Same Disk Name Already Exists" ) > gcp_result$GCP_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $VM_NAME +  "  ----------> Fail: Same Disk Name Already Exists" ) > gcp_created$GCP_COUNT.txt
            Remove-Item .\gcp_disk_list$GCP_COUNT.json
            exit 0
        }
        $disk_count++
    }

    Remove-Item .\gcp_server_list$GCP_COUNT.json
    Remove-Item .\gcp_disk_list$GCP_COUNT.json

    if ($IMAGE -eq "centos7") {
        $IMAGE="centos-7"
        $IMAGE_PROJECT="centos-cloud"
    }

    if ($IMAGE -eq "ubuntu20") {
    $IMAGE="ubuntu-2004-lts"
    $IMAGE_PROJECT="ubuntu-os-cloud"
    }

    if ($IMAGE -eq "ubuntu18") {
    $IMAGE="ubuntu-1804-lts"
    $IMAGE_PROJECT="ubuntu-os-cloud"
    }

    if ($IMAGE -eq "win2016") {
    $IMAGE="windows-2016"
    $IMAGE_PROJECT="windows-cloud"
    }

    if ($IMAGE -eq "win2019") {
    $IMAGE="windows-2019"
    $IMAGE_PROJECT="windows-cloud"
    }
        
}


    ############################################################  NCP  ############################################################



      elseif ($CLOUD_TYPE -eq "NCP") {
          $cnt = $args[2]
          $NCP_COUNT = $args[3]
          $VPC_NO = $args[5]
          $SUBNET_NO = $args[6]
          $ACL_NO = $args[7]
          $ACG_NO = $args[8]
          $ACCESS_KEY = $myJson.cloud[$cloud_count].auth.access_key;
          $SECRET_KEY = $myJson.cloud[$cloud_count].auth.secret_key;
          $LOGINKEY = $myJson.cloud[$cloud_count].auth.login_key;
          $VM_NAME = $myJson.cloud[$cloud_count].vm[$cnt].vm_name;
          $ZONE = $myJson.cloud[$cloud_count].vm[$cnt].zone;
          $OS = $myJson.cloud[$cloud_count].vm[$cnt].os;
          $SCRIPT_NAME = $myJson.cloud[$cloud_count].vm[$cnt].scriptName;
          $PUBLICIP = $myJson.cloud[$cloud_count].vm[$cnt].associateWithPublicIp;
          $PROFILE_NAME = "DEFAULT";

          # Error Check (Script, Key)
    
          cmd /c ncloud vserver getInitScriptList > ncp_script_list$NCP_COUNT.json
          $NCP_SCRIPT_LIST = Get-Content ncp_script_list$NCP_COUNT.json | ConvertFrom-Json
          for ($i =0; $i -lt $NCP_SCRIPT_LIST.getInitScriptListResponse.totalRows; $i++) {
            if ($SCRIPT_NAME -eq $NCP_SCRIPT_LIST.getInitScriptListResponse.initScriptList[$i].initScriptName){
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same Script Name Already Exists") > ncp_result$NCP_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same Script Name Already Exists") > ncp_created$NCP_COUNT.txt
                Remove-Item .\ncp_script_list$NCP_COUNT.json
                exit 0 
                }   
          }
          Remove-Item .\ncp_script_list$NCP_COUNT.json

          if ($NCP_COUNT -eq 1){
          cmd /c ncloud vserver getLoginKeyList > ncp_key_list$NCP_COUNT.json
          $NCP_KEY_LIST = Get-Content ncp_key_list$NCP_COUNT.json | ConvertFrom-Json
          for ($i =0; $i -lt $NCP_KEY_LIST.getLoginKeyListResponse.totalRows; $i++) {
            if ($LOGINKEY -eq $NCP_KEY_LIST.getLoginKeyListResponse.loginKeyList[$i].keyName){
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same LoginKey Name Already Exists") > ncp_result$NCP_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail : Same LoginKey Name Already Exists") > ncp_created$NCP_COUNT.txt
                Remove-Item .\ncp_key_list$NCP_COUNT.json
                exit 0 
                }   
          }

          Remove-Item .\ncp_key_list$NCP_COUNT.json

        }
       if ($OS -eq "linux"){
            $IMAGE = "SW.VSVR.OS.LNX64.CNTOS.0708.B050"
            $NCP_LIN_COUNT = $args[4]
          

            cmd /c ncloud vserver createInitScript --regionCode $ZONE --initScriptName $SCRIPT_NAME --osTypeCode LNX --initScriptContent "#! /bin/bash"
            
          
            cmd /c ncloud vserver getInitScriptList > naver-lin-script$NCP_LIN_COUNT.json
          
            $script_info = Get-Content naver-lin-script$NCP_LIN_COUNT.json | ConvertFrom-Json
            for ($i =0; $i -lt $script_info.getInitScriptListResponse.totalRows; $i++) {
                if($script_info.getInitScriptListResponse.initScriptList[$i].initScriptName -eq $SCRIPT_NAME) {
                    $SCRIPT_NO = $script_info.getInitScriptListResponse.initScriptList[$i].initScriptNo
                    break
                }
            }
          Remove-Item .\naver-lin-script$NCP_LIN_COUNT.json
         }

         elseif ($OS -eq "windows"){
            $IMAGE = "SW.VSVR.OS.WND64.WND.SVR2019EN.B100"
            $NCP_WIN_COUNT = $args[4]
          
            cmd /c ncloud vserver createInitScript --regionCode $ZONE --initScriptName $SCRIPT_NAME --osTypeCode WND --initScriptContent "#! /bin/bash"
          
            cmd /c ncloud vserver getInitScriptList > naver-win-script$NCP_WIN_COUNT.json
          
            $script_info = Get-Content naver-win-script$NCP_WIN_COUNT.json | ConvertFrom-Json
            for ($i =0; $i -lt $script_info.getInitScriptListResponse.totalRows; $i++) {
                 if($script_info.getInitScriptListResponse.initScriptList[$i].initScriptName -eq $SCRIPT_NAME) {
                    $SCRIPT_NO = $script_info.getInitScriptListResponse.initScriptList[$i].initScriptNo
                    break
                }
            }
          
          Remove-Item .\naver-win-script$NCP_WIN_COUNT.json

       }
         
        # KEY FILE 생성
        if ($NCP_COUNT -eq 1){
            cmd /c ncloud vserver createLoginKey --keyName $LOGINKEY > .\$LOGINKEY.json
            $ncpkey = Get-Content .\$LOGINKEY.json | ConvertFrom-Json
            $ncpkey.createLoginKeyResponse.privateKey | Out-File -Encoding ASCII .\$LOGINKEY.pem
            Remove-Item .\$LOGINKEY.json

        }
    
}

       ############################################################  OpenStack  ############################################################


    elseif ($CLOUD_TYPE -eq "OPENSTACK") { 

        # auth
        $env:OS_AUTH_URL= $myJson.cloud[$cloud_count].auth.os_auth_url;
        $env:OS_USERNAME= $myJson.cloud[$cloud_count].auth.os_username
        $env:OS_PASSWORD= $myJson.cloud[$cloud_count].auth.os_password
        $env:OS_REGION_NAME= $myJson.cloud[$cloud_count].auth.os_region_name
        $env:OS_PROJECT_NAME= $myJson.cloud[$cloud_count].auth.os_project_name
        $env:OS_USER_DOMAIN_NAME= $myJson.cloud[$cloud_count].auth.os_user_domian_name
        $env:OS_PROJECT_DOMAIN_NAME= $myJson.cloud[$cloud_count].auth.os_project_domain_name
 


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
        for ($i =0; $i -lt $OPS_SERVER_LIST.length; $i++) {
            if ($VM_NAME -eq $OPS_SERVER_LIST[$i].Name){
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") > ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> Fail: Same VM Name Already Exists") > ops_created$OPS_COUNT.txt
                Remove-Item .\ops_server_list$OPS_COUNT.json
                exit 0
            }
        }

        #Openstack Disk List
        openstack volume list -f json > ops_volume_list$OPS_COUNT.json
        $OPS_VOLUME_LIST = Get-Content ops_volume_list$OPS_COUNT.json | ConvertFrom-Json
        for ($i =0; $i -lt $OPS_VOLUME_LIST.length; $i++) {
            if ($DISK_NAME -eq $OPS_VOLUME_LIST[$i].Name){
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $DISK_NAME + " ----------> Fail: Same Disk Name Already Exists") > ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $DISK_NAME + " ----------> Fail: Same Disk Name Already Exists") > ops_created$OPS_COUNT.txt
                Remove-Item .\ops_volume_list$OPS_COUNT.json
                exit 0
            }
        }

        #Openstack KeyPair List
        openstack keypair list -f json > ops_key_list$OPS_COUNT.json
        $OPS_KEY_LIST = Get-Content ops_key_list$OPS_COUNT.json | ConvertFrom-Json
        for ($i =0; $i -lt $OPS_KEY_LIST.length; $i++) {
            if ($KEY_NAME -eq $OPS_KEY_LIST[$i].Name){
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $KEY_NAME + " ----------> Fail: Same Key Name Already Exists") > ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $KEY_NAME + " ----------> Fail: Same Key Name Already Exists") > ops_created$OPS_COUNT.txt
                Remove-Item .\ops_key_list$OPS_COUNT.json
                exit 0
            }
        }

        Remove-Item .\ops_server_list$OPS_COUNT.json
        Remove-Item .\ops_volume_list$OPS_COUNT.json
        Remove-Item .\ops_key_list$OPS_COUNT.json
   
        if ($FLAVOR -eq 1){
          	$FLAVOR="m1.tiny"
        }
        elseif ($FLAVOR -eq 2){
          	$FLAVOR="m1.small"
        }
        elseif ($FLAVOR -eq 3){
          	$FLAVOR="m1.medium"
        }
        elseif ($FLAVOR -eq 4){
          	$FLAVOR="m1.large"
        }
        elseif ($FLAVOR -eq 5){
          	$FLAVOR="m1.xlarge"
        }

        if ($OS -eq "linux") {
          	$file = '.\ops_key.pem'
            if ( -not (Test-Path $file)){   
          			openstack keypair create $KEY_NAME --private-key ops-key.pem

            }
            if ($IMAGE -eq "centos7") {
              	$IMAGE = "centos7"
            }
              
              
            openstack server create --flavor $FLAVOR --image $IMAGE --network $NETWORK --key-name $KEY_NAME --user-data linux.sh $VM_NAME > output_ops$OPS_COUNT.txt
              
          }
        elseif ($OS -eq "windows"){
          	if ($IMAGE -eq "win2012"){
              	$IMAGE = "win2012"
            }
            openstack server create --flavor $FLAVOR --image $IMAGE --security-group $SECURITY_GROUP --network $NETWORK --user-data win.ps1 $VM_NAME > output_ops$OPS_COUNT.txt
            $pass =(Get-Content -Path .\win.ps1) |findstr PASSWORD=
            $PASSWORD = $pass.Replace("`"","").split("=")[1]
	
        }
        openstack volume create $DISK_NAME --size $DISK_SIZE
        openstack server add volume $VM_NAME $DISK_NAME
          
        if ($FLOATING_IP -eq "O"){
            openstack floating ip create --subnet public-sub public-network | findstr floating_ip_address > ops_ip$OPS_COUNT.txt
            (Get-Content -Path .\ops_ip$OPS_COUNT.txt) | foreach {	$token = $_ -split ' +'}
            $FLO_IP = $token[3]
              
            openstack server add floating ip $VM_NAME $FLO_IP
              
            if ($IMAGE -eq "centos7") {
              	if (type output_ops$OPS_COUNT.txt | findstr created) {
                  	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user : centos   ") > ops_result$OPS_COUNT.txt
                    Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user : centos   ") > ops_created$OPS_COUNT.txt
            
                }
                else {
                  	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> FAIL") > ops_result$OPS_COUNT.txt
                    Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> FAIL") > ops_created$OPS_COUNT.txt
                }
                  
                  
              }
            elseif ($OS -eq "windows"){
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created){
              	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user: Administrator    password: " + $PASSWORD) > ops_result$OPS_COUNT.txt
                  Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> SUCCESS    " + "user: Administrator    password: " + $PASSWORD) > ops_created$OPS_COUNT.txt
              	}
            else {
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> FAIL") > ops_result$OPS_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "  " + $FLO_IP + "   ----------> FAIL") > ops_created$OPS_COUNT.txt
                }
            }
          		
				Remove-Item ops_ip$OPS_COUNT.txt   
          }
          
        else {
          	if ($IMAGE -eq "centos7") {
              	if (Get-Content output_ops$OPS_COUNT.txt | findstr created) {
                  	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "   ----------> SUCCESS    " + "user : centos   ") > ops_result$OPS_COUNT.txt
                      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "   ----------> SUCCESS    " + "user : centos   ") > ops_created$OPS_COUNT.txt
           
                }
                else {
                  	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "   ----------> FAIL") > ops_result$OPS_COUNT.txt
                      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME  + "   ----------> FAIL") > ops_created$OPS_COUNT.txt
                }
            }
            elseif ($OS -eq "windows"){
            if (Get-Content output_ops$OPS_COUNT.txt | findstr created){
                	Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user: Administrator    password: ") > ops_result$OPS_COUNT.txt
                    Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "   ----------> SUCCESS    " + "user: Administrator    password: ") > ops_created$OPS_COUNT.txt
            }
            else {
                    Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") > ops_result$OPS_COUNT.txt
                    Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  ----------> FAIL") > ops_created$OPS_COUNT.txt
                }
            }
        }   
   			Remove-Item output_ops$OPS_COUNT.txt
              
        }
          
    

 if ($CLOUD_TYPE -eq "GCP"){
			
      gcloud auth activate-service-account $ACCOUNT --key-file=$ACCOUNT_KEY --project=$PROJECT
			
   if ($OS -eq "linux") {
       gcloud compute instances create $VM_NAME --metadata-from-file=startup-script=linux.sh --image-family=$IMAGE --image-project=$IMAGE_PROJECT --custom-cpu=$CPU --custom-memory=$MEMORY --zone=$ZONE > output_gcp$GCP_COUNT.txt
       ssh-keygen -t rsa -f $USER-gcp-key -C $USER -b 2048 -P """"
       $key_file_name = "$USER-gcp-key.pub"
       $key_content = Get-Content $key_file_name
			 gcloud compute project-info add-metadata --metadata=ssh-keys=$USER":"$key_content 
           for ($j =1; $j -lt $DISK_NUM + 1; $j++) {
                $dd = $DISK_NAME + $disk_count
                $disk_count++
                gcloud compute disks create $dd --zone=$ZONE --size=$DISK_SIZE --user-output-enabled=false
                gcloud compute instances attach-disk $VM_NAME --disk $dd
           }

       
       
       cmd /c "type output_gcp$GCP_COUNT.txt |findstr RUNNING > temp_gcp$GCP_COUNT.txt"
       
       $info = cmd /c "for /f "tokens=1,5 delims= " %i in (temp_gcp$GCP_COUNT.txt) do @echo %i %j"
       Write-Output "생성된 VM --------> $info"

       if (Get-Content output_gcp$GCP_COUNT.txt | findstr RUNNING){
                Write-Output ($CLOUD_TYPE + "  " + $info  + "  ----------> SUCCESS    " + "user : $USER   ") > gcp_result$GCP_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $info  + "  ----------> SUCCESS    " + "user : $USER   ") > gcp_created$GCP_COUNT.txt
                    }
                    else {
                Write-Output ($CLOUD_TYPE + "  " + $info + "  ----------> FAIL") > gcp_result$GCP_COUNT.txt
                Write-Output ($CLOUD_TYPE + "  " + $info + "  ----------> FAIL") > gcp_created$GCP_COUNT.txt
                    }


  
}
    elseif ($OS -eq "windows") {
       gcloud compute instances create $VM_NAME --metadata-from-file=windows-startup-script-ps1=win.ps1 --image-family=$IMAGE --image-project=$IMAGE_PROJECT --custom-cpu=$CPU --custom-memory=$MEMORY --zone=$ZONE > output_gcp$GCP_COUNT.txt
       

       for ($j =1; $j -lt $DISK_NUM + 1; $j++) {
            $dd = $DISK_NAME + $disk_count
            $disk_count++
            gcloud compute disks create $dd --zone=$ZONE --size=$DISK_SIZE --user-output-enabled=false
            gcloud compute instances attach-disk $VM_NAME --disk $dd
        }
       cmd /c "type output_gcp$GCP_COUNT.txt |findstr RUNNING > temp_gcp$GCP_COUNT.txt"

       $info = cmd /c "for /f "tokens=1,5 delims= " %i in (temp_gcp$GCP_COUNT.txt) do @echo %i %j"
       Write-Output "생성된 VM --------> $info"
       
       Start-Sleep 60
       Write-Output 'Y' | gcloud compute reset-windows-password $VM_NAME --zone=$ZONE --user=$USER > gcp_password$GCP_COUNT.txt
       $PASSWORD = Get-content gcp_password$GCP_COUNT.txt | select-string "password"
          
       
       if (Get-content output_gcp$GCP_COUNT.txt | findstr RUNNING){
            Write-Output ($CLOUD_TYPE + "  " + $info  + "  ----------> SUCCESS    " + "user : $USER   "  + $PASSWORD) > gcp_result$GCP_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $info  + "  ----------> SUCCESS    " + "user : $USER   "  + $PASSWORD) > gcp_created$GCP_COUNT.txt

       }
       else {
            Write-Output ($CLOUD_TYPE + "  " + $info + "  ----------> FAIL") > gcp_result$GCP_COUNT.txt
            Write-Output ($CLOUD_TYPE + "  " + $info + "  ----------> FAIL") > gcp_created$GCP_COUNT.txt
       }
       Remove-Item gcp_password$GCP_COUNT.txt
     }
    
    Remove-Item temp_gcp$GCP_COUNT.txt
    Remove-Item output_gcp$GCP_COUNT.txt
 }
       elseif ($CLOUD_TYPE -eq "NCP"){
      
          cmd /c ncloud vserver createServerInstances --regionCode $ZONE --serverImageProductCode $IMAGE --vpcNo $VPC_NO --subnetNo $SUBNET_NO --serverName $VM_NAME --networkInterfaceList "networkInterfaceOrder='0', accessControlGroupNoList=['$ACG_NO']" --initScriptNo $SCRIPT_NO --loginKeyName $LOGINKEY --associateWithPublicIp $PUBLICIP > output_ncp$NCP_COUNT.json
   
       
          cmd /c ncloud vserver getServerInstanceList > ncp_instance_list$NCP_COUNT.json
          $NCP_INSTANCE_LIST = Get-Content ncp_instance_list$NCP_COUNT.json | ConvertFrom-Json


            for ($k=0; $k -lt $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows; $k++) {
                if ($NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k].serverName -eq $VM_NAME){
                    $total = $NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows;
                    while ($true) {
                        cmd /c ncloud vserver getServerInstanceList > ncp_instance_list$NCP_COUNT.json
                        $NCP_INSTANCE_LIST = Get-Content ncp_instance_list$NCP_COUNT.json | ConvertFrom-Json
                        if ($NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k+$NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows-$total].publicIp -ne ""){
                            $INSTANCE_NO = $NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k+$NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows-$total].serverInstanceNo 
                            $PUBLIC_IP = $NCP_INSTANCE_LIST.getServerInstanceListResponse.serverInstanceList[$k+$NCP_INSTANCE_LIST.getServerInstanceListResponse.totalRows-$total].publicIp
                           
                            break
                            }
                        }
                    break
                }
            }
            Remove-Item ncp_instance_list$NCP_COUNT.json
      
            cmd /c ncloud vserver getRootPassword --regionCode $ZONE --serverInstanceNo $INSTANCE_NO --privateKey "file://.\/$LOGINKEY.pem" > naver-password$NCP_COUNT.json
            $password_info = Get-Content naver-password$NCP_COUNT.json | ConvertFrom-Json
            $PASSWORD = $password_info.getRootPasswordResponse.rootPassword
            Remove-Item naver-password$NCP_COUNT.json
            
    
  
    if (Get-Content output_ncp$NCP_COUNT.json | findstr serverName){
   		if ($OS -eq "linux") {
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: root    password: " + $PASSWORD) > ncp_result$NCP_COUNT.txt
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: root    password: " + $PASSWORD) > ncp_created$NCP_COUNT.txt
      }
      elseif ($OS -eq "windows"){
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: Administrator    password: " + $PASSWORD) > ncp_result$NCP_COUNT.txt
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  " + $PUBLIC_IP + "  -----------> SUCCESS   " + "user: Administrator    password: " + $PASSWORD) > ncp_created$NCP_COUNT.txt
      }
   }
   else {
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  -----------> FAIL ") > ncp_result$NCP_COUNT.txt
      Write-Output ($CLOUD_TYPE + "  " + $VM_NAME + "  -----------> FAIL ") > ncp_created$NCP_COUNT.txt
   }
   
    
    Remove-Item output_ncp$NCP_COUNT.json
    
   }




