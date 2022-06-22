
$JSON_NAME = $args[0]
$myJson = Get-Content $args[0] | ConvertFrom-Json
$cloud_count = $myJson.cloud_platform_count
$all_vm_count = $myJson.all_vm_count
$GCP_COUNT = 1
$NCP_COUNT = 1
$OPS_COUNT = 1
$NCP_LIN_COUNT = 1
$NCP_WIN_COUNT = 1
$VPC_IP = "192.168.0.0/24"
$SUBNET_IP = "192.168.0.0/25"
$sum_of_vm_count = 0
for ($i =0; $i -lt $cloud_count; $i++) {  
    $sum_of_vm_count += $myJson.cloud[$i].vm_count;
}
if ($sum_of_vm_count -ne $all_vm_count){
    Write-Output "생성하고자 하는 VM 총 개수와 각 클라우드 플랫폼의 개수의 합이 맞지 않습니다."
    exit 0
}



Write-Output "------ $all_vm_count VM Creating ------"

for ($i =0; $i -lt $cloud_count; $i++) {   
    $CLOUD_TYPE = $myJson.cloud[$i].cloud_type;
    $vm_count = $myJson.cloud[$i].vm_count;

        # GCP
        if ($CLOUD_TYPE -eq "GCP"){
            for ($j =0; $j -lt $vm_count; $j++){
            Start-Process "cmd.exe" "/c powershell -executionpolicy bypass -File .\vm_creating.ps1 $JSON_NAME $i $j $GCP_COUNT"
            $GCP_COUNT++
            }
        }

        # NCP
        elseif ($CLOUD_TYPE -eq "NCP") {
            $LOGINKEY = $myJson.cloud[$cloud_count].auth.login_key;

            for ($j =0; $j -lt $vm_count; $j++){
                $ZONE = $myJson.cloud[$i].vm[$j].zone;
                $OS = $myJson.cloud[$i].vm[$j].os;
                $VPC_NAME = $myJson.cloud[$i].vm[$j].vpcName;
                $SUBNET_NAME = $myJson.cloud[$i].vm[$j].subnetName;

                #VPC
                cmd /c ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json
                $NCP_VPC_LIST = Get-Content ncp_vpc_list$NCP_COUNT.json | ConvertFrom-Json 
                if ($NCP_VPC_LIST.getVpcListResponse.totalRows -eq 0){     
                    
                     cmd /c ncloud vpc createVpc --regionCode $ZONE --vpcName $VPC_NAME --ipv4CidrBlock $VPC_IP | Out-Null
                     cmd /c ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json
                     $NCP_VPC_LIST = Get-Content ncp_vpc_list$NCP_COUNT.json | ConvertFrom-Json 
                     for ($k =0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                         if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName){
                             $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                             break
                         }
                     }
                }
                else {
                    
                     if ($NCP_VPC_LIST.getVpcListResponse.totalRows -eq 3){
                         $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[0].vpcNo
                     }
                     else {
                        
                         if ($NCP_VPC_LIST.getVpcListResponse.vpcList.vpcName.Contains($VPC_NAME)){
                             for ($k =0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                                 if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName){
                                     $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                                     break
                                 }      
                             }
                         }
         
                         else {
                             cmd /c ncloud vpc createVpc --regionCode $ZONE --vpcName $VPC_NAME --ipv4CidrBlock $VPC_IP | Out-Null
                             cmd /c ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json
                             $NCP_VPC_LIST = Get-Content ncp_vpc_list$NCP_COUNT.json | ConvertFrom-Json 
                             for ($k =0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                                 if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName){
                                     $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                                     break
                                     }
                                 }
                             }
                         }
                     }
                
                     # VPC READY?
                for ($k =0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                    if ($VPC_NO -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo){
                        while ($true) {
                            cmd /c ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json
                            $NCP_VPC_LIST = Get-Content ncp_vpc_list$NCP_COUNT.json | ConvertFrom-Json
                            if ($NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcStatus.code -eq "RUN"){
                                break
                                }
                            
                            }
                            break
                        }
                    }

                # ACL
                
                cmd /c ncloud vpc getNetworkAclList --networkAclStatusCode RUN --vpcNo $VPC_NO > ncp_acl_list$NCP_COUNT.json
                
                $NCP_ACL_LIST = Get-Content ncp_acl_list$NCP_COUNT.json | ConvertFrom-Json
                for ($k =0; $k -lt $NCP_ACL_LIST.getNetworkAclListResponse.totalRows; $k++) {
                        if ($NCP_ACL_LIST.getNetworkAclListResponse.networkAclList[$k].vpcNo -eq $VPC_NO){
                            $ACL_NO = $NCP_ACL_LIST.getNetworkAclListResponse.networkAclList[$k].networkAclNo
                            break
                    } 
                }
        
                # Subnet
                cmd /c ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json
                $NCP_SUBNET_LIST = Get-Content ncp_subnet_list$NCP_COUNT.json | ConvertFrom-Json

                if ($NCP_SUBNET_LIST.getSubnetListResponse.totalRows -eq 0){
                    cmd /c ncloud vpc createSubnet --regionCode $ZONE --zoneCode KR-1 --vpcNo $VPC_NO --subnetName $SUBNET_NAME --subnet $SUBNET_IP --networkAclNo $ACL_NO --subnetTypeCode PUBLIC --usageTypeCode GEN  | Out-Null
                    cmd /c ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json
                    $NCP_SUBNET_LIST = Get-Content ncp_subnet_list$NCP_COUNT.json | ConvertFrom-Json
                    for ($k =0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                        if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO){
                            $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo
                            break 
                        }
                    }
                }
                else {
                    if ($NCP_SUBNET_LIST.getSubnetListResponse.totalRows -eq 3){
                        for ($k =0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                            if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO){
                                $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo  
                                break 
                            }
                        }
                    }
                    else {
                        if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList.subnetName.Contains($SUBNET_NAME)){
                            for ($k =0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                                if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO){
                                    $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo
                                    break 
                                }
                            }
                        }
                        else {
                            cmd /c ncloud vpc createSubnet --regionCode $ZONE --zoneCode KR-1 --vpcNo $VPC_NO --subnetName $SUBNET_NAME --subnet $SUBNET_IP --networkAclNo $ACL_NO --subnetTypeCode PUBLIC --usageTypeCode GEN | Out-Null  
                            cmd /c ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json
                            $NCP_SUBNET_LIST = Get-Content ncp_subnet_list$NCP_COUNT.json | ConvertFrom-Json
                            for ($k =0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                                if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$i].subnetName -eq $SUBNET_NAME){
                                    $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo    
                                    break 
                                }
                            }

                        }

                    }
                }
        
                #SUBNET READY?
                for ($k =0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                    if ($SUBNET_NO -eq $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo){
                        while ($true) {
                            cmd /c ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json
                            $NCP_SUBNET_LIST = Get-Content ncp_subnet_list$NCP_COUNT.json | ConvertFrom-Json
                            if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetStatus.code -eq "RUN"){
                                break
                                }
                            }
                            break
                        }
                    }

                # ACG 

                cmd /c ncloud vserver getAccessControlGroupList --regionCode $ZONE --vpcNo $VPC_NO > ncp_acg_list$NCP_COUNT.json
            
                $NCP_ACG_LIST = Get-Content ncp_acg_list$NCP_COUNT.json | ConvertFrom-Json
                for ($k=0; $k -lt $NCP_ACG_LIST.getAccessControlGroupListResponse.totalRows; $k++) {
                    if($NCP_ACG_LIST.getAccessControlGroupListResponse.accessControlGroupList[$k].vpcNo -eq $VPC_NO){
                        $ACG_NO = $NCP_ACG_LIST.getAccessControlGroupListResponse.accessControlGroupList[$k].accessControlGroupNo
                        break
                    }
                }

                Remove-Item .\ncp_vpc_list$NCP_COUNT.json
                Remove-Item .\ncp_acl_list$NCP_COUNT.json
                Remove-Item .\ncp_subnet_list$NCP_COUNT.json
                Remove-Item .\ncp_acg_list$NCP_COUNT.json
        

                if ($OS -eq "linux"){
                    Start-Process "cmd.exe" "/c powershell -executionpolicy bypass -File .\vm_creating.ps1 $JSON_NAME $i $j $NCP_COUNT $NCP_LIN_COUNT $VPC_NO $SUBNET_NO $ACL_NO $ACG_NO"   
                    $NCP_LIN_COUNT++
                }
                elseif($OS -eq "windows"){
                    Start-Process "cmd.exe" "/c powershell -executionpolicy bypass -File .\vm_creating.ps1 $JSON_NAME $i $j $NCP_COUNT $NCP_WIN_COUNT $VPC_NO $SUBNET_NO $ACL_NO $ACG_NO"   
                    $NCP_WIN_COUNT++
                }
               
                $NCP_COUNT++
            }
            
           
        }
        #OPENSTACK
		elseif ($CLOUD_TYPE -eq "OPENSTACK"){
            for ($j =0; $j -lt $vm_count; $j++){
                Start-Process "cmd.exe" "/c powershell -executionpolicy bypass -File .\vm_creating.ps1 $JSON_NAME $i $j $OPS_COUNT"   
                $OPS_COUNT++
            }
        }
  
  }
  
  while($true) {
    
    $gcp_total =  Get-ChildItem .\  -File -filter gcp_result*.txt |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}
    $ncp_total =  Get-ChildItem .\  -File -filter ncp_result*.txt |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}
    $ops_total =  Get-ChildItem .\  -File -filter ops_result*.txt |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}
    
    $created_file_gcp = '.\gcp_created*.txt'
    $created_file_ncp = '.\ncp_created*.txt'
    $created_file_ops = '.\ops_created*.txt'
    
    if ((Test-Path $created_file_gcp)){
    	Write-Output $(Get-Content $created_file_gcp)
        Remove-Item $created_file_gcp
    }
    elseif ((Test-Path $created_file_ncp)){
    	Write-Output $(Get-Content $created_file_ncp)
        Remove-Item $created_file_ncp
    }
    elseif ((Test-Path $created_file_ops)){
    	Write-Output $(Get-Content $created_file_ops)
        Remove-Item $created_file_ops
    }
    
    if (($gcp_total + $ncp_total + $ops_total) -eq $all_vm_count) {
          break
    }
    
  }

Remove-Item gcp_result*.txt
Remove-Item ncp_result*.txt
Remove-Item ops_result*.txt

if ((Test-Path "$LOGINKEY.pem")){
    Remove-Item $LOGINKEY.pem 
}

