#!/bin/bash

list_name="global.acmeSubdomain"

read -p "Введите name для удаления: " name

file="values.yaml"

# Проверяем, есть ли запись с таким name
exists=$(yq e ".${list_name}[] | select(.name == \"$name\")" $file)

if [ -n "$exists" ]; then
  # Фильтруем список, удаляя элементы с заданным name
  yq e -i ".${list_name} |= map(select(.name != \"$name\"))" $file
  echo "Запись с name='$name' удалена."
else
  echo "Запись с name='$name' не найдена."
fi
