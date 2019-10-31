classdef SMLMModelFitGUI<interfaces.SEEvaluationProcessor

    methods
        function obj=SMLMModelFitGUI(varargin)
            obj@interfaces.SEEvaluationProcessor(varargin{:});
        end
        
        function out=run(obj, inp, varargin)
            p = inputParser;
            addParameter(p,'onlySetUp',false, @islogical);
            addParameter(p,'forceDisplay',false, @islogical);
            parse(p,varargin{:});
            results = p.Results;
            out=runSMLMModelFitGUI(obj, inp, results.onlySetUp, results.forceDisplay);
        end
        
        function makeGui(obj,varargin)
            %% init settings
            obj.setPar('currentLoadedModel',[]);
            % field names in the parsArg table
            fnParsArg={'name','value','fix','lb','ub','type','min','max','label'};
            lFnParsArgEdit = logical([0 1 1 1 1 0 1 1 1]);
            fnParsArgColWidth = {50,35,20,30,30,30,30,30,30};
            obj.setPar(['parsArgFieldnames_' obj.name], fnParsArg);
            obj.setPar(['lFnParsArgEdit_' obj.name], lFnParsArgEdit);
            obj.setPar(['fnParsArgColWidth_' obj.name], fnParsArgColWidth);
            % field names in the layer table
            fnLayer ={'layer','value','fix','lb','ub','min','max'};
            fnLayerColWidth = {30,35,20,30,30,30,30};
            lFnLayerEdit = logical([0 1 1 1 1 1 1]);
            obj.setPar(['layerFieldnames_' obj.name], fnLayer);
            obj.setPar(['lFnLayerEdit_' obj.name], lFnLayerEdit);
            
            if nargin >2 && varargin{2}==true %gui of tabs
                 makeGui@interfaces.GuiModuleInterface(obj,varargin{1});
            else %real make GUI of main gui
                makeGui@interfaces.GuiModuleInterface(obj); %make the main GUI from the guidef definitions
                %Settings               
                optimizernames={'fminsearchbnd','particleswarm'};%if possible, get from fitter object
                obj.guihandles.optimizer.String=optimizernames;
                Data={};
                oldh=obj.guihandles.optimizerpar;
                pos=oldh.Position;
                htable=uitable(oldh.Parent,'Data',Data,'Position',pos);
                htable.ColumnEditable = true;
                htable.ColumnName = {'Setting', 'Value'};
                htable.CellSelectionCallback = {@optimizerSetting_selectionCallback,obj};
                htable.CellEditCallback = {@optimizerSetting_editCallback,obj};
                htable.RowName = [];
                delete(oldh);
                obj.guihandles.optimizerpar=htable;
                
                %% layer settings
                oldh = obj.guihandles.layerSetting;
                pos=oldh.Position;
                hLayer=uitable(oldh.Parent,'Data',{},'Position',pos);
                hLayer.ColumnName = fnLayer;
                hLayer.ColumnEditable = true;
                hLayer.CellEditCallback = {@layerSetting_callback,obj};
                hLayer.RowName = [];
                hLayer.ColumnWidth = fnLayerColWidth;
                delete(oldh);
                obj.guihandles.layerSetting=hLayer;
                
                %% add first module and  + tab
                obj.guihandles.tabgroup=obj.guihandles.tab1.Parent;
                obj.addguitotab(1);
                obj.guihandles.addtab=uitab(obj.guihandles.tabgroup,'Title','+');
                obj.setPar('numMod',1);                 % init of the model counts
                obj.guihandles.tabgroup.SelectionChangedFcn={@selectLayer_callback,obj};
                
                %% Convert               
                addconverttotab(obj);
                oldh=obj.guihandles.anchorConvert;
                pos=oldh.Position;
                htable=uitable(oldh.Parent,'Data',{},'Position',[pos(1:2)+[5 10] 300 200]);
                colNames={'Source', 'Rule', 'Target_fit', 'Target_usr'};
                htable.ColumnName = colNames;
                htable.CellEditCallback = {@convertTable_callback,obj};
                % check the loaded modules and hook the all the SMLMModelFitGUI
                loadedModuls = obj.locData.SE.processors.eval.guihandles.modules.Data(:,2);
                lSMLMModelFitGUI = contains(loadedModuls, 'SMLMModelFitGUI');
                if sum(lSMLMModelFitGUI)>0
                    loadedSMLMModelFitGUI = loadedModuls{lSMLMModelFitGUI};
                else
                    loadedSMLMModelFitGUI = [];
                end
                htable.ColumnFormat = {[{'this step'}; loadedSMLMModelFitGUI]',[],{'none'},[]};
                htable.ColumnEditable = true;
                htable.CellSelectionCallback = {@convertTableSelection_callback,obj};
                htable.RowName = [];
                delete(oldh);
                obj.guihandles.anchorConvert=htable;
                
                %% create the SMLMModelFit
                % check the dim of the data and update the corresponding
                % seeting in the fitter
                if isfield(obj.locData.loc,'znm')
                    dataDim = 3;
                else
                    dataDim = 2;
                end
                fitter = SMLMModelFit('DataDim',dataDim);
                obj.setPar(['fitter_' obj.name], fitter);
            end
        end
        function pard=guidef(obj)
            pard=SMLMModelFitGUIdef(obj);
        end
        
        function addguitotab(obj,number)
            run_addguitotab(obj,number);
        end
        
        function addconverttotab(obj)
            run_addconverttotab(obj);
        end
    end

end

function selectLayer_callback(tabgroup,eventdata,obj) 
    % if + tab selected this makes a new model
    layertitle=(eventdata.NewValue.Title);
    if strcmp(layertitle,'+')
        numtabs=length(tabgroup.Children);
        obj.addguitotab(numtabs-2)
        obj.setPar('numMod',numtabs-2)   % save the number of model
        s=1:length(tabgroup.Children);
        % shift the order of table
        s(end-2)=s(end);
        s(end)=s(end)-2;
        s(end-1)=s(end);
        s(end)=s(end)+1;
        tabgroup.Children=tabgroup.Children(s);
        tabgroup.SelectedTab=tabgroup.Children(end-2); 
    end
end

function convertTable_callback(a,b,obj) 
    if b.Indices(2) == 4
        htable = obj.guihandles.anchorConvert;
        optionTarget = unique([htable.ColumnFormat{3} {['usr_' b.NewData]}]);
        htable.ColumnFormat{3} = optionTarget;
        obj.guihandles.anchorConvert=htable;
    end
end

function layerSetting_callback(a,b,obj) 
    fitter = obj.getPar(['fitter_' obj.name]);
    fn=obj.getPar(['layerFieldnames_' obj.name]);
    indices = b.Indices;
    layer = a.Data{indices(1),1};
    layer = strrep(layer,'layer','9');
    [~,idx] = fitter.wherePar(['pars.m' layer '.offset.weight']);
    fitter.allParsArg.(fn{indices(2)})(idx) = b.NewData;
    obj.setPar(['fitter_' obj.name], fitter);
end

function convertTableSelection_callback(a,b,obj) 
    selectedRow = b.Indices(1);
    obj.setPar(['selectedRowConvert_' obj.name], selectedRow)
end

function optimizerSetting_selectionCallback(a,b,obj)
    try
    selectedRow = b.Indices(1);
    obj.setPar(['selectedRowOptimizer_' obj.name], selectedRow)
    catch
    end
end

function optimizerSetting_editCallback(a,b,obj)
    obj.setPar(['lOptimizerSettingEdited_' obj.name], true)
end