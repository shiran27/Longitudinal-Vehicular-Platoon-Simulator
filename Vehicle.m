classdef Vehicle < handle
    %FACILITY Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

        % Indices
        platoonIndex      % k
        vehicleIndex      % i

        % Parameters
        vehicleParameters
        noiseMean
        noiseStd

        % Passivity Indices
        nu
        rho

        % ControllerGains
        controllerGains1 = []
        controllerGains2 = []
        
        % States
        desiredSeparation    %From the leader
        desiredSeparations   %From all others
        states               % x_ik
        noise                % v_ik
        controlInput
        errors
        outputs

        % state history
        stateHistory = []

        % error history
        errorHistory = []

        % Predefined controls
        plannedControls = [] % matrix of paris [t_i,u_i]

        % GeometricProperties (for plotting)          
        inNeighbors = []
        outNeighbors = []

        % graphicHandles
        graphics = []
    end
    
    methods

        function obj = Vehicle(k,i,parameters,states,desiredSeparation,noiseMean,noiseStd)

            % Constructor
            obj.platoonIndex = k;
            obj.vehicleIndex = i;

            obj.vehicleParameters = parameters;                     %[mass,length,height1,height2]

            obj.states = states;                                      % states of the i^{th} vehicle
            obj.desiredSeparation = desiredSeparation;                              % need to track this signal (desired position,velocity and 0 acceleration for i^{th} vehicle)
            
            
            % External disturbances represented by random noise
            obj.noiseMean = noiseMean;
            obj.noiseStd = noiseStd;

            obj.noise = noiseMean + noiseStd*randn(1);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Initial controller values
            obj.errors = zeros(3,1);
            obj.controlInput = zeros(1);
            obj.outputs = zeros(1);
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            obj.inNeighbors = [];
            obj.outNeighbors = [];
            
        end


        % This function is used to draw a "car" shape object
        function outArg = drawVehicle(obj,figNum)
            figure(figNum); hold on;
      
            length = obj.vehicleParameters(2);
            height1 = obj.vehicleParameters(2)/8;
            height2 = obj.vehicleParameters(2)/8;
            radius = obj.vehicleParameters(2)/16;
            pos = obj.states(1);
            
           
            % Draw the car body
            % poly1 = polyshape([pos, (pos-length), (pos-length), pos],[0.5, 0.5, 0.5+height1, 0.5+height1]+8*(obj.platoonIndex-1)*[1, 1, 1, 1]);
            poly1 = polyshape([pos, (pos-length), (pos-length), pos],[0.5, 0.5, 0.5+height1, 0.5+height1]);
            obj.graphics(1) = plot(poly1,'FaceColor','r');

%             poly2 = polyshape([0.5*(pos+0.5*(pos+(pos-length))), 0.5*((pos-length)+0.5*(pos+(pos-length))),...
%                 0.5*((pos-length)+0.5*(pos+(pos-length))), 0.5*(pos+0.5*(pos+(pos-length)))],...
%                 [0.5+height1, 0.5+height1, (0.5+height1)+height2, (0.5+height1)+height2]+8*(obj.platoonIndex-1)*[1, 1, 1, 1]);
            poly2 = polyshape([0.5*(pos+0.5*(pos+(pos-length))), 0.5*((pos-length)+0.5*(pos+(pos-length))),...
                0.5*((pos-length)+0.5*(pos+(pos-length))), 0.5*(pos+0.5*(pos+(pos-length)))],...
                [0.5+height1, 0.5+height1, (0.5+height1)+height2, (0.5+height1)+height2]);
            obj.graphics(2) = plot(poly2,'FaceColor','r');
            
            % Draw two wheels
