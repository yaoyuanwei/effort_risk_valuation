clear;
clc;

%define the directory structure
base_path       = '/Volumes/projects/ERGT/EGT/univariate';
model_i         = 'egt_model4sv_6fd';

sub_fold    = dir([base_path '/sub*']);
sub_dir     = cell(length(sub_fold),1);
for i=1:length(sub_fold)
    sub_dir{i,1} = sub_fold(i).name;
end

result_dir  = 'results/';
consToCopy  = {'con_0001.nii'};

for si = 1:length(sub_dir)
    
    sub_path        = fullfile(base_path, sub_dir{si}, result_dir, model_i);
    result_path     = fullfile(base_path, 'stats', model_i);
    
    
    for cons = 1:length(consToCopy)
        sourceFile      = spm_select('FPList', sub_path, consToCopy{cons});
        [path,name,ext] = fileparts(consToCopy{cons});
        destFileName    = sprintf('%s_%s%s',name,sub_dir{si},ext); %con_0001_Sub102.nii
        con_name        = sprintf('con_000%d',cons);
        dest_path       = fullfile(result_path, con_name);
        if ~exist(dest_path,'dir')
            mkdir(dest_path);
        end
        destFile        = fullfile(result_path, con_name, destFileName);
        copyfile(sourceFile,destFile);
    end
end