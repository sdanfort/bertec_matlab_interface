%treadmill_interface_example

%Code to 
%(1) remotely set treadmill speed
%(2) read treadmill data during a warm-up period
%(3) plot the vertical forces from this warm-up
%Written by Shannon Danforth

clear;
close all;

%% add file paths
%These file paths should work for the Vicon computer in RehabLab.
addpath('C:\Program Files\Vicon\DataStream SDK');
addpath('C:\Program Files\Vicon\DataStream SDK\Win64\MATLAB');
addpath('C:\Program Files (x86)\Vicon\Nexus2.12\SDK\MATLAB');
addpath([pwd '\matlabTreadmillFunctions']);
addpath([pwd '\dotNET']);

%to connect to vicon SDK 
%(I copied this code from a test function provided by Vicon, 
%you won't be able to connect without it):
dssdkAssembly = which('ViconDataStreamSDK_DotNET.dll');
if dssdkAssembly == ""
  [ file, path ] = uigetfile( '*.dll' );
  if isequal( file, 0 )
    fprintf( 'User canceled' );
    return;
  else
    dssdkAssembly = fullfile( path, file );
  end   
end
NET.addAssembly(dssdkAssembly);

%% treadmill speed, subject number, etc
%after having user walk on treadmill for awhile
% pref_speed = input('Enter preferred walking speed in m/s.'); %m/s

%or, just set it to 1.2 m/s for now.
pref_speed = 1; %m/s
SubjName = '1';

%% create a folder to save subject data

if ~exist( sprintf('matlab_data/Subject%s', SubjName), 'dir' )
    mkdir( sprintf('matlab_data/Subject%s', SubjName) );
end
addpath( genpath( 'matlab_data') );

%% Warm up at a specific speed (and save some info)

% define input settings
Settings.Duration = 30; %warm-up for this amount of seconds
Settings.Speed = pref_speed;
Settings.Threshold = 30; %force, in N, to detect stance. May need to be adjusted.

%pause before starting treadmill:
uiwait(msgbox('Click to start warm up'));
%run the warm-up (all the cool stuff happens in WarmUpTM!)
WarmUpData = WarmUpTM(Settings);

%save the warm-up data
save( sprintf('matlab_data/Subject%s/subject%s_warmup_data.mat',...
SubjName, SubjName ), 'WarmUpData' );

%plot the force data
right_z_force = [WarmUpData.FzR]';
left_z_force = [WarmUpData.FzL]';
t = [WarmUpData.Time]';

%let's plot the absolute value of force. I use abs() when checking against
%the threshold I set.
right_z_force = abs(right_z_force);
left_z_force = abs(left_z_force);

%plot stuff
sz = 20;
color1 = [117,107,177]/255;
color2 = [241,163,64]/255;

figure(1);
subplot(2,1,1); hold on;
scatter( t, right_z_force, sz, 'MarkerEdgeColor', color1,...
    'MarkerFaceColor', color1 );
xlabel('Time (s)');
ylabel('Force (N)');
title('Right Vertical Force');
subplot(2,1,2); hold on;
scatter( t, left_z_force, sz, 'MarkerEdgeColor', color2,...
    'MarkerFaceColor', color2 );
xlabel('Time (s)');
ylabel('Force (N)');
title('Left Vertical Force');