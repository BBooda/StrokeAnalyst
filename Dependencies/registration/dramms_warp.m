function dramms_warp(img_path,dfield_path, out_path, name, dr_dir)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here
% ret_add = pwd;
    %create cell with registered slices to reference
    

%     cd(dr_dir);


    command = strcat("/",dr_dir,"/dramms-warp ", img_path, ".nii", " ", dfield_path, ".nii.gz", " ",...
        out_path, "/",convertCharsToStrings(name), ".nii");
    [status, result] = system(command, '-echo');
    if status ~= 0
        result
    end
       
%      cd(ret_add)
end
