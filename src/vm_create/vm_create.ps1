# Get current path
$fullPathIncFileName = $MyInvocation.MyCommand.Definition     
$currentScriptName = $MyInvocation.MyCommand.Name           
$path = $fullPathIncFileName.Replace($currentScriptName, "") 


$JSON_NAME = $args[0] # JSON file name
$myJson = Get-Content "${path}$JSON_NAME" | ConvertFrom-Json 
$cloud_count = $myJson.cloud_platform_count # cloud platform count
$all_vm_count = $myJson.all_vm_count # all cloud vm count 
$GCP_COUNT = 1
$NCP_COUNT = 1
$OPS_COUNT = 1
$NCP_LIN_COUNT = 1
$NCP_WIN_COUNT = 1
$VPC_IP = "192.168.0.0/24" # VPC IP
$SUBNET_IP = "192.168.0.0/25" # Subnet IP
$sum_of_vm_count = 0


## Error Parameter Check

for ($i = 0; $i -lt $cloud_count; $i++) {  
    $sum_of_vm_count += $myJson.cloud[$i].vm_count;
}

# Count Parameter Check
if ($sum_of_vm_count -ne $all_vm_count) {
    Write-Output "The sum of the total number of VMs to be created and the number of each cloud platform does not match."
    exit 0
}


# OS parameter check 
for ($i = 0; $i -lt $cloud_count; $i++) {   
    $vm_count = $myJson.cloud[$i].vm_count;
    for ($j = 0; $j -lt $vm_count; $j++) {
        $OS = $myJson.cloud[$i].vm[$j].os;
        if ($OS -ne "linux" -and $OS -ne "windows") {
            "Error: OS name only can be linux or windows"
            exit 0 
        }
    }
}

# Image Parameter check 
for ($i = 0; $i -lt $cloud_count; $i++) {   
    $CLOUD_TYPE = $myJson.cloud[$i].cloud_type;
    $vm_count = $myJson.cloud[$i].vm_count;
    if ($CLOUD_TYPE -eq "GCP" -or $CLOUD_TPYE -eq "NCP"){ 
        for ($j = 0; $j -lt $vm_count; $j++) {
            $IMAGE = $myJson.cloud[$i].vm[$j].image;
            if ($IMAGE -ne "centos7" -and $IMAGE -ne "ubuntu18" -and $IMAGE -ne "ubuntu20" -and $IMAGE -ne "win2016" -and $IMAGE -ne "win2019") {
                "Error: GCP or NCP OS Image can be only [centos7, ubuntu18, ubuntu20, win2016, win2019]"
                exit 0 
            }
        }
    }
    elseif ($CLOUD_TYPE -eq "OPENSTACK"){
        for ($j = 0; $j -lt $vm_count; $j++) {
            $IMAGE = $myJson.cloud[$i].vm[$j].image;
            if ($IMAGE -ne "centos7" -and $IMAGE -ne "win2012") {
                "Error: Openstack OS Image can be only [centos7, win2012]"
                exit 0 
            }
        }
    }
}


Write-Output "------ $all_vm_count VM Creating ------"

