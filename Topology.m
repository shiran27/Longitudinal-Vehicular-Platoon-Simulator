classdef Topology < handle 
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        startNodes
        endNodes
        
        numOfNodes 
        graph  % store the topology as a matlab digraph variable

        inNeighbors
        outNeighbors
    end

    methods

        function obj = Topology(n_k,startNodes,endNodes,nodeNames)
            if nargin == 1

                [startNodes,endNodes,nodeNames] = obj.generateAUniformTopology(n_k);
                % [startNodes,endNodes,nodeNames] = obj.generateARandomTopology(n_k);
%                 [startNodes,endNodes,nodeNames] = obj.generateABlankTopology(n_k);
               % [startNodes,endNodes,nodeNames] = obj.generateAFullyConnectedTopology(n_k);
%                [startNodes,endNodes,nodeNames] = obj.generateAHalfRandomTopology(n_k);

            end
            obj.startNodes = startNodes;
            obj.endNodes = endNodes; 
            obj.numOfNodes = n_k;
            weights = ones(length(startNodes),1);
            
            % Here, we need the digraph for further compute the graph matrices
            obj.graph = digraph(startNodes,endNodes,weights,nodeNames);
            obj.loadNeighborSets();
                        
        end

        function newObj = copy(obj)
            % Create a new object of the same class
            newObj = Topology(obj.numOfNodes, obj.startNodes, obj.endNodes, obj.graph.Nodes.Name);

            % Copy each property
            newObj.startNodes = obj.startNodes;
            newObj.endNodes = obj.endNodes;
            newObj.numOfNodes = obj.numOfNodes;
            newObj.graph = digraph(obj.graph.Edges, obj.graph.Nodes);
            newObj.inNeighbors = obj.inNeighbors;
            newObj.outNeighbors = obj.outNeighbors;
        end

        % function newTopology = removeNodes(obj,nodeIndices)
        %     newTopology = copy(obj);
        %     numOfNodes = 0;
        %     for i = 1:1:obj.numOfNodes
        %         if ~any(nodeIndices == i)
        %             nodeNames{i} = num2str(i-1);
        %             numOfNodes = numOfNodes + 1;
        %         end
        %     end
        % 
        %     startNodes = [];
        %     endNodes = [];
        %     for i = 1:1:length(obj.startNodes)
        %         if ~any(nodeIndices == obj.startNodes(i)) && ~any(nodeIndices == obj.endNodes(i)) 
        %             startNodes = [startNodes, obj.startNodes(i)];
        %             endNodes = [endNodes, obj.endNodes(i)];
        %         end
        %     end
        % 
        %     newTopology.startNodes = startNodes;
        %     newTopology.endNodes = endNodes; 
        %     newTopology.numOfNodes = numOfNodes;
        %     weights = ones(length(startNodes),1);
        % 
        %     % Here, we need the digraph for further compute the graph matrices
        %     newTopology.graph = digraph(startNodes,endNodes,weights,nodeNames);
        %     newTopology.loadNeighborSets();
        % end

        function obj = removeNodes(obj, nodeIndices)
                       
            % Remove the nodes from the graph
            for i = 1:length(nodeIndices)
                obj.graph = rmnode(obj.graph, nodeIndices(i));
            end
            
            % Create a mapping from old indices to new indices
            oldIndices = setdiff(1:(obj.numOfNodes + length(nodeIndices)), nodeIndices);
            newIndices = 1:obj.numOfNodes;
            indexMapping = containers.Map(oldIndices, newIndices);
            
            % Update the start and end nodes using the mapping
            startNodes = [];
            endNodes = [];
            startNodesCell = obj.graph.Edges.EndNodes(:, 1)';
            endNodesCell = obj.graph.Edges.EndNodes(:, 2)';
            for i = 1:length(startNodesCell)
                startNodes = [startNodes, indexMapping(eval(startNodesCell{i}) + 1)];
                endNodes = [endNodes, indexMapping(eval(endNodesCell{i}) + 1)];
            end
            obj.startNodes = startNodes;
            obj.endNodes = endNodes;

            
            % Update the number of nodes
            obj.numOfNodes = numnodes(obj.graph);
            

            % Reload the neighbor sets
            obj.loadNeighborSets();
        end

        function [startNodes,endNodes,nodeNames] = generateAUniformTopology(obj,n_k)
            startNodes = [];
            endNodes = [];
            for i = 1:1:n_k
                nodeNames{i} = num2str(i-1);
                if i <= 2
                    startNodes = [startNodes, i];
                    endNodes = [endNodes, i+1];
                elseif i > 2 && i < n_k
                    startNodes = [startNodes, i,i];
                    endNodes = [endNodes, i+1,i-1];
                elseif i == n_k
                    startNodes = [startNodes, i];
                    endNodes = [endNodes, i-1];
                end
            end
        end 

        function [startNodes,endNodes,nodeNames] = generateARandomTopology(obj,NBar)
            startNodes = [];
            endNodes = [];
            for i = 1:1:NBar
                nodeNames{i} = num2str(i-1);
                % From node i, there can be links going to all other NBar nodes 
                for j = 1:1:NBar
                    if j ~= 1 && j~=i 
                        if abs(i-j)<=1 % If i and j are adjacent, add a link from i to j
                            startNodes = [startNodes,i];
                            endNodes = [endNodes,j];
                        elseif rand(1) <= 0.8*(1/abs(i-j))
                            startNodes = [startNodes,i];
                            endNodes = [endNodes,j];
                        end
                    end
                end

            end
        end

        function [startNodes,endNodes,nodeNames] = generateABlankTopology(obj,NBar)
            startNodes = [];
            endNodes = [];
            for i = 1:1:NBar
                nodeNames{i} = num2str(i-1);
                startNodes = [startNodes,1];
                endNodes = [endNodes,i];
            end
        end

        function [startNodes,endNodes,nodeNames] = generateAFullyConnectedTopology(obj,NBar)
            startNodes = [];
            endNodes = [];
            for i = 1:1:NBar
                nodeNames{i} = num2str(i-1);
                % From node i, there can be links going to all other NBar nodes 
                for j = 1:1:NBar
                    if j ~= 1 && j~=i 
                        startNodes = [startNodes,i];
                        endNodes = [endNodes,j];
                    end
                end
            end
        end

        function [startNodes,endNodes,nodeNames] = generateAHalfRandomTopology(obj,NBar)
            startNodes = [];
            endNodes = [];
            for i = 1:1:NBar
                nodeNames{i} = num2str(i-1);
                % From node i, there can be links going to all other NBar nodes 
                for j = 1:1:NBar
                    if j~=1 && j~=i
                        if abs(i-j)<=1 % If i and j are adjacent, add a link from i to j
                            if i < j
                                startNodes = [startNodes,i];
                                endNodes = [endNodes,j];
                            end
                        elseif rand(1) <= 0.9*(1/abs(i-j))
                            if i < j
                                startNodes = [startNodes,i];
                                endNodes = [endNodes,j];
                            end
                        end
                    end
                end
            end
        end


        function neighborSets = loadNeighborSets(obj)

            for i = 1:1:obj.numOfNodes
                inNeighbors{i} = predecessors(obj.graph,i);
                outNeighbors{i} = successors(obj.graph,i);
            end
            obj.inNeighbors = inNeighbors;
            obj.outNeighbors = outNeighbors; 
                        
        end


        function connectedToNeighbor = getTopologyLeader(obj)
            connectedToNeighbor = zeros(obj.numOfNodes,1);
            for i = 1:1:obj.numOfNodes
                if any(obj.inNeighbors{i}==1)
                    connectedToNeighbor(i) = 1;
                end
            end
        end

    end
end







