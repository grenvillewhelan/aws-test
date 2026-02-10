#!/bin/bash

function exec_cmd()
{
   cont=""
   $*

   echo "Command"
   echo "    --> $*"
   echo -n "    returned $?, continue [y/n] : "

   while [ "${cont}" != "y" ]
   do
      read cont

      if [ "${cont}" == "n" ]; then
         exit 1
      fi
   done
}

echo -n "Enter git branch :"
read css_number

echo -n "Description : "
read description

echo
echo "Run git commands:"
echo
#echo "    "git checkout main
echo "    "git branch ${css_number}
echo "    "git checkout ${css_number}
echo "    "git add .
echo "    "git commit -m '"'${css_number}' - '${description}'"'
echo "    "git push --set-upstream origin ${css_number}
echo "    "git push origin
echo "    "git checkout
#echo "    "git branch origin
echo

echo "if stuck consider git pull --rebase ...."
