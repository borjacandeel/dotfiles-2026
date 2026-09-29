function fish_user_key_bindings
    # Ctrl+R for fzf history search
    bind \cr 'fzf_history_search'
    
    # Alt+H for help
    bind \eh 'fish_commandline_prepend man '
    
    # Ctrl+F for file finder
    bind \cf 'fzf_file_search'
end

function fzf_history_search
    history | fzf --reverse | read -l command
    if test -n "$command"
        commandline -r $command
    end
    commandline -f repaint
end

function fzf_file_search
    find . -type f | fzf --reverse | read -l file
    if test -n "$file"
        commandline -i "$file "
    end
    commandline -f repaint
end
