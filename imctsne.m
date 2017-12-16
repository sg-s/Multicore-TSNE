% imctsne.m
% MATLAB wrapper for Dmitry Ulyanov's Multicore t-SNE 
% implementation
% this wrapper assumes you have the python wrapper set up
% and calls that. 
% also supports an interactive mode so you can
% pick a nice perplexity and view the embedding 
% before settling on it. 

function R = imctsne(Vs)

	R = NaN;
	save('Vs.mat','Vs','-v7.3')

	% make the UI
	handles.fig = figure('Name','Interactive t-SNE','NumberTitle','off','position',[50 50 1000 700], 'Toolbar','figure','Menubar','none','CloseRequestFcn',@close_imctsne,'WindowButtonDownFcn',@mouseCallback); hold on,axis off
	handles.ax(1) = axes('parent',handles.fig,'position',[-0.1 0.1 0.85 0.85],'box','on','TickDir','out');axis square, hold on ; title('Reduced Data')
	handles.ax(2) = axes('parent',handles.fig,'position',[0.65 0.1 0.3 0.3],'box','on','TickDir','out');axis square, hold on  ; title('Raw data'), set(gca,'YLim',[min(min(Vs)) max(max(Vs))]);
	set(handles.ax(1),'XTickLabel',{},'YTickLabel',{})


	handles.red_data = plot(handles.ax(1),NaN,NaN,'k+');

	handles.full_data = plot(handles.ax(2),Vs,'Color',[.7 .7 .7]);
	handles.current_pt = plot(handles.ax(2),NaN,NaN,'k','LineWidth',2);

	prettyFig('font_units','points');

	% make a puppeteer figure
	lb.n_iter = 100;
	ub.n_iter = 5e3;
	S.n_iter = 1e3;

	lb.perplexity = 3;
	ub.perplexity = 100;
	S.perplexity = 30;

	U.perplexity = '';
	U.n_iter = '';

	embed(S);

	p = puppeteer(S,lb,ub,U,false);
	p.callback_function = @embed;

	uiwait(handles.fig);
	
	% clean up
	delete('data.h5')
	delete('Vs.mat')


	function embed(params)

		perplexity = floor(params.perplexity);
		n_iter = floor(params.n_iter);


		p1 = ['"' fileparts(which('mctsne'))];
		eval_str =  [p1 oss 'mctsne.py" ' oval(perplexity) ' ' oval(n_iter)];

		system(eval_str)

		% read the solution
		R = h5read('data.h5','/R');

		handles.red_data.XData = R(1,:);
		handles.red_data.YData = R(2,:);

		handles.ax(1).XLim = [min(R(1,:)) max(R(2,:))];
		handles.ax(1).YLim = [min(R(2,:)) max(R(2,:))];

	end

	function close_imctsne(~,~)
		delete(handles.fig)
		p.quitManipulateCallback;

	end

	function mouseCallback(src,event)

		% get current point 

		if gca == handles.ax(1)
            pp = get(handles.ax(1),'CurrentPoint');
            pt(1) = (pp(1,1)); pt(2) = pp(1,2);
            x = R(1,:); y = R(2,:);
            [~,cp] = min((x-pt(1)).^2+(y-pt(2)).^2); % cp C the index of the chosen point
            if length(cp) > 1
                cp = min(cp);
            end

            set(handles.current_pt,'YData',Vs(:,cp),'XData',1:length(Vs(:,cp)));

        end

	end


end