for ($i = 0; $i -lt $cloud_count; $i++) {   
    $CLOUD_TYPE = $myJson.cloud[$i].cloud_type;
    $vm_count = $myJson.cloud[$i].vm_count;

    # GCP
    if ($CLOUD_TYPE -eq "GCP"){
        for ($j =0; $j -lt $vm_count; $j++){
        Start-Process "cmd.exe" "/k powershell -executionpolicy bypass -File ${path}vm_thread.ps1 $JSON_NAME $i $j $GCP_COUNT" # Run Thread
        $GCP_COUNT++
        }
    }

    # NCP
    elseif ($CLOUD_TYPE -eq "NCP") {
        $LOGINKEY = $myJson.cloud[$i].auth.login_key;
        $ZONE = "KR"
        for ($j = 0; $j -lt $vm_count; $j++) {
            $OS = $myJson.cloud[$i].vm[$j].os;
            $VPC_NAME = $myJson.cloud[$i].vm[$j].vpcName;
            $SUBNET_NAME = $myJson.cloud[$i].vm[$j].subnetName;
            

            #Get VPC List
            cmd /c "cd $path && .\ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json"
            $NCP_VPC_LIST = Get-Content "${path}ncp_vpc_list$NCP_COUNT.json" | ConvertFrom-Json
            
            # if NCP VPC number is 0 (no VPC in cloud)
            if ($NCP_VPC_LIST.getVpcListResponse.totalRows -eq 0) {     
                # Create VPC
                cmd /c "cd $path && .\ncloud vpc createVpc --regionCode $ZONE --vpcName $VPC_NAME --ipv4CidrBlock $VPC_IP | Out-Null"
                cmd /c "cd $path && .\ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json"
                $NCP_VPC_LIST = Get-Content "${path}ncp_vpc_list$NCP_COUNT.json" | ConvertFrom-Json 
                for ($k = 0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                    if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName) {
                        $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                        break
                    }
                }
            }
            else {
                    
                if ($NCP_VPC_LIST.getVpcListResponse.totalRows -eq 3) {# if NCP VPC number in cloud is already 3(max)  
                    $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[0].vpcNo # Use first one in cloud
                }

                # if VPC number is 1 or 2 
                else { 
                    # if VPC name already exists then use that one
                    if ($NCP_VPC_LIST.getVpcListResponse.vpcList.vpcName.Contains($VPC_NAME)) {
                        for ($k = 0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                            if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName) {
                                $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                                break
                            }      
                        }
                    }
         
                    else {
                        # if VPC name does not exists then create 
                        cmd /c "cd $path && .\ncloud vpc createVpc --regionCode $ZONE --vpcName $VPC_NAME --ipv4CidrBlock $VPC_IP" | Out-Null
                        cmd /c "cd $path && .\ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json"
                        $NCP_VPC_LIST = Get-Content "${path}ncp_vpc_list$NCP_COUNT.json" | ConvertFrom-Json 
                        for ($k = 0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                            if ($VPC_NAME -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcName) {
                                $VPC_NO = $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo
                                break
                            }
                        }
                    }
                }
            }
                
            # VPC READY? (Creating)
            for ($k = 0; $k -lt $NCP_VPC_LIST.getVpcListResponse.totalRows; $k++) {
                if ($VPC_NO -eq $NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcNo) {
                    while ($true) {
                        cmd /c "cd $path && .\ncloud vpc getVpcList > ncp_vpc_list$NCP_COUNT.json"
                        $NCP_VPC_LIST = Get-Content "${path}ncp_vpc_list$NCP_COUNT.json" | ConvertFrom-Json
                        if ($NCP_VPC_LIST.getVpcListResponse.vpcList[$k].vpcStatus.code -eq "RUN") {
                            break
                        }
                            
                    }
                    break
                }
            }

            # Get ACL Number
            cmd /c "cd $path && .\ncloud vpc getNetworkAclList --networkAclStatusCode RUN --vpcNo $VPC_NO > ncp_acl_list$NCP_COUNT.json"
                
            $NCP_ACL_LIST = Get-Content "${path}ncp_acl_list$NCP_COUNT.json" | ConvertFrom-Json
            for ($k = 0; $k -lt $NCP_ACL_LIST.getNetworkAclListResponse.totalRows; $k++) {
                if ($NCP_ACL_LIST.getNetworkAclListResponse.networkAclList[$k].vpcNo -eq $VPC_NO) {
                    $ACL_NO = $NCP_ACL_LIST.getNetworkAclListResponse.networkAclList[$k].networkAclNo
                    break
                } 
            }
        
            # Get Subnet List
            cmd /c "cd $path && .\ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json"
            $NCP_SUBNET_LIST = Get-Content "${path}ncp_subnet_list$NCP_COUNT.json" | ConvertFrom-Json

            # if NCP Subnet number is 0 (no Subnet in cloud)
            if ($NCP_SUBNET_LIST.getSubnetListResponse.totalRows -eq 0) {
                # Create Subnet
                cmd /c "cd $path && .\ncloud vpc createSubnet --regionCode $ZONE --zoneCode KR-1 --vpcNo $VPC_NO --subnetName $SUBNET_NAME --subnet $SUBNET_IP --networkAclNo $ACL_NO --subnetTypeCode PUBLIC --usageTypeCode GEN"  | Out-Null
                cmd /c "cd $path && .\ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json"
                $NCP_SUBNET_LIST = Get-Content "${path}ncp_subnet_list$NCP_COUNT.json" | ConvertFrom-Json
                for ($k = 0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                    if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO) {
                        $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo
                        break 
                    }
                }
            }
            else { 
                if ($NCP_SUBNET_LIST.getSubnetListResponse.totalRows -eq 3) { # if NCP Subnet number is already 3(max)  
                    for ($k = 0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                        if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO) {
                            $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo  
                            break 
                        }
                    }
                }
                else { # if NCP Subnet number is 1 or 2 

                    # if subnet name already exists then use that one
                    if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList.subnetName.Contains($SUBNET_NAME)) {
                        for ($k = 0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                            if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].vpcNo -eq $VPC_NO) {
                                $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo
                                break 
                            }
                        }
                    }
                    else {
                        # if subnet name does not exists then create 
                        cmd /c "cd $path && .\ncloud vpc createSubnet --regionCode $ZONE --zoneCode KR-1 --vpcNo $VPC_NO --subnetName $SUBNET_NAME --subnet $SUBNET_IP --networkAclNo $ACL_NO --subnetTypeCode PUBLIC --usageTypeCode GEN" | Out-Null  
                        cmd /c "cd $path && .\ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json"
                        $NCP_SUBNET_LIST = Get-Content "${path}ncp_subnet_list$NCP_COUNT.json" | ConvertFrom-Json
                        for ($k = 0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                            if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$i].subnetName -eq $SUBNET_NAME) {
                                $SUBNET_NO = $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo    
                                break 
                            }
                        }

                    }

                }
            }
        
            #SUBNET READY? (Creating)
            for ($k = 0; $k -lt $NCP_SUBNET_LIST.getSubnetListResponse.totalRows; $k++) {
                if ($SUBNET_NO -eq $NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetNo) {
                    while ($true) {
                        cmd /c "cd $path && .\ncloud vpc getSubnetList > ncp_subnet_list$NCP_COUNT.json"
                        $NCP_SUBNET_LIST = Get-Content "${path}ncp_subnet_list$NCP_COUNT.json" | ConvertFrom-Json
                        if ($NCP_SUBNET_LIST.getSubnetListResponse.subnetList[$k].subnetStatus.code -eq "RUN") {
                            break
                        }
                    }
                    break
                }
            }

            # Get ACG Number
            cmd /c "cd $path && .\ncloud vserver getAccessControlGroupList --regionCode $ZONE --vpcNo $VPC_NO > ncp_acg_list$NCP_COUNT.json"
            
            $NCP_ACG_LIST = Get-Content "${path}ncp_acg_list$NCP_COUNT.json" | ConvertFrom-Json
            for ($k = 0; $k -lt $NCP_ACG_LIST.getAccessControlGroupListResponse.totalRows; $k++) {
                if ($NCP_ACG_LIST.getAccessControlGroupListResponse.accessControlGroupList[$k].vpcNo -eq $VPC_NO) {
                    $ACG_NO = $NCP_ACG_LIST.getAccessControlGroupListResponse.accessControlGroupList[$k].accessControlGroupNo
                    break
                }
            }

            # Remove log file
            Remove-Item "${path}ncp_vpc_list$NCP_COUNT.json"
            Remove-Item "${path}ncp_acl_list$NCP_COUNT.json"
            Remove-Item "${path}ncp_subnet_list$NCP_COUNT.json"
            Remove-Item "${path}ncp_acg_list$NCP_COUNT.json"
        
            # Run Thread
            if ($OS -eq "linux") {
                Start-Process "cmd.exe" "/k powershell -executionpolicy bypass -File ${path}vm_thread.ps1 $JSON_NAME $i $j $NCP_COUNT $NCP_LIN_COUNT $VPC_NO $SUBNET_NO $ACL_NO $ACG_NO"   
                $NCP_LIN_COUNT++
            }
            elseif ($OS -eq "windows") {
                Start-Process "cmd.exe" "/k powershell -executionpolicy bypass -File ${path}vm_thread.ps1 $JSON_NAME $i $j $NCP_COUNT $NCP_WIN_COUNT $VPC_NO $SUBNET_NO $ACL_NO $ACG_NO"   
                $NCP_WIN_COUNT++
            }
               
            $NCP_COUNT++
        }
                 
    }
    
    elseif ($CLOUD_TYPE -eq "OPENSTACK"){
        for ($j =0; $j -lt $vm_count; $j++){
            Start-Process "cmd.exe" "/c powershell -executionpolicy bypass -File ${path}vm_thread.ps1 $JSON_NAME $i $j $OPS_COUNT"   
            $OPS_COUNT++
        }
    }
  
}
  
