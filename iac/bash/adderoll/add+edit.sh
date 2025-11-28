#!/bin/bash

# Параметр с именем списка
list_name="global.acmeSubdomain"

# Запрос переменных у пользователя
read -p "Введите name: " name
read -p "Введите host: " host
read -p "Введите meshPort: " meshPort

file="values.yaml"

# Проверка, существует ли запись с таким name
exists=$(yq e ".${list_name}[] | select(.name == \"$name\")" $file)

if [ -n "$exists" ]; then
  # Если host не пустой, обновляем поле host
  if [ -n "$host" ]; then
    yq e -i "(.${list_name}[] | select(.name == \"$name\") | .host) = \"$host\"" $file
  fi

  # Если meshPort не пустой, обновляем поле meshPort
  if [ -n "$meshPort" ]; then
    yq e -i "(.${list_name}[] | select(.name == \"$name\") | .meshPort) = $meshPort" $file
  fi

  echo "Запись с name='$name' обновлена."
else
  # Добавляем пустой элемент и обновляем его поля по отдельности
  yq e -i ".${list_name} += [{}]" $file
  last_index=$(yq e ".${list_name} | length - 1" $file)
  yq e -i "(.${list_name}[$last_index].name) = \"$name\"" $file
  yq e -i "(.${list_name}[$last_index].host) = \"$host\"" $file
  yq e -i "(.${list_name}[$last_index].meshPort) = $meshPort" $file
  echo "Новая запись с name='$name' добавлена."
fi
