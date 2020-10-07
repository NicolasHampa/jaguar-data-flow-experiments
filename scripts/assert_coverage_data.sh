#! /bin/bash

echo "Hello world!"

if [ -z "$1" ] ; then
    echo "Caminho base do Dataset não informado! Execução interrompida."
    exit 1
fi

dataset_base_path=$1

for project_base_path in `find $dataset_base_path -maxdepth 1 -mindepth 1 -type d`
do
    echo "************"$project_base_path"************"
    printf '\n'
    for project_version in `find $project_base_path -maxdepth 1 -mindepth 1 -type d`
    do
        echo $project_version
        python3 assert_jaguar.py "$project_version/jaguar"
        printf '\n'
    done
    printf '\n'
done