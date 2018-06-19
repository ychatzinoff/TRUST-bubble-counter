function varargout = Bubble_Counter(varargin)
% BUBBLE_COUNTER MATLAB code for Bubble_Counter.fig
%      BUBBLE_COUNTER, by itself, creates a new BUBBLE_COUNTER or raises the existing
%      singleton*.
%
%      H = BUBBLE_COUNTER returns the handle to a new BUBBLE_COUNTER or the handle to
%      the existing singleton*.
%
%      BUBBLE_COUNTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BUBBLE_COUNTER.M with the given input arguments.
%
%      BUBBLE_COUNTER('Property','Value',...) creates a new BUBBLE_COUNTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Bubble_Counter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Bubble_Counter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Bubble_Counter

% Last Modified by GUIDE v2.5 16-Apr-2018 10:07:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Bubble_Counter_OpeningFcn, ...
                   'gui_OutputFcn',  @Bubble_Counter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
function Bubble_Counter_OpeningFcn(hObject, eventdata, handles, varargin)
set(handles.slider1,'Value',1);
handles.output = hObject;
guidata(hObject, handles);
function varargout = Bubble_Counter_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in load_file.
function load_file_Callback(hObject, eventdata, handles)
% record home path
here = pwd;
% delete rect to let user choose new ROI
for this_name = {'rect','ffind','raw_image','Nframes'};
    if isfield(handles,this_name)
        handles = rmfield(handles,this_name);
    end
end
% set default values
handles.frames_to_track = 1;
handles.bubble_threshold = get(handles.threshold_slider,'Value');
handles.ind = get(handles.slider1,'Value');
handles.ffind = 1;
set(handles.slider1,'Value',1);
[Filename,Pathname] = uigetfile({'*.ima';'*.avi'});
cd(Pathname)
% hourglass
set(handles.figure1, 'pointer', 'watch')
drawnow;
% if it's a dicom your life is simple
if strcmp(Filename(end),'A')
handles.raw_image = dicomread(Filename);

else % its an AVI
    myvid = VideoReader(Filename);
    len = myvid.Duration * myvid.FrameRate;
    % initialize variable
    handles.raw_image = (zeros(myvid.Height,myvid.Width,3,round(len),'uint8'));
    for ind = 1:len
        handles.raw_image(:,:,:,ind) = readFrame(myvid,'native');
        ind = ind+1;
    end
end
% back to pointer
set(handles.figure1, 'pointer', 'arrow')
cd(here);
set(handles.fpath,'String',Filename);
axes(handles.axes1);
handles.Nframes = length(handles.raw_image);
set(handles.slider1,'Max',handles.Nframes);
handles.nbubs = zeros(handles.Nframes,1);
set(handles.slider1,'SliderStep',[1/handles.Nframes 10/handles.Nframes]);
imshow(handles.raw_image(:,:,:,1));
guidata(hObject,handles);



% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)

axes(handles.axes1);
if handles.ind ~= ceil(hObject.Value)
    imshow(handles.raw_image(:,:,:,ceil(hObject.Value)));
    handles.ind = ceil(hObject.Value);
    guidata(hObject,handles);
    if isfield(handles,'rect')
        handles.h = impoly(handles.axes1,handles.rect);
        id = addNewPositionCallback(handles.h,@myplot);
        my_fred = myplot(handles.rect);
        handles = my_fred;
    end
end

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
set(hObject,'BusyAction','cancel')
set(hObject,'Interruptible','on')
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Lets user select ROI
function select_roi_Callback(hObject, eventdata, handles)
axes(handles.axes1);
if isfield(handles,'h')
    delete(handles.h);
end
imshow(handles.raw_image(:,:,:,ceil(hObject.Value)));
handles.h = impoly;
handles.rect = getPosition(handles.h);
axes(handles.axes1);
ax = gca;
setVerticesDraggable(handles.h,true);
addNewPositionCallback(handles.h,@myplot);
guidata(hObject,handles);
set(handles.figure1, 'pointer', 'arrow')

handles = myplot(handles.rect);


% plot the roi in secondary graph
function[handles] =  myplot(rect)
colormap gray
% get handles
handles = guidata(gcbo);
handles = calculate_params(handles);
%rect= round(rect);
axes(handles.axes2);
% display image
imagesc(handles.I);
centroids = handles.centroids;
% scatter(centroids(:,1)+rect(1),centroids(:,2)+rect(2), 'r*')
title(num2str(length(centroids),'There are %0.0f bubbles'))
daspect([1 1 1]);
% axes(handles.axes1);
hold on
line(centroids(:,1),centroids(:,2),'Color','red','LineStyle','none','Marker','+')
%drawnow limitrate nocallbacks
hold off
handles.rect = rect;
axes(handles.axes3);
plot(handles.nbubs);
line([handles.ffind; handles.ffind],[0;max(handles.nbubs)],'Color','red','LineWidth',4)
line([handles.ind; handles.ind],[0;max(handles.nbubs)],'Color','blue','LineWidth',2)
ave_bubbles = mean(handles.nbubs(handles.ffind:handles.ind));
title( num2str(ave_bubbles,'Average Bubble Count: %0.0f'))
guidata(gcbo,handles);