%             viscircles([0.5*((pos-length)+0.5*(pos+(pos-length))), 0.3+8*(obj.platoonIndex-1)], 0.3,'Color','k');
%             viscircles([0.5*(pos+0.5*(pos+(pos-length))), 0.3+8*(obj.platoonIndex-1)], 0.3,'Color','k');

            obj.graphics(3) = viscircles([0.5*((pos-length)+0.5*(pos+(pos-length))), 0.3], radius,'Color','k');
            obj.graphics(4) = viscircles([0.5*(pos+0.5*(pos+(pos-length))), 0.3], radius,'Color','k');

            % Vehicle number
            obj.graphics(5) = text(pos,0.2,num2str(obj.vehicleIndex));
        end


        % This function is used to plot the real time states (i.e., position) of the 
        % i^{th} vehicle at the position before each vehicle
%         function outputArg = drawState(obj,figNum)
%             figure(figNum); hold on;
% 
%             if ~isempty(obj.graphics)
%                 delete(obj.graphics)
%             end
%             
%         end

        function outputArg = redrawVehicle(obj,figNum)
            figure(figNum); hold on;

            if ~isempty(obj.graphics)
                delete(obj.graphics);

                length = obj.vehicleParameters(2);
                height1 = obj.vehicleParameters(2)/8;
                height2 = obj.vehicleParameters(2)/8;
                radius = obj.vehicleParameters(2)/16;
                pos = obj.states(1);
            
           
                % Draw the car body
                poly1 = polyshape([pos, (pos-length), (pos-length), pos],[0.5, 0.5, 0.5+height1, 0.5+height1]);
                obj.graphics(1) = plot(poly1,'FaceColor','r');
                
                poly2 = polyshape([0.5*(pos+0.5*(pos+(pos-length))), 0.5*((pos-length)+0.5*(pos+(pos-length))),...
                0.5*((pos-length)+0.5*(pos+(pos-length))), 0.5*(pos+0.5*(pos+(pos-length)))],...
                [0.5+height1, 0.5+height1, (0.5+height1)+height2, (0.5+height1)+height2]);
                obj.graphics(2) = plot(poly2,'FaceColor','r');
            
                % Draw two wheels
                obj.graphics(3) = viscircles([0.5*((pos-length)+0.5*(pos+(pos-length))), 0.3], radius,'Color','k');
                obj.graphics(4) = viscircles([0.5*(pos+0.5*(pos+(pos-length))), 0.3], radius,'Color','k');
                
                % Vehicle number
                obj.graphics(5) = text(pos,0,num2str(obj.vehicleIndex));
            end
            
        end



        function outputArg = generateNoise(obj)

            if obj.vehicleIndex==1
                w = 0; % Leader is not affected by the noise.
            else 
                w = obj.noiseMean + obj.noiseStd.*randn(3,1);
            end

            obj.noise = w;

            %%%% Some old code
