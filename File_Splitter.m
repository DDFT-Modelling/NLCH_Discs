%% Split/Recombine files in half for storing kernels (due to GitHub memory limitations)

%% Split .mat file into two files

% Define input and output file names
inputFile = 'Singular_Kernel_Disc_60.mat';
outputFile_1 = 'Singular_Kernel_Disc_60_[split_1].mat';
outputFile_2 = 'Singular_Kernel_Disc_60_[split_2].mat';

% Open the original file in read mode
fileID = fopen(inputFile, 'r');
if fileID == -1
    error('Error opening the file.');
end

% Determine file size
fseek(fileID, 0, 'eof');
fileSize = ftell(fileID);
halfSize = ceil(fileSize / 2);
fseek(fileID, 0, 'bof');

% Read the first half of the data
data_1 = fread(fileID, halfSize, 'uint8');
% Write to the first output file
fileID_1 = fopen(outputFile_1, 'w');
fwrite(fileID_1, data_1, 'uint8');
fclose(fileID_1);

% Read the remaining data for the second half
data_2 = fread(fileID, Inf, 'uint8');
% Write to the second output file
fileID_2 = fopen(outputFile_2, 'w');
fwrite(fileID_2, data_2, 'uint8');
fclose(fileID_2);

% Close the original file
fclose(fileID);

disp('File has been split into two halves.');

%% Recombine the files

% Define input and output file names
outputFile = 'Singular_Kernel_Disc_60.mat';
inputFile_1 = 'Singular_Kernel_Disc_60_[split_1].mat';
inputFile_2 = 'Singular_Kernel_Disc_60_[split_2].mat';


% Open each split file in read mode
fileID_1 = fopen(inputFile_1, 'r');
fileID_2 = fopen(inputFile_2, 'r');

% Open a new file in write mode for recombination
outputID = fopen(outputFile, 'w');

% Read and write the content of the first file
data_1 = fread(fileID_1, Inf, 'uint8');
fwrite(outputID, data_1, 'uint8');
fclose(fileID_1);

% Read and write the content of the second file
data_2 = fread(fileID_2, Inf, 'uint8');
fwrite(outputID, data_2, 'uint8');
fclose(fileID_2);

% Close the output file
fclose(outputID);

disp('Files recombined.');


%% Test
Newtonians_r = load('Singular_Kernel_Disc_60.mat', 'Newtonians');
Newtonians_o = load('Singular_Kernel_Disc_60_o.mat', 'Newtonians');   % Not present in GitHub version of the code

% Compare values
isequal(Newtonians_r, Newtonians_o)

% Deep comparison
[same, er_1, er_2] = comp_struct(Newtonians_r, Newtonians_o,2,0);
length(er_1) + length(er_2)
% >> ans = 0