function [Data] = WarmUpTM(Settings)

%option to add a 5-second pause before treadmill starts
pause(5);

%% Connect to Vicon
% Load the SDK
HostName = 'localhost:801';

MyClient = ViconDataStreamSDK.DotNET.Client();
MyClient.Connect( HostName );

% Enable some different data types
MyClient.EnableDeviceData();

%Set the streaming mode
MyClient.SetStreamMode( ViconDataStreamSDK.DotNET.StreamMode.ClientPull );

%Set global axis (I think this is the default, but just in case!)
MyClient.SetAxisMapping( ViconDataStreamSDK.DotNET.Direction.Forward,...
    ViconDataStreamSDK.DotNET.Direction.Left,...
    ViconDataStreamSDK.DotNET.Direction.Up );

% % Discover the version number
Output_GetVersion = MyClient.GetVersion();
version = sprintf( 'Version: %d.%d.%d\n', Output_GetVersion.Major, ...
                                          Output_GetVersion.Minor, ...
                                          Output_GetVersion.Point ); 
                                      
%% initiate treadmill start by detecting forces

currentSpeed = Settings.Speed; % set speed in m/s
acc = 0.5; %acceleration, m/s^2
inc = 0; %incline

%treadmill units are mm/s, hence the multiply by 1000!
setTreadmill( currentSpeed*1000, currentSpeed*1000, acc*1000, acc*1000, inc );
                                      
%% Initialize data structure
Frame = 1; %frame numbers in our dataset
k = 0; %indices of our dataset

Data = struct([]);

disp('Starting Warm-Up Trial');
tic; % start timer
startTime = datevec(now); % create elapsed timer

%% Get the warm-up data
timer = 0;
while timer <= Settings.Duration
    
    %get the frame from Vicon SDK
    MyClient.GetFrame();
    
    %check how much time has passed
    timer = toc;
    
    iFrame = MyClient.GetFrameNumber();
    if iFrame.FrameNumber > Frame
        
        k = k+1;
        Frame = iFrame.FrameNumber;
        
        % extract forces
        FzL = MyClient.GetDeviceOutputValue('LeftForcePlate','Fz').Value;
        FzR = MyClient.GetDeviceOutputValue('RightForcePlate','Fz').Value;
        FyL = MyClient.GetDeviceOutputValue('LeftForcePlate','Fy').Value;
        FyR = MyClient.GetDeviceOutputValue('RightForcePlate','Fy').Value;
        
        %% Save Treadmill data in structure
        Data(k).Frame = iFrame.FrameNumber;
        
        % save forces (in N)
        Data(k).FyL = FyL;
        Data(k).FzL = FzL;
        Data(k).FyR = FyR;
        Data(k).FzR = FzR;
        
        % save whether the individual is in swing or stance for left and right
        if mean(abs(FzR)) > Settings.Threshold
            Data(k).RightOn = 1;
        else
            Data(k).RightOn = 0;
        end
        if mean(abs(FzL)) > Settings.Threshold
            Data(k).LeftOn = 1;
        else
            Data(k).LeftOn = 0;
        end
        
        %% Get current time
        currTime = datevec(now);
        ElapsedTime = etime(currTime, startTime);
        Data(k).Time = ElapsedTime; 
        
    end
end

%% stop treadmill after trial time is done
disp('Stopping Treadmill');
currentSpeed = 0;
%set speed (mm/s):
setTreadmill( currentSpeed*1000, currentSpeed*1000, acc*1000, acc*1000, inc );

end