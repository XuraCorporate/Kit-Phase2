#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#####
# Function to give the usage help
#####
function input_error_log {
	echo -e ${RED}
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete/Replace> <CMS/LVU/OMU/VM-ASU/MAU> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/${_UNITLOWER}"] [StackName - default ${_UNITLOWER}]"
}

#####
# Function to exit in case of error
#####
function exit_for_error {
	#####
	# The message to print
	#####
        _MESSAGE=$1

	#####
	# If perform a change directory in case something has failed in order to not be in deploy dir
	#####
        _CHANGEDIR=$2

	#####
	# If hard "exit 1"
	# If break "break"
	# If soft no exit
	#####
	_EXIT=${3-hard}
        if ${_CHANGEDIR}
        then
                cd ${_CURRENTDIR}
        fi
	if [[ "${_EXIT}" == "hard" ]]
	then
		echo -e "${RED}${_MESSAGE}${NC}"
        	exit 1
	elif [[ "${_EXIT}" == "break" ]]
	then
		echo -e "${RED}${_MESSAGE}${NC}"
		break
	elif [[ "${_EXIT}" == "soft" ]]
	then
		echo -e "${YELLOW}${_MESSAGE}${NC}"
	fi
}

#####
# Function to Create CMS Unit
#####
function create_update_cms {
	echo "Not yet implemented."
	
    #####
	# merge 2 text files
	#######
	BashFile=cms_software_config.sh
	IniFile=globalConf.ini
	DestFile=script/cms_Application_config.sh
	perl -e 'open(f1,"<$ARGV[0]");@b=<f1>; close(f1);print @b;open(f2,"<$ARGV[1]");@c=<f2>;close(f2);for $i (@b) {$i =~ s/$ARGV[2]/@c/ ; print $i}' $BashFile  $IniFile __ApplicationConf__ > $DestFile
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load the CSV Files
		#####
	        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} > ../${_ADMINCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} > ../${_SZCSVFILE}.tmp
			sed -n -e ${_INSTACE}p ../${_SIPINTCSVFILE} > ../${_SIPINTCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_MEDIACSVFILE} > ../${_MEDIACSVFILE}.tmp
			
			
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
			exec 5<../${_SIPINTCSVFILE}.tmp
			exec 6<../${_MEDIACSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4 && _SIP_PORTID _SIP_MAC _SIP_IP <&5 && _MEDIA_PORTID _MEDIA_MAC _MEDIA_IP <&6
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_cms Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp
			cat ../${_SIPINTCSVFILE}|tail -n+${_INSTACE} > ../${_SIPINTCSVFILE}.tmp
	        cat ../${_MEDIACSVFILE}|tail -n+${_INSTACE} > ../${_MEDIACSVFILE}.tmp

		#####
		# Verify that in the CSV files there are the same amout of Ports
		#####
		_ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
		_SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
		echo -e -n "Validating number of Ports ...\t\t"
		if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
		then
			exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
			exec 5<../${_SIPINTCSVFILE}.tmp
			exec 6<../${_MEDIACSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4 && _SIP_PORTID _SIP_MAC _SIP_IP <&5 && _MEDIA_PORTID _MEDIA_MAC _MEDIA_IP <&6
	        do

			#####
			# After the checks create the OMU with the right parameters
			#####
			init_cms ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	exec 5<&-
	exec 6<&-
	rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp ../${_SIPINTCSVFILE}.tmp ../${_MEDIACSVFILE}.tmp

}

#####
# Function to Create LVU Unit
#####
function create_update_lvu {
    #####
	# merge 2 text files
	#######
	BashFile=omu_software_config.sh
	IniFile=globalConf.ini
	DestFile=script/lvu_Application_config.sh
	perl -e 'open(f1,"<$ARGV[0]");@b=<f1>; close(f1);print @b;open(f2,"<$ARGV[1]");@c=<f2>;close(f2);for $i (@b) {$i =~ s/$ARGV[2]/@c/ ; print $i}' $BashFile  $IniFile __ApplicationConf__ > $DestFile
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load the CSV Files
		#####
	        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} > ../${_ADMINCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} > ../${_SZCSVFILE}.tmp
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_lvu Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp

		#####
		# Verify that in the CSV files there are the same amout of Ports
		#####
		_ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
		_SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
		echo -e -n "Validating number of Ports ...\t\t"
		if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
		then
			exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do

			#####
			# After the checks create the OMU with the right parameters
			#####
			init_lvu ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
	#echo "Not yet implemented."
}

