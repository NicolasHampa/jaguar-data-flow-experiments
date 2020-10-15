#! /bin/bash

if [ -z "$1" ] ; then
    echo "Defects4J dataset path is missing! Execution has been stopped."
    exit 1
fi

dataset_path=$1

for project_path in `find $dataset_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_name=${project_version_path_array[((index-2))]}
        project_version=${project_version_path_array[((index-1))]}
        strlen=${#project_version}
        project_version_number=${project_version:0:((strlen-1))}
        project_version_type=${project_version: -1}
        if [ $project_version_type = "b" ]; then
            defects4j info -p $project_name -b $project_version_number > $project_version_path/defects4j-info.txt
        fi
    done
done

echo "Successfully generated Defects4J information files!"