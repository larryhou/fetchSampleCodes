#!/bin/bash

cd $(dirname $0)
# export HTTPS_PROXY=http://web-proxy.oa.com:8080

YEAR=2015
while getopts :y:h OPTION
do
	case ${OPTION} in
		y) YEAR=${OPTARG};;
		h) echo "Usage: $(basename $0) -y [FULL_YEAR] -h [HELP]"
		   exit;;
		:) echo "ERR: -${OPTARG} 缺少参数, 详情参考: $(basename $0) -h" 1>&2
		   exit 1;;
		?) echo "ERR: 输入参数-${OPTARG}不支持, 详情参考: $(basename $0) -h" 1>&2
		   exit 1;;
	esac
done

if [ ! -d ${YEAR} ]
then
	mkdir ${YEAR}
fi

echo 'library.json ...'
url='https://developer.apple.com/library/prerelease/ios/navigation/library.json'
json=$(curl -s ${url})
if [ ! $? -eq 0 ]
then
	echo 'ERROR: library.json failed'
	exit $?
fi

id=$(echo ${json} | jq '.topics[] | select(.name == "Resource Types").contents[] | select(.name == "Sample Code").key | tonumber' )

type_index=$(echo ${json} | jq '.columns.type')
date_index=$(echo ${json} | jq '.columns.date')
sort_index=$(echo ${json} | jq '.columns.sortOrder')
path_index=$(echo ${json} | jq '.columns.url')
name_index=$(echo ${json} | jq '.columns.name')

base=$(echo ${url} | sed 's/[^\/]*\/[^\/]*$//')
echo ${json} | jq -c ".documents[] | select((.[${type_index}] == ${id}) and (.[${date_index}] | startswith(\"${YEAR}\")))" | while read item
do
	path=$(echo ${item} | jq ".[${path_index}]" | sed 's/\"//g' | sed 's/^..\///')
	book=$(echo ${path} | sed 's/#.*$//' | sed 's/[^\/]*\/[^\/]*$//' | xargs -I{} echo "${base}{}book.json")
	echo "--> ${path}"
	name=$(curl -s ${book} | jq '.sampleCode' | sed 's/\"//g')
	file=$(echo ${book} | sed 's/[^\/]*$//' | xargs -I{} echo "{}${name}")
	echo ">>> ${file}"
	wget ${file} -O ${YEAR}/${name}
	echo
done