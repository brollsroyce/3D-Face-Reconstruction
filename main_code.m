% 3D Face Reconstruction from stereo images
% Course: Image Processing & Computer Vision
% University of Twente
% 18 April, 2019

% Authors: Gunish Alag s2148439 & Brolin Fernandes s2107112

clear variables % Clear variables in workspace
close all       % Close all images/graphs/plots
clc             % Clear Command Window

% Initialize paths to data, functions and images
addpath('CalibrationData');
addpath('Test');
addpath('Functions');

% LM represent Left -> Middle
% MR represent Middle -> Right

%% Reading images
images = imageSet('Test'); % Create a indexed imageSet of the subject
Sub = 2; %0, 1, 2 represents subject 1, 2, 3
im_left = im2double(read(images,1+3*Sub));
im_middle = im2double(read(images,2+3*Sub));
im_right = im2double(read(images,3+3*Sub));

%% Camera Calibration

% matlab app stereo camera calibration was used to calibrate the camera and
% the parameters are stored and loaded.

% Load stereo camera calibrated parameters
load('CalibrationData/stereoParams_subject1_calib1.mat');
showExtrinsics(stereoParams_LM)


%% k means clustering and image segmentation

% the image was broken into L*a*b category and then k means clustering aws
% used to extract a mask from the left middle and right image. 
% This is based mostly on the Matlab Example:
%       openExample('images/LabColorSegmentationExample')
%       openExample('images/KMeansSegmentationExample')
% but the results were not satisfactory enough so next we used the colour
% thresholder app from the matlab to segment the images and it was further
% used as the mask for the images. the data from the app was stored and
% loaded later for use.

% 
% [mask_left] = k_means_segment(im_left);
% [mask_middle] = k_means_segment(im_middle);
% [mask_right] = k_means_segment(im_right);

im_left_masked = im_left;
im_middle_masked = im_middle;
im_right_masked = im_right;

% Load masks of the desired subject found through color thresholder  clustering
% load('Masks/masks_subject1_calib1.mat'); % load left, middle, and right mask
%load('Masks/masks_subject2_calib1.mat'); % load left, middle, and right mask
load('Masks/masks_subject3_calib1.mat'); % load left, middle, and right mask

% the obtained binary masks after using the k means segment is used to
% overlay on the original image and generate the masked images
mask_left = cat(3, mask_left, mask_left, mask_left);
im_left_masked(imcomplement(mask_left)) = 0;
mask_middle = cat(3, mask_middle, mask_middle, mask_middle);
im_middle_masked(imcomplement(mask_middle)) = 0;
mask_right = cat(3, mask_right, mask_right, mask_right);
im_right_masked(imcomplement(mask_right)) = 0;


%% Stereo rectification
% rectification of the original images with stereo parameters obtained from
% stereo camera calibration
[im_left_rect, im_middleleft_rect] = rectifyStereoImages(...
    im_left, im_middle, stereoParams_LM,'OutputView','full');
    
[im_middleright_rect, im_right_rect] = rectifyStereoImages(...
    im_middle, im_right, stereoParams_MR, 'OutputView','full');

% Stereo rectify the masked images as well for disparity maps later
[im_left_rect_mask, im_middleleft_rect_mask] = rectifyStereoImages(im_left_masked, ...
    im_middle_masked, stereoParams_LM,'OutputView','full');
        
[im_middleright_rect_mask, im_right_rect_mask] = rectifyStereoImages(im_middle_masked, ...
    im_right_masked, stereoParams_MR, 'OutputView','full');


%% Disparity map
% Create disparity map for the two image pairs
[disp_map_LM, unreliable_LM] =  disparityMapAndUnreliable(im_left_rect, ...
    im_middleleft_rect, im_left_rect_mask, 11 +Sub*10);
[disp_map_MR, unreliable_MR] =  disparityMapAndUnreliable(im_middleright_rect, ...
im_right_rect, im_middleright_rect_mask, 12 +Sub*10);

%% 3D point clouds
% Create point clouds for LM and MR
xyzPoints_LM = reconstructScene(disp_map_LM,stereoParams_LM);
xyzPoints_MR = reconstructScene(disp_map_MR,stereoParams_MR);

% Complete PointCloud Registration Algorithm
%{
    Denoise(LM)     &   Denoise(MR)     - pcdenoise
    Downsample(LM)  &   Denoise(MR)     - pcdownsample
    Rigid Transformation LM & MR        - pcregrigid
        Match Points between LM & MR
        Remove incorrect matches (Outlier filter)
        Recover rotation and translation (minimize error)
        Check if algorithm stops
    Align LM and MR                     - pctransform
    Merge LM and MR                     - pcmerge
%}

pc_LM = pointCloud(xyzPoints_LM);
pc_LM = pcdenoise(pc_LM);
pc_LM = pcdownsample(pc_LM, 'nonuniformGridSample', 15);
pc_MR = pointCloud(xyzPoints_MR);
pc_MR = pcdenoise(pc_MR);
pc_MR = pcdownsample(pc_MR, 'nonuniformGridSample', 15);
[tform,pc_MR,rmse]= pcregrigid(pc_MR, pc_LM, 'Extrapolate',true);
 pc = pcmerge(pc_LM, pc_MR, 1);
figure;
pcshow(pc_LM);

%% Create 3D meshes from point clouds
% function is used from the one provided in UT_sylabi
meash_LM = create_3D_mesh(disp_map_LM, xyzPoints_LM, ...
    unreliable_LM, im_left_rect_mask);
% mesh_MR = create_3D_mesh(disp_map_MR, xyzPoints_MR, ...
%     unreliable_MR, im_middleright_rect_mask);