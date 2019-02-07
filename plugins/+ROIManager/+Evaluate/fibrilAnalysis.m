classdef fibrilAnalysis<interfaces.SEEvaluationProcessor
    % This is a plugin in development. Public has no access to the 
    % run_ functions called in this plugin. For internal users, 
    % "fibrilKymograph" is required.
    methods
        function obj=fibrilAnalysis(varargin)        
                obj@interfaces.SEEvaluationProcessor(varargin{:});
        end
        
        function out=run(obj,p)
            out = runFibrilAnalysis(obj,p);
        end
        function pard=guidef(obj)
            pard=guidef(obj);
        end
    end
end

function pard = guidef(obj)
    pard.showPlot.object = struct('Style','checkbox','String','Show fig', 'Value', 0);
    pard.showPlot.position = [1 1];
    pard.showPlot.Width = 1;
    
    pard.t1.object = struct('Style','text','String','Filtering:');
    pard.t1.position = [2 1];
    pard.t1.Width = 1;
    
    pard.axisLb.object = struct('Style','edit','String','0');
    pard.axisLb.position = [2 2];
    pard.axisLb.Width = 0.5;
    
    pard.axisUb.object = struct('Style','edit','String','0');
    pard.axisUb.position = [2 2.5];
    pard.axisUb.Width = 0.5;
    
    pard.redoProjection.object = struct('Style','checkbox','String','Re run','Value', 0);
    pard.redoProjection.position = [3 1];
    pard.redoProjection.Width = 1;

    pard.inputParameters={'numberOfLayers','sr_layerson','se_cellfov','se_sitefov','se_siteroi'};
    pard.plugininfo.type='ROI_Evaluate';
end