#####
# Function to Create OMU Unit
#####
function create_update_omu {
    #####
	# merge 2 text files
	#######
	BashFile=omu_software_config.sh
	IniFile=globalConf.ini
	DestFile=script/omu_Application_config.sh
	perl -e 'open(f1,"<$ARGV[0]");@b=<f1>; close(f1);print @b;open(f2,"<$ARGV[1]");@c=<f2>;close(f2);for $i (@b) {$i =~ s/$ARGV[2]/@c/ ; print $i}' $BashFile  $IniFile __ApplicationConf__ > $DestFile
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load the CSV Files
		#####
	        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} > ../${_ADMINCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} > ../${_SZCSVFILE}.tmp
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_omu Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp

		#####
		# Verify that in the CSV files there are the same amout of Ports
		#####
		_ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
		_SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
		echo -e -n "Validating number of Ports ...\t\t"
		if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
		then
			exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do

			#####
			# After the checks create the OMU with the right parameters
			#####
			init_omu ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the OMU Unit
#####
function init_omu {
	_COMMAND=${1}

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
		port_validation ${_SZ_PORTID} ${_SZ_MAC}

		#####
		# Update the port securtiy group
		#####
		neutron port-update --no-security-groups ${_ADMIN_PORTID}
		neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
		neutron port-update --no-security-groups ${_SZ_PORTID}

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - Anti-affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ../templates/${_UNITLOWER}.yaml \
		 --environment-file ../environment/common.yaml \
		 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
		 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTACE=$(($_INSTACE+1))
}

#####
# Function to initialize the creation of the LVU Unit
#####
function init_lvu {
	_COMMAND=${1}

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
		port_validation ${_SZ_PORTID} ${_SZ_MAC}

		#####
		# Update the port securtiy group
		#####
		neutron port-update --no-security-groups ${_ADMIN_PORTID}
		neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
		neutron port-update --no-security-groups ${_SZ_PORTID}

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - Anti-affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ../templates/${_UNITLOWER}.yaml \
		 --environment-file ../environment/common.yaml \
		 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
		 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTACE=$(($_INSTACE+1))
}

#####
# Function to initialize the creation of the VM-ASU Unit
#####
function init_asu {
	_COMMAND=${1}

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
		port_validation ${_SZ_PORTID} ${_SZ_MAC}

		#####
		# Update the port securtiy group
		#####
		neutron port-update --no-security-groups ${_ADMIN_PORTID}
		neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
		neutron port-update --no-security-groups ${_SZ_PORTID}

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - Anti-affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ../templates/${_UNITLOWER}.yaml \
		 --environment-file ../environment/common.yaml \
		 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
		 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTACE=$(($_INSTACE+1))
}

#####
# Function to initialize the creation of the CMS Unit
#####
function init_cms {
	_COMMAND=${1}

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
		port_validation ${_SZ_PORTID} ${_SZ_MAC}
		port_validation ${_SIP_PORTID} ${_SIP_MAC}
		port_validation ${_MEDIA_PORTID} ${_MEDIA_MAC}
		
		#####
		# Update the port securtiy group
		#####
		neutron port-update --no-security-groups ${_ADMIN_PORTID}
		neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
		neutron port-update --no-security-groups ${_SZ_PORTID}
		############################
		#  Todo: 
		#      1.  Update security group for cms sip / media 
		#      2.  Change ! Security group of SZ should be specified for each Unit Type. (add to environment Security group per UnitType )

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - Anti-affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ../templates/${_UNITLOWER}.yaml \
		 --environment-file ../environment/common.yaml \
		 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "sip_network_port=${_SIP_PORTID}" \
		 --parameters "sip_network_mac=${_SIP_MAC}" \
		 --parameters "sip_network_ip=${_SIP_IP}" \
		 --parameters "media_network_port=${_MEDIA_PORTID}" \
		 --parameters "media_network_mac=${_MEDIA_MAC}" \
		 --parameters "media_network_ip=${_MEDIA_IP}" \
		 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
		 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTACE=$(($_INSTACE+1))
}

