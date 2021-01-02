classdef ciBurstCamera < ciCamera
    %CIBURSTCAMERA Sub-class of ciCamera that adds burst and bracketing
    %   Basic multi-capture functionality, to be used for testing
    %   and as a base class for additional enhancements
    
    % History:
    %   Initial Version: D.Cardinal 12/2020

    properties
    end
    
    methods
        function obj = ciBurstCamera()
            %CIBURSTCAMERA Construct an instance of this class
            %   First invoke our parent ciCamera class
            obj = obj@ciCamera();

        end
        
       function ourPicture = TakePicture(obj, scene, intent)
            
            ourPicture = TakePicture@ciCamera(obj, scene, intent);
            % Typically we'd invoke the parent before or after us
            % or to handle cases we don't need to
            % Let's think about the best way to do that.
            % Otherwise could be some other type of specialized call?
            
       end
       
       % Decides on number of frames and their exposure times
       % based on the preview image passed in from the camera module
       function [expTimes] = planCaptures(obj, previewImage, intent)
           
           baseExposure = .05; % should calculate from preview image!
           numFrames = 5; %generic
           if numFrames > 1 && ~isodd(numFrames)
               numFrames = numFrames + 1;
           end
           frameOffset = (numFrames -1) / 2; 
           switch intent
               case 'HDR'
                   expTimes = repmat(baseExposure, 1, numFrames);
                   expTimes = expTimes.*(2.^[-1*frameOffset:1:frameOffset]);
               case 'Burst'
                   % algorithm here to calculate number of images and 
                   % exposure time based on estimated processing power,
                   % lighting, and possibly motion/intent
                   expTimes = repmat(baseExposure, 1, numFrames);
                   
               otherwise
                   [expTimes] = planCaptures@ciCamera(obj, previewImage, intent);
           end
       end
       
       % over-ride default processing to allow sum & hdr, for example:
       % should we also get intent passed here?
       function ourPhoto = computePhoto(obj, sensorImages, intent)

           switch intent
               case 'HDR'
                   % ipCompute for HDR assumes we have an array of voltages
                   % in a single sensor, NOT an array of sensors
                   % so first we merge our sensor array into one sensor
                   % For now this is simply concatenating, but could be
                   % more complex in a sub-class that wanted to be more
                   % clever
                   sensorImage = obj.isp.mergeSensors(sensorImages);
                   sensorImage = sensorSet(sensorImage,'exposure method', 'bracketing');
                   
                   ipHDR = ipSet(obj.isp.ip, 'render demosaic only', 'true');
                   ipHDR = ipSet(ipHDR, 'combination method', 'longest');
                   
                   % old ipBurstMotion  = ipCompute(ipBurstMotion,sensorBurstMotion);
                   % if we want to use the existing ipCompute we need to
                   % combine multiple sensors into one, with all the data &
                   % exposure times. Otherwise ipCompute gets confused if
                   % it is handed multiple sensors. It thinks those are
                   % something else.
                   ipHDR = ipCompute(ipHDR, sensorImage);
                   ourPhoto = ipHDR;
               case 'Burst'
                   % baseline is just sum the voltages
                   sensorImage = obj.isp.mergeSensors(sensorImages);
                   sensorImage = sensorSet(sensorImage,'exposure method', 'burst');

                   ipBurst = ipSet(obj.isp.ip, 'render demosaic only', 'true');
                   ipBurst = ipSet(ipBurst, 'combination method', 'sum');
                   
                   % old ipBurstMotion  = ipCompute(ipBurstMotion,sensorBurstMotion);
                   ipBurst = ipCompute(ipBurst, sensorImage);
                   ourPhoto = ipBurst;
               otherwise
                   ourPhoto = computePhoto@ciCamera(obj, sensorImages, intent);
           end
           %{
           % generic base code
           for ii=1:numel(sensorImages)
               sensorWindow(sensorImages(ii));
               ourPhoto = obj.isp.compute(sensorImages(ii));
               ipWindow(ourPhoto);
           end
           %}
           
       end
    end
end
