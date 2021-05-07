function linear_registration(app, subject, reference)
            
    [~,~,chann_test] = size(subject);

    if chann_test > 1 
        % call linear registration function given as input the
        % coresponding linear transformation
        [aff_out, ~,movingRefObj,fixedRefObj] = linear_registration(app,rgb2gray(subject),reference, app.SetDropDown.Value);
    else
        [aff_out, ~,movingRefObj,fixedRefObj] = linear_registration(app,(subject),reference, app.SetDropDown.Value);
    end

    %save tranformation information
    app.sub_T.index = app.IndexiesListBox.Value;
    app.sub_T.subject = subject;
    app.sub_T.reference = app.reference;
    app.sub_T.aff_out = aff_out;
    app.sub_T.movingRefObj = movingRefObj;
    app.sub_T.fixedRefObj = fixedRefObj;

    % inverse linear transfor
    app.sub_T.inv_aff = invert(aff_out.Transformation);
    
    % create nifti files for dramms non linear registration
    app.affine_data_S2A = create_affine_data(aff_out, subject, reference,... 
    app.sub_T.index, app.save_dir, movingRefObj, fixedRefObj);

    cd(app.save_dir);
end