%             stepSize = 1;
%             if w < obj.noise - stepSize
%                 w = obj.noise - stepSize;
%             elseif w > obj.noise + stepSize
%                 w = obj.noise + stepSize;
%             end

        end

        function outputArg = computePlatooningErrors1(obj,leaderStates,neighborInformation)

            locationError = 0;
            velocityError = 0;

            for jInd = 1:1:length(obj.inNeighbors)

                j = obj.inNeighbors(jInd);
                k_ijBar = obj.controllerGains1{j};
                d_ij = obj.desiredSeparations(j);
                X_j = neighborInformation{j};

                locationError_j = k_ijBar*(obj.states(1)-X_j(1)-d_ij);
                locationError = locationError + locationError_j;

                velocityError_j = k_ijBar*(obj.states(2)-X_j(2));
                velocityError = velocityError + velocityError_j;
                
            end

            accelerationError = obj.states(3)-leaderStates(3); %a_i-a_0

            newErrors = [locationError;velocityError;accelerationError];

            obj.errors = newErrors;
            obj.errorHistory = [obj.errorHistory, newErrors];

        end

        function outputArg = computePlatooningErrors2(obj,leaderStates)
            separationFromLeader = obj.desiredSeparation; 
            newErrors = obj.states - leaderStates + [separationFromLeader;0;0];
            obj.errors = newErrors;
            obj.errorHistory = [obj.errorHistory, newErrors];
        end


        function outputArg = computeControlInputs1(obj,t)
            
            if obj.vehicleIndex==1  % Leader's control (from planned)
                
                if obj.plannedControls(1,1)==t
                    obj.controlInput = obj.plannedControls(1,2);
                    obj.plannedControls = obj.plannedControls(2:end,:); % Delete the executed planned control
                else
                    obj.controlInput = 0;
                end

            else                    % Followers control (based on errors) under Error-Dynamics - I
                
                i = obj.vehicleIndex;
                L_ii = obj.controllerGains1{i};
                e_i = obj.errors;
                obj.controlInput = L_ii*e_i;

            end
        end

        function outputArg = computeControlInputs2(obj,t,neighborInformation)
            
            if obj.vehicleIndex==1  % Leader's control (from planned)
                
                if obj.plannedControls(1,1)==t
                    obj.controlInput = obj.plannedControls(1,2);
                    obj.plannedControls = obj.plannedControls(2:end,:); % Delete the executed planned control
                else
                    obj.controlInput = 0;
                end

            else                    % Followers control (based on errors) under Error-Dynamics - II
               
                i = obj.vehicleIndex;
                L_ii = obj.controllerGains2{i};
                e_i = obj.errors;
                controlInput = L_ii*e_i;
                for jInd = 1:1:length(obj.inNeighbors)
                    j = obj.inNeighbors(jInd);
                    if j~=1
                        L_ij = obj.controllerGains2{j};
                        e_j = neighborInformation{j};
                        controlInput = controlInput + L_ij*(e_i - e_j);
                    end 
                end
                obj.controlInput = controlInput;
                
            end
        end


        % Update the state values of the system dynamics
        function vehicleError = update(obj,t,dt)
            
            vehicleError = obj.errors;

            A = [0 1 0; 0 0 1; 0 0 0];
            B = [0 0 1]';

            updateValue = A*obj.states + B*obj.controlInput + obj.noise;
            
            newStates = obj.states + dt*(updateValue);
            obj.states = newStates;                     
            
            % Collect all the state points at each step
            obj.stateHistory = [obj.stateHistory, newStates];

        end


        function outputArg = loadPassivityIndices(obj,nu,rho)
            obj.nu = nu;
            obj.rho = rho;
        end

        function [LVal,rhoVal] = synthesizeLocalControllers(obj)
            % Here we will synthesize the local controllers for local error
            % dynamics to optimize the passivity properties
            
            % Error Dynamics Type
            errorDynamicsType = 1;
            tau = 1; % Irrespective of this value, both methods seems to lead to rho = -1/2
            if errorDynamicsType == 1       % When nu = 0, both methods seems to lead to rho = -1/2 
                A = [0,1,0;0,0,0;0,0,-1/tau];    
            else
                A = [0,1,0;0,0,1;0,0,-1/tau];    
            end
            B = [0;0;1];
            I = eye(3);
            
            % Set up the LMI problem
            solverOptions = sdpsettings('solver','mosek');            
            P = sdpvar(3,3,'symmetric'); 
            K = sdpvar(1,3,'full'); 
            rho = sdpvar(1,1,'full');
            nu = sdpvar(1,1,'full');

            X_11 = -nu*I;
            X_22 = -rho*I;
            X_12 = 0.5*I;
            X_21 = X_12';
            alpha = -1;

            % Basic Constraints
            con1 = P >= 0;
            con2 = trace(P)==1;
            
            % Approach 1 with nu=0
            W = -2*(A+A')-B*K-K'*B'-4*rho*I;
            % Approach 2 without nu=0 (still bilinear)
            %W = [-A*P-P*A'-B*K-K'*B'+alpha*(P*X_22+X_22*P)-alpha^2*X_22, -I+P*X_21; -I+X_12*P, X_11]
            
            con3 = W >= 0;
            

            % Total Cost and Constraints
            cons = [con1,con2,con3];
            costFun = -rho;
            
            % Solution
            sol = optimize(cons,[costFun],solverOptions);
                        
            PVal = value(P)
            KVal = value(K)

            LVal = KVal/PVal
            rhoVal = value(rho)

            status = sol.info
            
        end


    end
end

