% Export all existing EPS files in the logs folder to PNG and PDF
% Use this when EPS files exist but PNG/PDF versions are missing

clear; close all; clc;

script_dir = fileparts(mfilename('fullpath'));
logs_folder = fullfile(script_dir, '..', 'logs');

eps_files = dir(fullfile(logs_folder, '*.eps'));
fprintf('Found %d EPS files in: %s\n\n', length(eps_files), logs_folder);

for i = 1:length(eps_files)
    [~, name, ~] = fileparts(eps_files(i).name);
    eps_path = fullfile(logs_folder, eps_files(i).name);
    
    fprintf('Processing: %s.eps\n', name);
    
    try
        fig = open(eps_path);
        
        % Save as PNG
        png_path = fullfile(logs_folder, [name, '.png']);
        print(fig, png_path, '-dpng', '-r300');
        fprintf('  -> %s.png\n', name);
        
        % Save as PDF
        pdf_path = fullfile(logs_folder, [name, '.pdf']);
        print(fig, pdf_path, '-dpdf', '-r300');
        fprintf('  -> %s.pdf\n', name);
        
        close(fig);
    catch ME
        fprintf('  ERROR: %s\n', ME.message);
    end
end

fprintf('\nExport complete!\n');
