function out = register_atlas_hemisphere(img, index, hemi_flag, hemi_tr, save_dir, atlas_dir, dramms_path)
    
    img = img.Img;
    
    % if lesion hemisphere is right, obtain transformations and continue, else compute transformations for this index
    % check if transformations already exist 
    if hemi_tr.hemi_transf.isKey(index)
        fixedRefObj_T1 = hemi_tr.hemi_transf(index).fixed;
        movingRefObj_T1 = hemi_tr.hemi_transf(index).mov;
        aff_ref_flip = hemi_tr.hemi_transf(index).T ;
        
        transf.fixed = fixedRefObj_T1;
        transf.mov = movingRefObj_T1;
        transf.T = aff_ref_flip;
        transf.hemi_flag = hemi_flag;
        
        out.linear_transf = transf;
        
        out.dfield_path = strcat(atlas_dir,'/hemisphere_transformations/', strcat(index, "_atlasHR_dfield"));
        
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
        out_path = save_dir;
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
        
        out.linear_transf = transf;

        %create and save to struct
        hemi_transf(index) = transf;                   

        %save struct, save deformation field.
%           save('/home/makis/Documents/MouseStrokeImageAnalysis/Data/subjects_results/hemisphere_transformations', 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
        save(strcat(atlas_dir,'/hemisphere_transformations/hemisphere_transformations'), 'hemi_transf', 'hemi_transf_l', 'hemi_transf_r');
        dfield_path = strcat(atlas_dir,'/hemisphere_transformations/', strcat(index, "_atlasHR"));

        % permorm non linear registration 
        def_regi_out = dramms_2dregistration(ref_path,aff_path,out_path, strcat(index, "atlasHR"), dramms_path, dfield_path);
                     
        out.dfield_path = def_regi_out.regi_output_path_dfield;
        
    end    
    
    
end