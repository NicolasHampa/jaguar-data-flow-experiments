#! /bin/bash

if [ -z "$1" ] ; then
    echo "Gzoltar repository root path is missing! Execution has been stopped."
    exit 1
fi

if [ -z "$2" ] ; then
    echo "Jaguar repository root path is missing! Execution has been stopped."
    exit 1
fi

repository_root_path=$1

for project_path in `find $repository_root_path -maxdepth 1 -mindepth 1 -type d`
do
    for project_version_path in `find $project_path -maxdepth 1 -mindepth 1 -type d`
    do
        filename=$project_version_path/spectra
        classes=()
        while read line; do
            IFS='#' read -ra line_array <<< "$line"
            clazz=${line_array[((0))]}

            IFS='$' read -ra clazz_array  <<< "$clazz"
            clazz=${clazz_array[((0))]}

            if [[ ! " ${classes[*]} " =~ " ${clazz} " ]]; then
                classes+=($clazz)
            fi
        done < $filename

        #echo ${classes[@]}

        IFS='/' read -ra project_version_path_array <<< "$project_version_path"
        index=${#project_version_path_array[@]}
        project_name=${project_version_path_array[((index-2))]}
        project_version=${project_version_path_array[((index-1))]}

        jaguar_root_path=$2
        jaguar_spectra_version_path=$jaguar_root_path"/"$project_name"/"$project_version"b/jaguar/.jaguar/spectra"
        cd $jaguar_spectra_version_path
        printf "\n===================================================================\n" >> "$HOME/report.txt"
        echo $project_name"/"$project_version >> "$HOME/report.txt"
        echo "===================================================================" >> "$HOME/report.txt"

        jaguar_spectra_files=()
        for spectra_file_path in `find $jaguar_spectra_version_path -maxdepth 1 -mindepth 1 -type f`
        do
            IFS='/' read -ra spectra_filename_array <<< "$spectra_file_path"
            index=${#spectra_filename_array[@]}
            spectra_filename=${spectra_filename_array[((index-1))]}
            spectra_filename=${spectra_filename%".spectra"}

            if [[ ! " ${jaguar_spectra_files[*]} " =~ " ${spectra_filename} " ]]; then
                jaguar_spectra_files+=($spectra_filename)
            fi
        done

        #echo ${jaguar_spectra_files[@]}

        for classname in "${classes[@]}"
        do
            if [[ ! " ${jaguar_spectra_files[*]} " =~ " ${classname} " ]]; then
                echo "Jaguar data-flow coverage for $classname class not found!" >> "$HOME/report.txt"
            fi
        done
    done
done
