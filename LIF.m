function varargout = LIF(varargin)
% LIF MATLAB code for LIF.fig
%      LIF, by itself, creates a new LIF or raises the existing
%      singleton*.
%
%      H = LIF returns the handle to a new LIF or the handle to
%      the existing singleton*.
%
%      LIF('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LIF.M with the given input arguments.
%
%      LIF('Property','Value',...) creates a new LIF or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LIF_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LIF_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LIF

% Last Modified by GUIDE v2.5 11-Aug-2014 16:55:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LIF_OpeningFcn, ...
                   'gui_OutputFcn',  @LIF_OutputFcn, ...
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


% --- Executes just before LIF is made visible.
function LIF_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LIF (see VARARGIN)

% Choose default command line output for LIF
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);
set(findobj('Tag','WLStartText'),'String',num2str(round(get(findobj('Tag','WLStartSlider'),'Value'))))
set(findobj('Tag','WLEndText'),'String',num2str(round(get(findobj('Tag','WLEndSlider'),'Value'))))
set(findobj('Tag','StepSizeText'),'String',num2str(round(get(findobj('Tag','StepSizeSlider'),'Value'))))
set(findobj('Tag','NumReadsText'),'String',num2str(round(get(findobj('Tag','NumReadsSlider'),'Value'))))
% UIWAIT makes LIF wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LIF_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function GUIDeleteCallback(hObject, eventdata, handles)
disp('Closing');
try
    delete(handles.adc);
catch
end
try
    delete(handles.mono);
catch
end

% --- Executes on button press in FindPortspb.
function FindPortspb_Callback(hObject, eventdata, handles)
% hObject    handle to FindPortspb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.lbCom, 'String', scanports);


% --- Executes on selection change in lbCom.
function lbCom_Callback(hObject, eventdata, handles)
% hObject    handle to lbCom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbCom contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbCom


% --- Executes during object creation, after setting all properties.
function lbCom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbCom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in AssignADCpb.
function AssignADCpb_Callback(hObject, eventdata, handles)
% hObject    handle to AssignADCpb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(get(hObject, 'String'), 'Assign ADC'))
    vals = get(handles.lbCom, 'String');
    cpName = vals(get(handles.lbCom, 'Value'));
    adc = ADC(cpName);
    handles.adc = adc;
    set(hObject, 'String','Remove ADC');
    disp('ADC')
else
    delete(handles.adc)
    set(hObject, 'String','Assign ADC');
end
guidata(hObject, handles);

% --- Executes on button press in AssignLaserpb.
function AssignLaserpb_Callback(hObject, eventdata, handles)
% hObject    handle to AssignLaserpb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(get(hObject, 'String'), 'Assign Laser'))
    vals = get(handles.lbCom, 'String');
    cpName = vals(get(handles.lbCom, 'Value'));
    laser = Laser(cpName);
    handles.laser = laser;
    set(hObject, 'String','Remove Laser');
    disp('Set Laser')
else
    delete(handles.laser)
    set(hObject, 'String','Assign Laser');
end
guidata(hObject, handles);

% --- Executes on button press in AssignMonopb.
function AssignMonopb_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(strcmp(get(hObject, 'String'), 'Assign Mono'))
    vals = get(handles.lbCom, 'String');
    cpName = vals(get(handles.lbCom, 'Value'));
    mono = Stepper(cpName);
    handles.mono = mono;
    set(hObject, 'String','Remove Mono');
    disp('Monochromator Started')
else
    delete(handles.mono)
    set(hObject, 'String','Assign Mono');
end
guidata(hObject, handles);

% --- Executes on button press in AssignMonopb.
function CalibrateMonopb_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('Calibrating monochromator')
handles.mono.calibrate()

% --- Executes on button press in AssignMonopb.
function WLStartSlider_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slider_value = get(hObject,'Value');
set(findobj('Tag','WLStartText'),'String',num2str(round(slider_value)))

% --- Executes on button press in AssignMonopb.
function WLEndSlider_Callbacks(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slider_value = get(hObject,'Value');
set(findobj('Tag','WLEndText'),'String',num2str(round(slider_value)))

% --- Executes on button press in AssignMonopb.
function WLStepSizeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slider_value = get(hObject,'Value');
set(findobj('Tag','StepSizeText'),'String',num2str(round(slider_value)))

% --- Executes on button press in AssignMonopb.
function NumReadsSlider_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
slider_value = get(hObject,'Value');
set(findobj('Tag','NumReadsText'),'String', num2str(round(slider_value)))

% --- Executes on button press in AssignMonopb.
function ScanButton_Callback(hObject, eventdata, handles)
% hObject    handle to AssignMonopb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
swl = str2double(get(findobj('Tag','WLStartText'),'String'));
ewl = str2double(get(findobj('Tag','WLEndText'),'String'));
dwl = str2double(get(findobj('Tag','StepSizeText'),'String'));
num_reads = str2double(get(findobj('Tag','NumReadsText'),'String'));
num_scans = 1;
fn = get(findobj('Tag', 'FilenameText'), 'String');
gain = 1.0;
conc = '';
cuv = '';
disp([swl ewl dwl num_reads])
disp(fn)
LIFScan( swl, ewl, dwl, handles.mono, handles.adc, handls.laser, num_reads, num_scans, fn, gain, conc, cuv)
