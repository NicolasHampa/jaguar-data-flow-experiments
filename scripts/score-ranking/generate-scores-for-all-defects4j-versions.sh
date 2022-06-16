#! /bin/bash

if [ -z "$1" ] ; then
    echo "Repository root path is missing! Execution has been stopped."
    exit 1
fi

if [ -z "$2" ] ; then
    echo "Coverage tool [gzoltar,jaguar] is missing! Execution has been stopped."
    exit 1
fi

repository_root_path=$1
coverage_tool=$2

for project_path in `find $repository_root_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_name=${project_version_path_array[((index-2))]}
        project_version=${project_version_path_array[((index-1))]}

        if [ ${coverage_tool} == "gzoltar" ]; then
            ./do-full-analysis $project_name $project_version $project_version_path/matrix $project_version_path/spectra gzoltar ../../reports/
        fi

        if [ ${coverage_tool} == "jaguar" ] && [ "${project_version: -1}" == "b" ]; then
            project_version=${project_version%"b"}
            ./do-full-analysis-dua $project_name $project_version $project_version_path jaguar ../../reports/
        fi
    done
done