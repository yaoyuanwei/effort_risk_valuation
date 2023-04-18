clear;
clc;

%define the directory structure
base_path   = '/Volumes/projects/ERDT/Effort/univariate';
model_i     = 'edt_model4sv_6fd';

sub_fold    = dir(fullfile(base_path, 'Sub*'));
sub_dir     = {sub_fold.name}';


result_dir  = 'results';
consToCopy  = {'con_0001.nii'};

for si = 1:length(sub_dir)
    
    sub_path        = fullfile(base_path, sub_dir{si}, result_dir, model_i);
    result_path     = fullfile(base_path, 'stats', model_i);
    
    
    for cons = 1:length(consToCopy)
        source_file     = spm_select('FPList', sub_path, consToCopy{cons});
        [path,name,ext] = fileparts(consToCopy{cons});
        dest_file_name  = sprintf('%s_%s%s',name,sub_dir{si},ext); %con_0001_Sub102.nii
        con_name        = sprintf('con_000%d',cons);
        dest_path       = fullfile(result_path, con_name);
        if ~exist(dest_path,'dir')
            mkdir(dest_path);
        end
        dest_file       = fullfile(result_path, con_name, dest_file_name);
        copyfile(source_file,dest_file);
    end
end
