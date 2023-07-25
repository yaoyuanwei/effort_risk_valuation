% Function to copy contrast image
% Author: Yuanwei Yao
% Date: July 23, 2023


function [source_file, dest_file] = copy_contrast(task_name, anal_fold, sub_fold, cons_copy, si)

    % model name
    model_i     = [task_name, '_model_sv'];
    

    cons_dir        = fullfile(sub_fold, result_dir, model_i);    
    
    for cons = 1:length(cons_copy)
        
        source_file     = spm_select('FPList', sub_path, cons_copy{cons});
        [path,name,ext] = fileparts(cons_copy{cons});

        dest_file_name  = sprintf('%s_%s%s',name, ['Sub', si], ext); %con_0001_Sub102.nii

        con_name        = sprintf('con_000%d',cons);
        dest_dir        = fullfile(anal_fold, 'stats', model_i, con_name);
        if ~exist(dest_dir,'dir')
            mkdir(dest_dir);
        end

        dest_file       = fullfile(dest_dir, dest_file_name);
        copyfile(source_file, dest_file);
    end
end