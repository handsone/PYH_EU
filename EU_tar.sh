#!/usr/bin/bash
#set -x

pre_path='From_ArrayComm/001-Release/6cgEU/'
first_eu_path='first_eu'
cascade_eu_path='cascade_eu'
b_path='B_HW'
a_path='A_HW'

remote_first_A_path=$pre_path$first_eu_path
remote_first_B_path=$pre_path$first_eu_path/$b_path
remote_cascade_A_path=$pre_path$cascade_eu_path
remote_cascade_B_path=$pre_path$cascade_eu_path/$b_path

local_first_A_path=$first_eu_path/$a_path
local_first_B_path=$first_eu_path/$b_path
local_cascade_A_path=$cascade_eu_path/$a_path
local_cascade_B_path=$cascade_eu_path/$b_path

#sftp server login info 
IP=''
Usr=''
Password=''

#xml variable string  setting
build_Id='1'
code='AUE'
name='hub-6cg'
vendor='AC'
bldName='hub-6cg'
bldVersion=$version
id='1'
ohub_tar_name='O-HUB.netconf.tar.gz'
md5sum_fpga=''
md5sum_ohub=''

usage(){
 echo "Usage: $0 filename"  
 echo "eg: ./$0  AC-hub-6cg-0.68_test.zip" 
 echo "eg: ./$0 AC-hub-6cg-0.68_test.zip "
 echo "eg: bash <path>/$0  <path>/AC-hub-6cg-0.68_test.zip"
 exit 1  
}

func() {
    echo "Usage:"
    echo "test.sh [-i O_HUB -c package_code ] "
    echo "Description:"
    echo "O_HUB, o_hub zip package."
    echo "package_code,four bit code,from left to right, they represent (First A, FirstB, Cascade A,Cascade B)"
    echo "Use 0 or 1 to indicate if you want to package the version,eg, 1111, all four version are packaged"
    echo "0001, package Cascade B only "
    echo "0101, package Cascade B and First B "
    
    exit -1
}
 
 
while getopts 'i:c:h' OPT; do
    case $OPT in
        i) S_DIR="$OPTARG";;
        c) package_code="$OPTARG";;
        h) func;;
        ?) func;;
    esac
done


#[[ $# -ne 1 ]] && { usage ;} || o_hub_package_file=$1 