####################################################################### Creating VM #######################################################################
  
while ($true) {
    
    $gcp_total =  Get-ChildItem $path -File -filter ".\gcp_result*.txt" |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}
    $ncp_total =  Get-ChildItem $path -File -filter ".\ncp_result*.txt" |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}
    $ops_total =  Get-ChildItem $path -File -filter ".\ops_result*.txt" |Where-Object {$_.LastWriteTime} | Measure-Object | ForEach-Object{$_.Count}


    for ($i = 0; $i -lt $cloud_count; $i++) {  
        $CLOUD_TYPE = $myJson.cloud[$i].cloud_type;
        $vm_count = $myJson.cloud[$i].vm_count; 
        if ($CLOUD_TYPE -eq "GCP"){
            for ($j=1; $j -le $vm_count; $j++){
                if ((Test-Path ${path}gcp_created$j.txt)){
                    while($true){
                        if (Get-Content ${path}gcp_created$j.txt){ # if Content exists
                            # Print NCP VM Info
                            $output = $(Get-Content ${path}gcp_created$j.txt)
                            Write-Output $output
                            Remove-Item ${path}gcp_created$j.txt
                            break
                        }
                    }
                }
            }
        }
        elseif ($CLOUD_TYPE -eq "NCP"){
            for ($j=1; $j -le $vm_count; $j++){
                if ((Test-Path ${path}ncp_created$j.txt)){
                    while($true){
                        if (Get-Content ${path}ncp_created$j.txt){ # if Content exists
                            # Print NCP VM Info
                            $output = $(Get-Content ${path}ncp_created$j.txt)
                            Write-Output $output
                            Remove-Item ${path}ncp_created$j.txt
                            break
                        }
                    }
                }
            }
        }
        elseif ($CLOUD_TYPE -eq "OPENSTACK"){
            for ($j=1; $j -le $vm_count; $j++){
                if ((Test-Path ${path}ops_created$j.txt)){
                    while($true){
                        if (Get-Content ${path}ops_created$j.txt){ # if Content exists
                            # Print NCP VM Info
                            $output = $(Get-Content ${path}ops_created$j.txt)
                            Write-Output $output
                            Remove-Item ${path}ops_created$j.txt
                            break
                        }
                    }
                }
            }
        }
    }

    # if log file number equals vm_count and created log file(print vm info) does not exist then break
    if (-not (Test-Path ${path}gcp_created*.txt) -and -not (Test-Path ${path}ncp_created*.txt) -and -not (Test-Path ${path}ops_created*.txt) -and (($gcp_total + $ncp_total + $ops_total) -eq $all_vm_count)) {
        break
    }
    Start-Sleep 1
}


Remove-Item "${path}gcp_result*.txt"
Remove-Item "${path}ncp_result*.txt"
Remove-Item "${path}ops_result*.txt"