#####
# Function to Create VM-ASU Unit
#####
function create_update_vmasu {
	 #####
	# merge 2 text files
	#######
	BashFile=omu_software_config.sh
	IniFile=globalConf.ini
	DestFile=script/vmasu_Application_config.sh
	perl -e 'open(f1,"<$ARGV[0]");@b=<f1>; close(f1);print @b;open(f2,"<$ARGV[1]");@c=<f2>;close(f2);for $i (@b) {$i =~ s/$ARGV[2]/@c/ ; print $i}' $BashFile  $IniFile __ApplicationConf__ > $DestFile
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load the CSV Files
		#####
	        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} > ../${_ADMINCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} > ../${_SZCSVFILE}.tmp
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_asu Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp

		#####
		# Verify that in the CSV files there are the same amout of Ports
		#####
		_ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
		_SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
		echo -e -n "Validating number of Ports ...\t\t"
		if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
		then
			exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do

			#####
			# After the checks create the OMU with the right parameters
			#####
			init_asu ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to Create MAU Unit
#####
function create_update_mau {
	echo "Not yet implemented."
}

#####
# Function to valide various things
# - Given Flavor
# - Given Image Name and Image ID
#####
function validation {
	_UNITTOVALIDATE=$1
	_IMAGE=$(cat ../environment/common.yaml|grep "$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_image"|grep -v image_id|awk '{print $2}'|sed "s/\"//g")
	_IMAGEID=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_image_id'/ {print $2}'|sed "s/\"//g")
	_FLAVOR=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_flavor_name'/ {print $2}'|sed "s/\"//g")

	#####
	# Check the Image Id and the Image Name is the same 
	#####
	echo -e -n "Validating chosen Image ${_IMAGE} ...\t\t"
	glance image-show ${_IMAGEID}|grep "${_IMAGE}" >/dev/null 2>&1 || exit_for_error "Error, Image for Unit ${_UNITTOVALIDATE} not present or mismatch between ID and Name." true hard
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check the given flavor is available
	#####
	echo -e -n "Validating chosen Flavor ${_FLAVOR} ...\t\t"
	nova flavor-show "${_FLAVOR}" >/dev/null 2>&1 || exit_for_error "Error, Flavor for Unit ${_UNITTOVALIDATE} not present." true hard
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Function to valide the Network
# - Does it exist?
# - Does the given VLAN ID is valid?
#####
function net_validation {
        _UNITTOVALIDATE=$1
	_NET=$2
        _NETWORK=$(cat ../environment/common.yaml|awk '/'${_NET}'_network_name/ {print $2}'|sed "s/\"//g")
        _VLAN=$(cat ../environment/common.yaml|awk '/'${_NET}'_network_vlan/ {print $2}'|sed "s/\"//g")

	#####
	# Check the Network exist
	#####
	echo -e -n "Validating chosen Network ${_NETWORK} ...\t\t"
        neutron net-show "${_NETWORK}" >/dev/null 2>&1 || exit_for_error "Error, ${_NET} Network is not present." true hard
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check the VLAN ID is corret
	# - none
	# - between 1 to 4096
	#####
	echo -e -n "Validating VLAN ${_VLAN} for chosen Network ${_NETWORK} ...\t\t"
        if [[ "${_VLAN}" != "none" ]]
        then
                if (( ${_VLAN} < 1 || ${_VLAN} > 4096 ))
                then
                        exit_for_error "Error, The VLAN ID ${_VLAN} for the ${_NET} Network is not valid. Acceptable values: \"none\" or a number between 1 to 4096." true hard
                fi
        fi
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Function to valide the given Neutron Port
# - Does it exist?
# - Is it available?
# - Does the given Mac Address match with the Port Mac Address?
#####
function port_validation {
	_PORT=$1
	_MAC=$2

	#####
	# Check of the port exist
	#####
	echo -e -n "Validating Port ${_PORT} exist ...\t\t"
	neutron port-show ${_PORT} >/dev/null 2>&1 || exit_for_error "Error, Port with ID ${_PORT} does not exist." false break
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check if the port is in use
	#####
	echo -e -n "Validating Port ${_PORT} is not in use ...\t\t"
	if [[ "$(neutron port-show --field device_id --format value ${_PORT})" != "" ]]
	then
		exit_for_error "Error, Port with ID ${_PORT} is in use." false break
	fi
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check if the Mac address is the same from the given one
	#####
	echo -e -n "Validating Port ${_PORT} MAC Address ...\t\t"
	if [[ "$(neutron port-show --field mac_address --format value ${_PORT})" != "${_MAC}" ]]
	then
		exit_for_error "Error, Port with ID ${_PORT} has a different MAC Address than the one provided into the CSV file." false break
	fi
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Write the input args into variable
#####
_RCFILE=$1
_ACTION=$2
_UNIT=$3
_UNITLOWER=$(echo "${_UNIT}" | awk '{print tolower($0)}')
_INSTACE=${4-1}
_CSVFILEPATH=${5-environment/${_UNITLOWER}}
_STACKNAME=${6-${_UNITLOWER}}

#####
# Verity if any input values are present
#####
if [[ "$1" == "" ]]
then
	input_error_log
        echo -e ${NC}
	exit 1
fi

#####
# Check RC File
#####
if [ ! -e ${_RCFILE} ]
then
	input_error_log
	echo "OpenStack RC environment file does not exist."
        echo -e ${NC}
	exit 1
fi

#####
# Check Action Name
#####
if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" && "${_ACTION}" != "Replace" ]]
then
	input_error_log
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "\"Replace\" - To replace a specific stack - This will delete it and then recreate it"
        echo -e ${NC}
	exit 1
fi

#####
# Check Unit Name
#####
if [[ "${_UNIT}" != "CMS" && "${_UNIT}" != "LVU" && "${_UNIT}" != "OMU" && "${_UNIT}" != "VM-ASU" && "${_UNIT}" != "MAU" ]]
then
	input_error_log
	echo "Unit type non valid."
	echo "It must be in the following format:"
	echo "\"CMS\""
	echo "\"LVU\""
	echo "\"OMU\""
	echo "\"VM-ASU\""
	echo "\"MAU\""
        echo -e ${NC}
	exit 1
fi

#####
# Just write into variables the CSV Files
#####
_ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
_SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)
_SIPINTCSVFILE=$(echo ${_CSVFILEPATH}/sip.csv)
_MEDIACSVFILE=$(echo ${_CSVFILEPATH}/media.csv)

#####
# Check if the Admin CSV File
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
echo -e -n "Verifing if Admin CSV file is good ...\t\t"
if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Admin Network with mapping PortID,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Check if the Secure Zone CSV File except for the MAU Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e -n "Verifing if Secure Zone CSV file is good ...\t\t"
fi
if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ] && [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Check if the SIP CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifing if SIP CSV file is good ...\t\t"
fi
if [ ! -f ${_SIPINTCSVFILE} ] || [ ! -r ${_SIPINTCSVFILE} ] || [ ! -s ${_SIPINTCSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for SIP Internal Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Check if the Media CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifing if Media CSV file is good ...\t\t"
fi
if [ ! -f ${_MEDIACSVFILE} ] || [ ! -r ${_MEDIACSVFILE} ] || [ ! -s ${_MEDIACSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Media Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Unload any previous loaded environment file
#####
for _ENV in $(env|grep ^OS|awk -F "=" '{print $1}')
do
        unset ${_ENV}
done

#####
# Load environment file
#####
echo -e -n "Loading environment file ...\t\t"
source ${_RCFILE}
echo -e "${GREEN} [OK]${NC}"

#####
# Verify binary
#####
_BINS="heat nova neutron glance"
for _BIN in ${_BINS}
do
	echo -e -n "Verifing ${_BIN} binary ...\t\t"
	which ${_BIN} > /dev/null 2>&1 || exit_for_error "Error, Cannot find python${_BIN}-client." false
	echo -e "${GREEN} [OK]${NC}"
done

#####
# Verify if the given credential are valid. This will also check if the use can contact Heat
#####
echo -e -n "Verifing OpenStack credential ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the PreparetionStack is available.
#####
echo -e -n "Verifing Preparetion Stack ...\t\t"
heat resource-list PreparetionStack > /dev/null 2>&1 || exit_for_error "Error, Cannot find the Preparetion Stack, so create it first." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the Admin Security Group is available
#####
echo -e -n "Verifing Admin Security Group ...\t\t"
neutron security-group-show $(cat environment/common.yaml|awk '/admin_security_group_name/ {print $2}') >/dev/null 2>&1 || exit_for_error "Error, Cannot find the Admin Security Group." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the AntiAffinity Group is available and
# - Load them into an array
#####
echo -e -n "Verifing Anti-Affinity rules ...\t\t"
_GROUPS=./groups.tmp
nova server-group-list|grep Group|sort -k4|awk '{print $2}' > ${_GROUPS}
_GROUPNUMBER=$(cat ${_GROUPS}|wc -l)
if [[ "${_GROUPNUMBER}" == "0" && "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
then
	exit_for_error "Error, There is any available Anti-Affinity Group." false hard
fi
for (( i=0 ; i < ${_GROUPNUMBER} ; i++ ))
do
	_GROUP[${i}]=$(sed -n -e $((${i}+1))p ${_GROUPS})
done
rm -f ${_GROUPS}
echo -e "${GREEN} [OK]${NC}"

#####
# Change directory into the deploy one
#####
_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#_TENANT_NETWORK_NAME=$(cat ../environment/common.yaml|awk '/tenant_network_name/ {print $2}')
#_TENANT_NETWORK_ID=$(neutron net-show --field id --format value ${_TENANT_NETWORK_NAME})

#####
# Initiate the actions phase
#####
echo -e "${GREEN}Performing Action ${_ACTION}${NC}"
if [[ "${_ACTION}" == "List" ]]
then
	#####
	# Stack List for each Stack of the same Unit 
	#####
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKID} || exit_for_error "Error, During Stack ${_ACTION}." true hard
	done
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Delete" ]]
then
	#####
	# Delete each Stack of the same Unit
	#####
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKID} || exit_for_error "Error, During Stack ${_ACTION}." true hard
	done

	#####
	# Release the the port cleaning up the security group
	#####
	cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	IFS=","
	exec 3<../${_ADMINCSVFILE}.tmp
	while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
	do	
		echo "Cleaning up Neutron port"
        	neutron port-update --no-security-groups ${_ADMIN_PORTID}
	done
	exec 3<&-
	rm -f ../${_ADMINCSVFILE}.tmp
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Update" || "${_ACTION}" == "Replace" ]]
then
	#####
	# Validate the Input values (falvor, image etc)
	#####
	echo "Validation phase"
	validation ${_UNIT}

	if [[ ${_UNIT} == "CMS" ]]
	then
		#####
		# Validate the network for CMS
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz
		net_validation ${_UNIT} media
		net_validation ${_UNIT} sip

		#####
		# Validate the network for CMS
		#####
		create_update_cms
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "LVU" ]]
	then
		#####
		# Validate the network for LVU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the LVU Creation
		#####
		create_update_lvu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "OMU" ]]
	then
		#####
		# Validate the network for OMU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Ini the OMU Creation
		#####
		create_update_omu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "VM-ASU" ]]
	then
		#####
		# Validate the network for VM-ASU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the VM-ASU Creation
		#####
		create_update_vmasu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "MAU" ]]
	then
		#####
		# Validate the network for MAU
		#####
		net_validation ${_UNIT} admin

		#####
		# Init the MAU Creation
		#####
		create_update_mau
		cd ${_CURRENTDIR}
		exit 0
	fi
fi
 
exit 0
