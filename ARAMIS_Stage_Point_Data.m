clc
clear all

[File,Pathname,Index] = uigetfile('C:\Users\David Walters\Documents\MSU Research\Doctoral Work\Mechanical Testing\*.txt','Choose the Data file');
path(path,Pathname);
Import = importdata(File, ' ', 4);
data = Import.data;
    %Column 1 = Index_x
    %Column 2 = Index_y
    %Column 3 = Time(s)
    %Column 4 = User_Time(s)--If real time is unavailable
    %Column 5 = x-position_deformed(mm)
    %Column 6 = y-position_deformed(mm)
    %Column 7 = z-position_deformed(mm)
    %Column 8 = Major Strain (Technical-%)  (Principal I)
    %Column 9 = Minor Strain (Technical-%)  (Principal II)
    %Column 10 = Strain_X (Technical-%)
    %Column 11 = Strain_Y (Technical-%)
    %Column 12 = Shear_Strain (radians)
    %Column 13 = Displacement_X(um)
    %Column 14 = Displacement_Y(um)
    %Column 15 = Displacement_Z(um)

%Create time vector based on which time stamp is currently calculated by
%ARAMIS.  If the default time stamp is not present (this happens when not
%directly using ARAMIS images as in creating a 2D files from 3D images),
%then the user calculated tiime data is taken.
if max(data(:,3))>0
    time = data(:,3);
else
    time = data(:,4);
end

%Define position vector of stage point in 2D/3D.  Point is attached to the
%deformed configuration and therefore updates with each stage.
pos_x = data(:,5);
pos_y = data(:,6);
%Logic determines if test data is 2D or 3D
if (max(data(:,7))~=0) || (min(data(:,7))~=0)
    pos_z = data(:,7);
end

%Define vectors containing strain data
major = data(:,8);
minor = data(:,9);
eps_x = data(:,10);
eps_y = data(:,11);
eps_xy = data(:,12);

%Define vectors containing deformation data, data in micrometers(um)
d_x = data(:,13);
d_y = data(:,14);
%Logic determines if test data is 2D or 3D
% if (max(data(:,15))~=0) || (min(data(:,15))~=0)
%     d_z = data(:,15);
% end