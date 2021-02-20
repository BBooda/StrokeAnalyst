function reg_info = dramms_2dregistration(target_path,moving_path,out_path, file_name, dramms_path,varargin)
%   dramms_2dregistration(target_path,moving_path,out_path)
%   +input => absolute file paths
%   -output => 2 files. Registered Image to target and deformation field.   


%     moving_path = strcat(moving_path, "/",file_name, ".nii");
    target_path = convertCharsToStrings(target_path);

    moving_path = convertCharsToStrings(moving_path);

    out_path_dfield = convertCharsToStrings(strcat(out_path, '/dfield.nii.gz'));

    if ~isempty(varargin)
        out_path_dfield = convertCharsToStrings(strcat(varargin{1}, 'dfield.nii.gz'));
    end

    out_path = convertCharsToStrings(strcat(out_path, "/registered_", file_name, "_to_average.nii"));

    % keep registration info 
    reg_info.target_img_path = target_path;
    reg_info.moving_img_path = moving_path;
    reg_info.regi_output_path_dfield = out_path_dfield;

%     sett = " -w 1 -a 0 -v -v";


%  -c   <int>              How to use mutual-saliency weighting. 
%                         0 -- (default) do not use mutual-saliency if there are no outlier regions (lesions, cuts, etc);
%                        1 -- use but do not save mutual-saliency map; 


    sett = " -w 1 -a 0 -c 1"; % < -c 1 > for lesions and cuts..

    command = strcat("/", dramms_path, "/dramms", " -S ", moving_path, " -T ", target_path, " -O ", out_path, " -D ", out_path_dfield,sett);
    [status, result] = system(command, '-echo');    

end