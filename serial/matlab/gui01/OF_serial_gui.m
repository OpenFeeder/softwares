function OF_serial_gui

% Author: Jerome Briot - https://github.com/JeromeBriot

comPort = 'COM32';

ton_min = 1070;
ton_max = 2500;

echoCommands = true;
delay = 0.03;
s = [];

fig = figure(1);
clf

figSize = [800 600];

set(fig, ...
    'units', 'pixels', ...
    'position', [0 0 figSize], ...
    'resize', 'off', ...
    'menubar', 'none', ...
    'numbertitle', 'off', ...
    'name', 'OpenFeeder - Serial interface', ...
    'visible', 'off', ...
    'CloseRequestFcn', @closeCOMWindow);

movegui(fig, 'center')

set(fig, 'visible', 'on');

uiSketchfactor = figSize(1)/140; % 140/105 mm => 800x600 px

%% Button Zone
uiButtonConnect = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [5 90 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Connect', ...
    'tag', 'uiButtonConnect', ...
    'callback', @connectCOM);
uiButtonDisconnect = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [30 90 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Disconnect', ...
    'tag', 'uiButtonDisconnect', ...
    'enable', 'off', ...
    'callback', @disconnectCOM);
uiButtonSetDate = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [5 75 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Set date', ...
    'tag', 'uiButtonSetDate', ...
    'enable', 'off', ...
    'callback', @setDate);
uiButtonGetDate = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [30 75 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Get date', ...
    'tag', 'uiButtonGetDate', ...
    'enable', 'off', ...
    'callback', @getDate);
uiButtonCloseDoor = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [5 60 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Close door', ...
    'tag', 'uiButtonCloseDoor', ...
    'enable', 'off', ...
    'callback', @closeDoor);
uiButtonOpenDoor = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [30 60 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Open door', ...
    'tag', 'uiButtonOpenDoor', ...
    'enable', 'off', ...
    'callback', @openDoor);
uiButtonSliderDoor = uicontrol(fig, ...
    'style', 'slider', ...
    'units', 'pixels', ...
    'position', [5 50 45 5]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Close door', ...
    'tag', 'uiButtonCloseDoor', ...
    'enable', 'on', ...
    'min', ton_min, ...
    'max', ton_max, ...
    'value', ton_min, ...
    'SliderStep', [0.01 0.10], ...
    'callback', @setDoorPosition);







uiButtonEmptyBuffer = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [5 5 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Empty buffer', ...
    'tag', 'uiButtonEmptyBuffer', ...
    'enable', 'off', ...
    'callback', @empty_uart_buffer);

uiButtonQuit = uicontrol(fig, ...
    'units', 'pixels', ...
    'position', [30 5 20 10]*uiSketchfactor, ...
    'fontweight', 'bold', ...
    'string', 'Quit', ...
    'tag', 'uiButtonQuit', ...
    'enable', 'on', ...
    'callback', @closeCOMWindow);


%% Preview zone
uiCommunicationWindow = uicontrol(fig, ...
    'style', 'listbox', ...
    'units', 'pixels', ...
    'position', [80 0 60 105]*uiSketchfactor, ...
    'horizontalalignment', 'left', ...
    'fontweight', 'bold', ...
    'tag', 'uiCommunicationWindow', ...
    'min', 0, ...
    'max', 2, ...
    'keypressfcn', @keyPressComWindow);
