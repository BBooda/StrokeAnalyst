function out = register_atlas_hemisphere(atlas, index, hemi_flag, hemi_tr, save_dir, dramms_path)
    
    img = atlas(index).Img;
    
    if hemi_flag == 1
        % if lesion hemisphere is right, obtain transformations and continue, else compute transformations for this index
        % check if transformations already exist 
        if hemi_tr.hemi_transf_r.isKey(name)
            fixedRefObj_T1 = hemi_tr.hemi_transf_r(name).fixed;
            movingRefObj_T1 = hemi_tr.hemi_transf_r(name).mov;
            aff_ref_flip = hemi_tr.hemi_transf_r(name).T ;
        else
            %compute transformations for this index.
            
            % flip reference image around midline
            ref_flip = flip(img, 2);

            % linearly register hemispheres
            [aff_ref_flip, ~,movingRefObj_T1,fixedRefObj_T1] = linear_registration(ref_flip, img);
            
            % save fliped Linear Atlas Hemisphere Registration flip as
            % nifti for deformable registration
            nifti_save(aff_ref_flip.RegisteredImage, 'LAHR_flip', save_dir);
            
            % determine linearly transformed image path 
            aff_path = strcat(save_dir, '/LAHR_flip.nii');
            out_path = app.save_dir;
            ref_path = strcat(save_dir, '/reference.nii');

            % update .mat file 
            % load files and update 
            hemi_transf_r = hemi_tr.hemi_transf_r;
            hemi_transf = hemi_tr.hemi_transf;
            hemi_transf_l = hemi_tr.hemi_transf_l;

            %save hemisphere transformation
            %create transf object
            transf.fixed = fixedRefObj_T1;
            transf.mov = movingRefObj_T1;
            transf.T = aff_ref_flip;
            transf.hemi_flag = hemi_flag;

            %create and save to struct
            hemi_transf_r(index) = transf;                   

            %save struct, save deformation field.
%           save('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations', 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
            save(strcat(save_dir,'/hemisphere_transformations/hemisphere_transformations'), 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
            dfield_path = strcat(save_dir,'/hemisphere_transformations/r_hemisphere/', name);

            % permorm non linear registration 
            dramms_2dregistration(ref_path,aff_path,out_path, index, dramms_path,dfield_path)
                     
        end
    end
    
    % use hemi flag and determine deformation field path
            
    if hemi_flag == 1
        dfield_path = strcat(save_dir,'/hemisphere_transformations/r_hemisphere/', name, 'dfield');

    else
        dfield_path = strcat(save_dir,'/hemisphere_transformations/l_hemisphere/', name, 'dfield');
    end
    
    
end