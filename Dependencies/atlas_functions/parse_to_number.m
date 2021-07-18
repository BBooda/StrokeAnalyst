function ref = parse_to_number(str)
% check if index is string and convert it to a number index   
    if ischar(str) || isstring(str)
        if strcmp(str(1:2), 'bn')
            ref = str2double(strcat('-', str(3), '.', str(5:6)));
        else
            ref = str2double(strcat(str(3), '.', str(5:6)));
        end
    end
end