function out = ml_prediction(model, subject, hemi_mask, zscore, zscore_dif)
    % create feature vector 
    f_v_13 = create_ml_features(hemi_mask, 'subject', subject, 'zscore',...
        zscore, 'zscore_dif', zscore_dif);
    
    [pre, scores] = predict(model, f_v_13);
    
    out = str2num(cell2mat(pre));

    out = reshape(out, size(rgb2gray(subject)));
end