function[handles] = calculate_params(handles)
% This is the main calculation function
ind = handles.ind;
rect = handles.rect;
minX = min(rect(:,2));
minY = min(rect(:,1));
rangeX = round(max(rect(:,2)) - min(rect(:,2)));
rangeY = round(max(rect(:,1)) - min(rect(:,1)));
minX = floor(minX);
minY = floor(minY);
% here's whete it actually starts
mymask = uint8(poly2mask(rect(:,1),rect(:,2),size(handles.raw_image,1),size(handles.raw_image,2)));
mymask = mymask(minX:minX+rangeX-1,minY:minY+rangeY-1);
I0 = rgb2gray(handles.raw_image(minX:minX+rangeX-1,minY:minY+rangeY-1,:,handles.ffind)) .* mymask;
I = rgb2gray(handles.raw_image(minX:minX+rangeX-1,minY:minY+rangeY-1,:,round(ind))) .* mymask;
I = I-I0;
% range stretching
I = imadjust(I,stretchlim(I),[]);
% % Threshold twice to remove vals < median
I(I<=median(I(I>0))) = 0;
I(I<=median(I(I>0))) = 0;
% Threshold based on value
I(I<=handles.bubble_threshold) = 0;
% median filter
handles.I = medfilt2(I);

% % gaussian filter
% I = imgaussfilt(I,1);
% binarize
BW = imbinarize(I);
% % erode
% SE = strel('disk',1,4);
% BW = imerode(BW,SE);
% connected components
CC = bwconncomp(BW);
% create mask
CC_mask = zeros(size(BW));
len2 = cellfun(@length,CC.PixelIdxList);
% limit to groups larger than 10
CC_sub = CC.PixelIdxList(len2>8);
CC_mask(cell2mat((CC_sub(:))))=1;
% regionalmax
I2 = imregionalmax(I.*uint8(CC_mask));
% % I2 reint
% I2 = uint8(I2);
s = regionprops(I2,'centroid');
handles.centroids = cat(1, s.Centroid);
handles.nbubs(ind) = length(handles.centroids);
handles.nbubs(1:handles.ffind) = 0;



% --- Executes on button press in first_frame.
function first_frame_Callback(hObject, eventdata, handles)
handles.ffind = round(get(handles.slider1,'Value'));
guidata(hObject,handles);
 

% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
handles.bubble_threshold = get(hObject,'Value');
guidata(hObject,handles);
handles = myplot(handles.rect);
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(hObject,'Min',1);
set(hObject,'Max',255);
% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in togglebutton1.
function togglebutton1_Callback(hObject, eventdata, handles)
handles = guidata(gcbo);
if get(hObject,'Value')
    set(hObject,'String','Pause')
    if handles.ind <= handles.Nframes
        set(handles.slider1,'Value',get(handles.slider1,'Value')+1);
        
        slider1_Callback(handles.slider1, eventdata, handles)
        pause(1/21)
        togglebutton1_Callback(hObject, eventdata, handles);
    end
else
    set(hObject,'String','Play')
end



function frames_to_track_Callback(hObject, eventdata, handles)
handles.frames_to_track = str2num(get(hObject,'String'));
if handles.frames_to_track > (handles.Nframes - handles.ffind-1)
    handles.frames_to_track = (handles.Nframes - handles.ffind-1);
    set(hObject,'String',num2str((handles.Nframes - handles.ffind-1),'%d'));
end
guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function frames_to_track_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frames_to_track (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calc_all.
function calc_all_Callback(hObject, eventdata, handles)
h = waitbar(0,'Click Cancel to Abort','Name','Calculating',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)
handles.ind = handles.ffind;
for step = handles.ffind:(handles.ffind+handles.frames_to_track)
    % Check for Cancel button press
    if getappdata(h,'canceling')
        break
    end
    waitbar(step/handles.frames_to_track,h)
    if step ==(handles.ffind+handles.frames_to_track) 
        set(handles.slider1,'Value',get(handles.slider1,'Value')+1);
        
        slider1_Callback(handles.slider1, eventdata, handles)
    
    else
        handles = calculate_params(handles);
        set(handles.slider1,'Value',handles.ind+1);
        handles.ind = handles.ind+1;
    end
    figure(h);
end
bub_stats = {num2str(max(handles.nbubs(handles.ffind+1:(handles.ffind+handles.frames_to_track))), 'Max number of bubbles = %0.0f')...
               num2str(min(handles.nbubs(handles.ffind+1:(handles.ffind+handles.frames_to_track))), 'Min number of bubbles = %0.0f')... 
               num2str(mean(handles.nbubs(handles.ffind+1:(handles.ffind+handles.frames_to_track))), 'Average number of bubbles = %0.1f')};
set(handles.bub_stats,'String',bub_stats);
delete(h)  


% --- Executes on button press in save_data.
function save_data_Callback(hObject, eventdata, handles)
fid = fopen([get(handles.saveas_filename,'String') '.txt'],'w');
bub_stats = get(handles.bub_stats,'String');
fprintf(fid,[bub_stats{1} '\n']);
fprintf(fid,[bub_stats{2} '\n']);
fprintf(fid,[bub_stats{3} '\n']);
fprintf(fid,'\nBubbles per Frame:\n');
fprintf(fid,'%d, ',handles.nbubs);
fclose(fid);




function saveas_filename_Callback(hObject, eventdata, handles)
% hObject    handle to saveas_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of saveas_filename as text
%        str2double(get(hObject,'String')) returns contents of saveas_filename as a double


% --- Executes during object creation, after setting all properties.
function saveas_filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to saveas_filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
