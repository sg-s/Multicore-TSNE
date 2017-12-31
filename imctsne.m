% imctsne.m
% MATLAB wrapper for Dmitry Ulyanov's Multicore t-SNE 
% implementation
% this wrapper assumes you have the python wrapper set up
% and calls that. 
% also supports an interactive mode so you can
% pick a nice perplexity and view the embedding 
% before settling on it. 

function R = imctsne(Vs,C)


	if nargin == 2
		% color provided
		c = parula(100);

		cidx = C;

		colorbar_limits = [min(C) max(C)];

		cidx = cidx - min(cidx);
		cidx = cidx/max(cidx);
		cidx = ceil(cidx*99) + 1;

		C = c(cidx,:);

	else
		% no color, default to grey
		C = zeros(length(Vs),3) + .5;
	end


	R = NaN(2,length(C));

	opacity = .5;

	% make the UI
	handles.fig = figure('Name','Interactive t-SNE','NumberTitle','off','position',[50 50 1000 700], 'Toolbar','figure','Menubar','none','CloseRequestFcn',@close_imctsne,'WindowButtonDownFcn',@mouseCallback); hold on,axis off
	handles.ax(1) = axes('parent',handles.fig,'position',[-0.1 0.1 0.85 0.85],'box','on','TickDir','out');axis square, hold on ; title('Reduced Data');
	axis off
	handles.red_data = scatter(R(1,:),R(2,:),128,C,'filled','Marker','o','MarkerFaceAlpha',opacity,'MarkerEdgeAlpha',opacity);


	if nargin == 2
		handles.color_bar = colorbar;
		handles.color_bar.Position = [.65 .5 .02 .45];
		caxis(colorbar_limits)
	end

	handles.ax(2) = axes('parent',handles.fig,'position',[0.65 0.1 0.3 0.3],'box','on','TickDir','out');axis square, hold on  ; title('Raw data'), set(gca,'YLim',[min(min(Vs)) max(max(Vs))]);
	set(handles.ax(1),'XTickLabel',{},'YTickLabel',{})




	if size(Vs,2) > 200
		sls = floor(22939/200);
		handles.full_data = plot(handles.ax(2),Vs(:,1:sls:end),'Color',[.7 .7 .7]);
	else
		handles.full_data = plot(handles.ax(2),Vs,'Color',[.7 .7 .7]);
	end

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



	function embed(params)

		perplexity = floor(params.perplexity);
		n_iter = floor(params.n_iter);


		R = mctsne(Vs,n_iter,perplexity);

		handles.red_data.XData = R(1,:);
		handles.red_data.YData = R(2,:);

		xr =  max(R(1,:)) - min(R(1,:));
		yr =  max(R(2,:)) - min(R(2,:));

		handles.ax(1).XLim = [min(R(1,:)) - xr/10 max(R(1,:)) + xr/10];
		handles.ax(1).YLim = [min(R(2,:)) - yr/10 max(R(2,:)) + yr/10];

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