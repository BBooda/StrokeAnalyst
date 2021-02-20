function transf_info = dramms_inverse_dfield(dfield_path, out_path, dr_dir)
% inverse drams deformation field
% dramms_inverse_dfield_ui(dfield_path, out_path, dr_dir)
% dfield_path := dfield path without .nii.gz extension.
% out path := output directory, creates a file named: inv_dfield.nii.gz
% dr_dir := dramms bin directory
    
%     % store return address
%     ret_add = pwd;
%     
%     % go to dramms bin directory 
%     cd(dr_dir);

    % keep transformation info 
    transf_info.dfield_path = dfield_path ;
    transf_info.out_path = strcat(out_path, "/inv_dfield"); 

    % exexute dramms command
    command = strcat("/",dr_dir, "/dramms-defop -i ", dfield_path,".nii.gz", " ", out_path, "/inv_dfield.nii.gz");
    [status, result] = system(command, '-echo');
    if status ~= 0
        result
    end
       
%      cd(ret_add)
end
