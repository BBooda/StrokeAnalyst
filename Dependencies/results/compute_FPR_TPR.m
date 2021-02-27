function [FPR, TPR, valid, DICE, ACC] = compute_FPR_TPR(predicted, ground_truth)
%     C = confusionmat(group,grouphat) returns the confusion matrix C 
%     determined by the known and predicted groups in group and grouphat, respectively. 
    cm =  confusionmat(ground_truth(:), predicted(:));
    
    valid = 0;
    if size(cm,1) ==2 && size(cm,2) == 2
        TN = cm(1,1);
        TP = cm(2,2);
        FP = cm(1,2);
        FN = cm(2,1);

        FPR = FP/(FP+TN);
        TPR = TP/(TP+FN);    
        ACC = (TP+TN)/(TP+FP+FN+TN);
        DICE = (2*TP)/(2*TP + FP + FN);
        valid = 1;
    else
        FPR = 'Not Assinged';
        TPR = 'Not Assinged';
    end
    

end