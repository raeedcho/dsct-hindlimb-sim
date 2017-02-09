%% find flexion axes for 2D model
% load ncmb
nmcb = read_nmcb('basicCatHindlimb_201201.nmcb');

%% Get world points
% neutral joint configuration
q = [0 0 0 -60 -14 0 -82 0 -78 0]'*pi/180;

% intersection plane for finding flexion axis positions
zplane = 0.01;

% use drawmodel to get world points
% [~,worldpoint,endpoint] = drawmodel(nmcb,q);

nbod = length(nmcb.bod);

%NMCB structure allows multiple axes connecting 2 bodies, which really
%complicates calculations.  We're going to convert that to a series of
%segments connected by single rotational degrees of freedom by replacing
%single bodies connected by multiple axes to multiple bodies of length 0
%connected by single axes

ax = cell(nbod, 1);         %rotational axes that connect bod(i) to bod(i-1)
                            %in bod(i) coordinates
joints = zeros(nbod,1);
for index = 1:nbod-1
    ax{index} = cat(1, nmcb.bod(index).rDOF.axis)';
    joints(index) = size(ax{index},2);
end
njoints = sum(joints);

endpoint = zeros(3,njoints+1); %origin of bod(i+1) in bod(i) coordinates
worldpoint = zeros(3, njoints+1);%origin of bod(i) in global coordinates
nextjoint = 1;
for index = 1:(nbod-1)%last body doesn't have a joint
    endpoint(:,nextjoint) = nmcb.bod(index).location;
    nextjoint = sum(joints(1:index))+1;
end
endpoint(:,njoints+1) = nmcb.en.pe.poi;    %assumes a perturbation exists and gives
                                    %the system endpoint
ax = cat(2, ax{:});                 %assumes unit axes

% get rotation matrices
cumrot = eye(3);
rots = zeros(3,3,njoints);
for index = 1:njoints
    rots(:,:,index) = axis2R(ax(:,index)*q(index));
    cumrot = squeeze(rots(:,:,index))*cumrot;
    worldpoint(:,index+1,1) = worldpoint(:,index,1) + ...
        cumrot*endpoint(:,index+1);
end

%% Find world point corresponding to flexion axes 

knee_points = worldpoint(:,7:8);
ankle_points = worldpoint(:,9:10);

knee_flex = interp1(knee_points(3,:)',knee_points(1:2,:)',zplane)';
ankle_flex = interp1(ankle_points(3,:)',ankle_points(1:2,:)',zplane,'linear','extrap')';

%% Get axes of different frames
pelvis_axes = eye(3);
femur_axes = eye(3);
tibia_axes = eye(3);
foot_axes = eye(3);

pelvis_origin = worldpoint(:,3);
femur_origin = worldpoint(:,6);
tibia_origin = worldpoint(:,8);
foot_origin = worldpoint(:,10);

% pelvis axes is after 3 joints
for index = 1:3
    pelvis_axes = squeeze(rots(:,:,index))*pelvis_axes;
end

% femur axes is after 6 joints
for index = 1:6
    femur_axes = squeeze(rots(:,:,index))*femur_axes;
end

% tibia axes is after 8 joints
for index = 1:8
    tibia_axes = squeeze(rots(:,:,index))*tibia_axes;
end

% foot axes is after 10 joints
for index = 1:10
    foot_axes = squeeze(rots(:,:,index))*foot_axes;
end

%% Extract necessary muscles
muscles = struct2table(nmcb.ms);
muscle_list = {'bfa','bfp','psoas','rf','mg','vl','sol','ta'};

muscles = muscles(contains(muscles.name,muscle_list),:);
oiv_world = cell(height(muscles),1);

for musc_idx = 1:height(muscles)
    oiv = muscles.oiv{musc_idx};
    oivsegment = muscles.oivsegment{musc_idx};
    oiv_world{musc_idx} = oiv;
    for oiv_idx = 1:size(oiv,1)
        if strcmp(oivsegment{oiv_idx},'pelvis')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*pelvis_axes'+pelvis_origin';
        elseif strcmp(oivsegment{oiv_idx},'femur')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*femur_axes'+femur_origin';
        elseif strcmp(oivsegment{oiv_idx},'tibia')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*tibia_axes'+tibia_origin';
        elseif strcmp(oivsegment{oiv_idx},'foot')
            oiv_world{musc_idx}(oiv_idx,:) = oiv(oiv_idx,:)*foot_axes'+foot_origin';
        else
            error('wrong frame')
        end
    end
end

muscles = [muscles cell2table(oiv_world,'VariableNames',{'oiv_world'})];

%% plot muscle points
h=plot3(worldpoint(1,:,1), worldpoint(2,:,1), worldpoint(3,:,1), 'k.-');
hold on
for musc_idx = 1:height(muscles)
    oiv_world = muscles.oiv_world{musc_idx};
    plot3(oiv_world(:,1),oiv_world(:,2),oiv_world(:,3),'r.-')
end
axis equal