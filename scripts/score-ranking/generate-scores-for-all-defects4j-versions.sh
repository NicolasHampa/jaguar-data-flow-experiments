#! /bin/bash

if [ -z "$1" ] ; then
    echo "Repository root path is missing! Execution has been stopped."
    exit 1
fi

repository_root_path=$1

for project_path in `find $repository_root_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        echo $project_version_path

        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_name=${project_version_path_array[((index-2))]}
        project_version=${project_version_path_array[((index-1))]}

        ./do-full-analysis $project_name $project_version $project_version_path/matrix $project_version_path/spectra ../../reports/
    done
done