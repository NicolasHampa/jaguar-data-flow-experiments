#! /bin/bash

if [ -z "$1" ] ; then
    echo "Defects4J dataset path is missing! Execution has been stopped."
    exit 1
fi

dataset_base_path=$1

mkdir output_files
cd output_files

for project_base_path in `find $dataset_base_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_path in `find $project_base_path -maxdepth 1 -mindepth 1 -type d`
    do
        IFS='/' read -ra project <<< "$project_path"
        index=${#project[@]}
        project_name=${project[((index-2))]}
        project_version=${project[((index-1))]}
        echo $project_name
        strlen=${#project_version}
        project_version=${project_version:0:((strlen-1))}
        echo $project_version
        defects4j info -p $project_name -b $project_version > $project_name-$project_version-info.txt
    done
done

echo "Successfully generated coverage report csv file!"