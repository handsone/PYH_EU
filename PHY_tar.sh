#!/bin/bash
#set -x

usage(){
 echo "Usage: $0 filename"  
 echo "eg: ./PHY_tar.sh ac_phy.V100R100C001B001.tgz" 
 echo "eg: ./PHY_tar.sh  <path>/ac_phy.V100R100C001B001.tgz"
 echo "eg: bash <path>/PHY_tar.sh  <path>/ac_phy.V100R100C001B001.tgz"
 exit 1  
}

prefix="cnf95O_dpdk_bphy_phyc_pkg"
file_path=`realpath $1`
abs_path=${file_path%/*}
file_name=${file_path##*/}
#dir_name=${file_name%.*}

#string=${dir_name##*_}

[[ $# -ne 1 ]] && { usage ;} || filename=$1 
[[ -e $file_path ]] || { echo -e "filename:${file_path}  Not existed!" ; exit 1; }

version=${file_name##*phy.}
version=${version%.*}
tmp="_${version}"
#tar_name=${file_name/${tmp}}
tar_name=${prefix}.tgz

build_Id='1'
code='.*'
name='PHY'
vendor='ArrayComm'
bldName='PHY'
bldVersion=$version
id='1'
fileVersion=$version
Phy_md5=`md5sum $1 | awk '{print $1}' `

dir_name=${prefix}_${version}





echo "(1) Cretea Dir :${dir_name}"
[[ -d $dir_name ]] && { echo "    dir existed! remove it" ; rm -rf $dir_name ; }

mkdir $dir_name

[[ $? -eq 0 ]] && echo "    Create dir $dir_name suceess !" || { echo "    Create dir $dir_name fail ; exit 1 !" ; exit 1 ;}


echo "(2) Copy source tar($file_path) to dir $dir_name ;"
cd $dir_name 
cp $file_path  ${tar_name} 
[[ $? -eq 0 ]] && echo "    Copy source tar $file_path suceess !" || { echo "    Copy source tar $file_path fail !" ; exit 1; }

echo "(3) Create xmlfile manifest.xml to dir $dir_name ;"
echo -e  \
"<xml>
  <manifest version=\"1.0\">
    <products>
      <product build-Id=\"${build_Id}\" code=\"${code}\" name=\"${name}\" vendor=\"${vendor}\"/>
    </products>
    <builds>
      <build bldName=\"${bldName}\" bldVersion=\"${bldVersion}\" id=\"${id}\">
        <file checksum=\"${Phy_md5}\" fileName=\"${tar_name}\" fileVersion=\"${fileVersion}\" path=\"./${tar_name}\"/>
      </build>
    </builds>
  </manifest>
</xml>
    "  > manifest.xml 
[[ $? -eq 0 ]] && echo "    Create xmlfile suceess !" || { echo "    Create xmlfile  fail !" ; exit 1; }

echo "(4) Tar Dir $dir_name"
#zip -r ./${DirName}.zip  $path/$Dirname

[[ -e ../${dir_name}.tar.gz ]] && { echo -e "    New tar file {../${dir_name}.tar.gz existed! remove it " ; rm -rf ../${dir_name}.tar.gz ; } 
tar cvf ../${dir_name}.tar.gz  * 

[[ $? -eq 0 ]] &&  echo "    Tar dir success !"   || echo "    Tar dir fail !"
