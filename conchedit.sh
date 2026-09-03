#!/bin/bash

## VERSION CONTROL 

version_support_dicts=false

if [ "$(echo "$BASH_VERSION"; echo "5.0" | sort -V | head -n1)" == "5.0" ]; then
    
    # Checks if associative arrays are supported in this version 
    
    version_support_dicts=true 

    declare -A version_history=()

else 

    history=()

    dates=()

fi 


## FUNCTION SET UP

# Version History Function 

version() {

   if [ $version_support_dicts == true ]; then 

       for i in "${!version_history[@]}"; do
           
           echo "$i"
           echo -e "\n${version_history[$i]}\n"

       done

       printf "Restore Date (y/n): "

       read restore_date

       if [ "${restore_date,,}" == "y" ]; then 

           printf "Enter date: "

           read restore_date

           if [ -n "${version_history[$restore_date]}" ]; then

               echo "${version_history[$restore_date]}" > "$filename"

               echo "Version restored."

           else

               echo "Date not found."

           fi

        else 

            open_explorer

        fi 

    else 

        for ((i=0; i<${#history[@]}; i++)); do
            
            echo ${dates[i]}

            echo "\n${history[i]}\n"
        
        done

        printf "Restore Date (y/n)"

        read restore_date
        
        if [ "${restore_date,,}" == "y" ]; then 

            printf "Enter date: "

            read restore_date

            for ((i=0; i<${#dates[@]}; i++)); do

                if [ "${dates[i]}" == "$restore_date" ]; then

                    echo "${history[i]}" > "$filename"

                    echo "Version restored."

                    break

                fi

        
            done

        else 

            open_explorer

        fi

    fi 


}

# Settings 

is_vim=false

editor="nano"

automatic_execution=false

cmd=""

settings() {

   printf "\nSETTINGS\n"

   echo "-----------"

   printf "\nVim Enabled: $is_vim"

   printf "\n\nAutomatic Execution: $automatic_execution\n\n"


   printf "Change (Type None for no changes): " 

   read change 

   if [ "${change,,}" == "vim enabled" ]; then 
      
      if [ ${is_vim} == false ]; then  

        is_vim=true

        editor="vim"

        open_explorer

      else 

        is_vim=false 

        editor="nano"

        open_explorer

      fi 

    elif [ "${change,,}" == "automatic execution" ]; then 

      if [ $automatic_execution == false ]; then  

        automatic_execution=true
        
        cmd="autoexec"

        open_explorer

      else 

        automatic_execution=false 

        cmd=""

        open_explorer

      fi  
      
    elif [ "${change,,}" == "none" ]; then 

        open_explorer
    
    fi 

}

# after terminal controls

after_terminal_controls() {

    printf "\n\nCONTROLS"

    echo "---------" 

    printf "\n\n1. Go back to editor" 

    printf "\n\n2. File/folder explorer" 

    printf "\n\n3. Settings" 

    printf "\n\n4. Quit Application" 

    printf "\n\nCommand" 

    read command

    case "${command,,}" in

    "go back to editor") 

        "$editor" "$filename"
        terminal
        ;; 

    "file/folder explorer")

        open_explorer
        ;;

    "settings") 

        settings
        ;;

    "quit application") 

        exit 0
        ;;

    *) 

       after_terminal_controls
       ;;

    esac

}

# terminal 

terminal() {

    if [ $version_support_dicts == true ]; then 
        
        version_history["$(date)"]="$(cat "$filename")"

    else 

        history+=("$(cat "$filename")")
        dates+=("$(date)")

    fi

    printf "TERMINAL"

    printf "--------"

    printf "\n\nRun your code by typing ./filename"

    printf "\n\nType exit to exit\n\n"

    if [ "$EUID" -eq 0 ]; then 
        permission="#"
    else 
        permission="$"
    fi

    if [ "$cmd" == "autoexec" ]; then 

        cmd="./$filename"
    
    fi 

    eval "$cmd"

    while read -rp "$(whoami):$(pwd)$permission " command; do

        if [ "${command,,}" == "exit" ]; then

            break

        fi
    
        eval "$command"
    
    done 

}

# Creating the workspace 

create_workspace() {

    if [ -z "$SELECTED_DIR" ]; then 

        echo "No folder selected."
        exit 1

    fi

    cd "$SELECTED_DIR" || exit 1

    ls "$SELECTED_DIR" 

    echo "Type filename"

    read -r filename

    touch "$filename"

    nano_version="$(nano --version | awk '{print $4}')"

    if [ "$(echo "$nano_version"; echo "1.1.4" | sort -V | head -n1)" >= "1.1.4" ]; then

        echo "Do you syntax highlighting (y/n)?"

        read hightlight_yn

        if [[ $hightlight_yn =~ ^[Yy] ]]; then 

            "Type THIS into the text editor." > ~/.nanorc

            "\nMacOS (Before 2020): include "/usr/local/share/nano/*.nanorc"" > ~/.nanorc
        
            "\nMacOS (2020 and After) include "/opt/homebrew/share/nano/*.nanorc"" > ~/.nanorc

            "\nLinux: include "/usr/share/nano/*.nanorc" " > ~/.nanorc

            nano ~/.nanorc


        fi 

    fi

    $editor "$filename"

    chmod +x "$filename"

    du -sh .

    terminal
    
}

# Opening up file explorer

open_explorer() {

    case "$(uname -s)" in 

        Linux*)

            if command -v zenity >/dev/null && [ -n "$DISPLAY" ]; then

                SELECTED_DIR="$(zenity --file-selection --directory --title="Select a folder")"

                create_workspace

            else

                # Linux VM Compatibility 

                cd ~

                ls 

                printf "\nInsert or create folder"

                read -r folder 

                SELECTED_DIR="$(pwd)/$folder"

                if [ ! -d "$SELECTED_DIR" ]; then

                    mkdir ./$folder

                fi

                create_workspace

            fi

            ;;

        Darwin*)

            SELECTED_DIR="$(osascript -e 'POSIX path of (choose folder with prompt "Select a folder")')"
          
            create_workspace

            ;;

        MSYS* | CYGWIN* | MINGW*) 

            SELECTED_DIR="$(powershell.exe -NoProfile -Command '[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null; $dialog = New-Object System.Windows.Forms.FolderBrowserDialog; if ($dialog.ShowDialog() -eq "OK") { $dialog.SelectedPath }')"
            
            create_workspace

            ;;

        *) 
            
            cd ~

            ls 

            printf "\nInsert or create folder"

            read -r folder 

            SELECTED_DIR="$(pwd)/$folder"


            if [ ! -d "$SELECTED_DIR" ]; then

            mkdir ./$folder

            fi

            create_workspace

            ;;

    esac
    
}


# CONCHEDIT FILE & FOLDER

cd ~

if [ ! -d "ConchEdit" ]; then

    mkdir ./ConchEdit

fi 

if [ ! -d "ConchEdit/conchedit.sh" ]; then

    mv conchedit.sh ./ConchEdit/

fi 


# START MESSAGE

echo "ConchEdit - A Free, Open Source Developer Environment"
echo "------------------------------------------------------"

printf "\nLet's start.\n\n"

printf "Settings\n\n"

printf "Version History\n\n"

printf "Code\n\n"

# Input

read command

if [ "${command,,}" == "settings" ]; then 

    settings

elif [ "${command,,}" == "version history" ]; then 

    version

else 

    open_explorer

fi 

after_terminal_controls