#o_hub_file_path=`realpath $1`
o_hub_file_path=`realpath $S_DIR`
o_hub_file_name=${file_path##*/}

script_path=`pwd`

[[ -e $o_hub_file_path ]] || { echo -e "filename:${o_hub_file_name}  Not existed!" ; exit 1; }

[[ ${#package_code} -ne  4 ]] && { echo "please enter four digits code, eg: 1111" ; exit 1; }


#exit

#Accoring to the path of parameter 1($1), get the latest directory files on the server under that path.
find_latest_dir() {
    path=$1

    expect ./findlatestdir.tcl  $path   > info
    latest_Dir=`cat info  | grep "2023" | awk 'NR==1{print $NF}' `
    echo $latest_Dir
}


#Download the lastest folder($2) on the remote server to the corresponding local path($1).
mkdir_dir_get_remoteDir(){

    Local_path=$1
    Remote_path=$2

    cd $script_path
    mkdir -p  $Local_path
    cd $Local_path
    
    echo "(3) download remote lastest directory "
    
    expect   << EOF
    set timeout 1200

    spawn sftp INT_FHGW@cdsftp.arraycomm.com 
    expect {
    "yes/no" { send "yes\r"; exp_continue}
    "password:" { send "BGygAgRdaztC\r" }
}

    expect  "sftp>" 
    send "cd $Remote_path \r";

    expect  "sftp>" 
    send "pwd \r";

    expect  "sftp>" 
    send "get -r * \r";

    expect "sftp>"
    send "exit \r"
    expect eof

EOF
}

find_down_lastet_dir(){
    cd $script_path
    remote_path=$1
    local_path=$2
    

    #find latest name
    latest_Dir=$(find_latest_dir  $remote_path)

    echo "(1) find remote latest dir: $latest_Dir"

    #concate prefix path 
    remote_latest_path=$remote_path/$latest_Dir

    echo "(2) get remote latest dir path: $remote_latest_path"


    #download remote latest
    mkdir_dir_get_remoteDir $local_path $remote_latest_path

}




#Reorganized FPGA packages  and repaceage,remote server path $1, local coresponding path $2. 
tar_fpga(){
    echo "(4) repackage FPGA tar"
    remote_path=$1
    local_path=$2

    #find version info , according lastest_Dir
    version=${latest_Dir#*-}
    version=${version%-*}
    fpga_dir=fpga_${version}

    cd ${script_path}/$local_path
    
    mkdir -p  ${fpga_dir}/lib/fireware
    mkdir -p  ${fpga_dir}/usr/bin

    bit_file=`ls bit  | grep "bit"`
    cp bit/$bit_file ${fpga_dir}/lib/fireware/ 
    md5sum_fpga=`md5sum bit/$bit_file | awk '{print $1}' `
    echo $md5sum_fpga > ${fpga_dir}/lib/fireware/${bit_file}.md5

    cp lib/* ${fpga_dir}/lib 
    cp app/* ${fpga_dir}/usr/bin 

    #tar -zcvf ${fpga_dir}.tar.gz  ${fpga_dir}  
    tar -zcf ${fpga_dir}.tar.gz  ${fpga_dir}  
}

ohub_tar(){
   

    echo "(5) repackage ohub tar"

    cd $script_path
    cd $local_path

    mkdir -p  O_HUB 
    md5sum_ohub=`md5sum $o_hub_file_path | awk '{print $1}'`

    unzip -d  O_HUB  -o $o_hub_file_path 
    cd  O_HUB
    #tar -zxvf O-HUB.netconf.tar.gz 
    tar -zxf O-HUB.netconf.tar.gz 
    #tar -zcvf O-HUB.netconf.tar.gz netconf  
    tar -zcf O-HUB.netconf.tar.gz netconf  
    cd ../
    mv O_HUB/O-HUB.netconf.tar.gz .
}

xml_create(){

echo "(6) create xml file"
echo -e  \
"<xml>
  <manifest version=\"1.0\">
    <products>
      <product build-Id=\"${build_Id}\" code=\"${code}\" name=\"${name}\" vendor=\"${vendor}\"/>
    </products>
    <builds>
      <build bldName=\"${bldName}\" bldVersion=\"${bldVersion}\" id=\"${id}\">
        <file checksum=\"${md5sum_ohub}\" fileName=\"${ohub_tar_name}\" fileVersion=\"${version}\" path=\"./${ohub_tar_name}\"/>
        <file checksum=\"${md5sum_fpga}\" fileName=\"fpga_${version}.tar.gz\" fileVersion=\"${version}\" path=\"./fpga_${version}.tar.gz\"/>
      </build>
    </builds>
  </manifest>
</xml>
    "  > manifest.xml 
}

packing(){


    find_down_lastet_dir $1 $2
    tar_fpga $1 $2
    ohub_tar
    xml_create
    echo "(7) zip compress AC-hub-6cg-${version}.zip"
    zip  AC-hub-6cg-${version}.zip  $ohub_tar_name fpga_${version}.tar.gz  manifest.xml
    rm -rf O_HUB O-HUB.netconf.tar.gz fpga_${version}.tar.gz manifest.xml lib  app bsp bit fpga_${version}
    echo "(8) target package save to ${2}/AC-hub-6cg-${version}.zip"

}

expect -v >/dev/null 2>&1
if [ $? -ne 0 ] ;then 
    echo "Command expect doesn't installed . Now trying install it"
    apt-get install expect -y
    if [ $? ] ; then 
        echo "Success install expect"
    else 
        echo "Fail install expect"
    fi
fi

package_code_split(){
    bit1=${package_code:0:1}
    bit2=${package_code:1:1}
    bit3=${package_code:2:1}
    bit4=${package_code:3:1}
    [[ $bit1 -eq 1 ]] && { echo "First A enable"; packing $remote_first_A_path $local_first_A_path;} 
    [[ $bit2 -eq 1 ]] && { echo "First B enable"; packing $remote_first_B_path $local_first_B_path;} 
    [[ $bit3 -eq 1 ]] && { echo "Cascade A enable"; packing $remote_cascade_A_path $local_cascade_A_path;} 
    [[ $bit4 -eq 1 ]] && { echo "Cascade B enable"; packing $remote_cascade_B_path $local_cascade_B_path;} 
}

package_code_split