hcmenu = uicontextmenu;
uimenu(hcmenu,'Label','Clear all','Callback',{@clearComWindow 'all'});
uimenu(hcmenu,'Label','Clear selection','Callback', {@clearComWindow 'select'});
uimenu(hcmenu,'Label','Copy all','Callback',{@copyComWindow 'all'}, 'separator', 'on');
uimenu(hcmenu,'Label','Copy selection','Callback', {@copyComWindow 'select'});
set(uiCommunicationWindow,'uicontextmenu',hcmenu)

    function connectCOM(obj, event)
        
        s = instrfind('Port', comPort);
        
        if isempty(s)
            s = serial(comPort, ...
                'Terminator', {'CR/LF', '' }, ...
                'Timeout', 2, ...
                'BytesAvailableFcnMode', 'terminator', ...
                'BytesAvailableFcn', @readDataFromOF);
            pause(delay)
            fopen(s);
        else
            if ~strcmp(s.Status, 'open')
                fopen(s);
            end
            
            set(s, 'Terminator', {'CR/LF', '' }, ...
                'Timeout', 2, ...
                'BytesAvailableFcnMode', 'terminator', ...
                'BytesAvailableFcn', @readDataFromOF);
        end
        
        % Purge input buffer
        while(s.BytesAvailable>0)
            fscanf(s);
            pause(delay);
        end
        
        set(uiButtonConnect, 'enable', 'off')
        set(uiButtonDisconnect, 'enable', 'on')
        set(uiButtonSetDate, 'enable', 'on')
        set(uiButtonGetDate, 'enable', 'on')
        set(uiButtonOpenDoor, 'enable', 'on')
        set(uiButtonCloseDoor, 'enable', 'on')
        set(uiButtonEmptyBuffer, 'enable', 'on')
        
    end

    function disconnectCOM(obj, event)
        
        if strcmp(s.Status, 'open')
            fclose(s);
        end
        
        delete(s)
        
        set(uiButtonConnect, 'enable', 'on')
        set(uiButtonDisconnect, 'enable', 'off')
        set(uiButtonSetDate, 'enable', 'off')
        set(uiButtonGetDate, 'enable', 'off')
        set(uiButtonOpenDoor, 'enable', 'off')
        set(uiButtonCloseDoor, 'enable', 'off')
        set(uiButtonEmptyBuffer, 'enable', 'off')
    end


    function readDataFromOF(obj, event)
        
        str = get(uiCommunicationWindow, 'string');
        str = cellstr(str);
        
        tmp = fscanf(s);
        str{end+1} = strrep(tmp, 9, [32 32 32]);
        
        set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        
    end

    function clearComWindow(obj, event, flag)
        
        if strcmpi(flag, 'all')
            set(uiCommunicationWindow, 'string', {}, 'value', 0)
        else
            idx = get(uiCommunicationWindow, 'value');
            str = get(uiCommunicationWindow, 'string');
            str(idx) = [];
            set(uiCommunicationWindow, 'string', str, 'value', idx(1))
        end
    end

    function copyComWindow(obj, event, flag)
        
        if strcmpi(flag, 'all')
            str = get(uiCommunicationWindow, 'string');
        else
            idx = get(uiCommunicationWindow, 'value');
            str = get(uiCommunicationWindow, 'string');
            str = str(idx);
        end
        
        
        %         str = sprintf('%s\n', str{:});
        str = sprintf('%s', str{:});
        clipboard('copy', str)
        
    end

    function keyPressComWindow(obj, event)
        
        
        if strcmp(event.Key, 'shift') || strcmp(event.Key, 'alt') || strcmp(event.Key, 'control')
            return
        end
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', event.Character);
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        sendCommand(event.Character)
        
    end

    function sendCommand(arg)
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', arg);
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        fprintf(s, arg, 'async');
        pause(delay)
        
    end

    function setDate(obj, event)
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', 's');
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        fprintf(s, 's', 'async');
        pause(5*delay)
        
        V = datevec(now);
        V(1) = V(1)-2000;
        V(end) = round(V(end));
        
        fprintf(s, '%d\r', V([3 2 1]), 'async');
        pause(5*delay)
        fprintf(s, '%d\r', V([4 5 6]), 'async');
        pause(5*delay)
        
    end

    function getDate(obj, event)
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', 't');
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        
        fprintf(s, 't', 'async');
        
    end

    function openDoor(obj, event)
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', 'o');
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        
        fprintf(s, 'o', 'async');
        
        set(uiButtonSliderDoor, 'value', ton_max)
    end


    function closeDoor(obj, event)
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', 'c');
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        
        fprintf(s, 'c', 'async');
        set(uiButtonSliderDoor, 'value', ton_min)
    end

    function setDoorPosition(obj, event)
        
        val = get(obj, 'value');
        val = uint16(round(val))
        
        if echoCommands
            str = get(uiCommunicationWindow, 'string');
            str{end+1} = sprintf('<html><font color="#FF18E6"><b> => %s</b></font></html>', 'p');
            set(uiCommunicationWindow, 'string', str, 'value', numel(str));
        end
        
        fprintf(s, 'p', 'async');
        pause(delay)
        fwrite(s, num2str(val), 'async');
    end

    function empty_uart_buffer(obj, event)
        
        while(s.BytesAvailable>0)
            fscanf(s);
            pause(delay)
        end
        
    end

    function closeCOMWindow(obj, event)
        
       s = instrfind('Port', comPort);
       
       if ~isempty(s)
           
           disconnectCOM([],[])
           
       end
        
       closereq;
    end

end