 function save_dir = create_processing_folder(name, base_path)
    % check date and time 
    date = datestr(floor(now));
    new_dir = strcat(date, "-", name);

    % create directory
    mkdir(base_path, new_dir);

    % set save directory
    % save dir will change for each different slice while working dir (wor_dir) will remain the same.
    save_dir = strcat(base_path, '/', new_dir);

end