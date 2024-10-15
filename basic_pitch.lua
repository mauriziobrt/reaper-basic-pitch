-- Initialize ImGui context
package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9.1'
local font = ImGui.CreateFont('sans-serif', 13)
local ctx = ImGui.CreateContext('My script')


-- Function to create a new track
function createNewTrack()
  -- Insert a new track at the end of the track list
  reaper.InsertTrackAtIndex(reaper.CountTracks(0), true)
  -- Get the newly created track (last track)
  local track = reaper.GetTrack(0, reaper.CountTracks(0) - 1)
  return track
end

-- Function to change file extension to .midi
function changeFileExtensionToMidi(filePath)
  return filePath:gsub("%.%w+$", "_basic_pitch.mid")
end

--:31: bad argument #1 to 'SetMediaItemPosition' (MediaItem expected)

-- Function to insert media file to a track at a specified position
function insertMediaFile(filePath, position)
  -- Ensure that the file path is valid
  if reaper.file_exists(filePath) then
    -- Insert the media file
    reaper.InsertMedia(filePath, 1)
    -- Get the last added item (the newly inserted media item)
    --local item = reaper.GetTrackMediaItem(track, reaper.CountTrackMediaItems(track)-1)
    --Set the position of the item
    --reaper.SetMediaItemPosition(item, position, false)
  else
    reaper.ShowMessageBox("The file path is invalid.", "Error", 0)
  end
end

-- Function to get selected media item

function get_selected_media_item()
  local item = reaper.GetSelectedMediaItem(0, 0)
  if item == nil then
    reaper.ShowMessageBox("Please select a media item first.", "Error", 0)
    return nil
  end
  return item
end
  
  -- Function to get file path of the media item
function get_media_item_filepath(item)
  local take = reaper.GetActiveTake(item)
  if take == nil then
    reaper.ShowMessageBox("No active take found.", "Error", 0)
    return nil
  end
  local source = reaper.GetMediaItemTake_Source(take)
  return reaper.GetMediaSourceFileName(source, "")
end

function main(listvalues)
  reaper.Undo_BeginBlock()
  -- Get the selected media item
  local item = get_selected_media_item()
  if item == nil then return end
  local input_path = get_media_item_filepath(item)
  local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  --reaper.ShowConsoleMsg(result)
  local output_path = input_path:match("(.*/)")
  --local output_path = input_path:gsub("%.wav$", ".midi")
  local output_file = changeFileExtensionToMidi(input_path)
  os.remove(output_file)
  --reaper.ShowConsoleMsg(output_path)
  local first_command = string.format('/opt/homebrew/bin/basic-pitch "%s" "%s" --onset-threshold "%f" --frame-threshold "%f" --minimum-note-length "%f" --minimum-frequency "%f" --maximum-frequency "%f"', output_path, input_path, listvalues.onset, listvalues.frame, listvalues.minlength, listvalues.minfreq, listvalues.maxfreq)
  --reaper.ShowConsoleMsg(first_command)
  local handle = io.popen(first_command)
  local result = handle:read("*a")
  handle:close()
  --reaper.ShowConsoleMsg(result)
  -- Create a new track
  --local newTrack = createNewTrack()
  -- Insert the media file into the new track at the specified position
  insertMediaFile(output_file, start_pos)
  -- Update the arrange view
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Process media item and create new take", -1)
end

local window_flags = ImGui.WindowFlags_None

--[[
--onset-threshold ONSET_THRESHOLD
  The minimum likelihood for an onset to occur, between
  0 and 1.
--frame-threshold FRAME_THRESHOLD
  The minimum likelihood for a frame to sustain, between
  0 and 1.
--minimum-note-length MINIMUM_NOTE_LENGTH
  The minimum allowed note length, in miliseconds.
--minimum-frequency MINIMUM_FREQUENCY
  The minimum allowed note frequency, in Hz.
--maximum-frequency MAXIMUM_FREQUENCY
  The maximum allowed note frequency, in Hz.
--multiple-pitch-bends
]]--

if not values then
  values = {onset=0.5, frame=0.5, minlength=100, minfreq = 40, maxfreq = 10000}--onset_threshold = 0.0, frame-threshold = 0.0}
end

local function gui()
  ImGui.PushFont(ctx, font)
  ImGui.SetNextWindowSize(ctx, 400, 300, ImGui.Cond_FirstUseEver)
  
  
  local visible, open = ImGui.Begin(ctx, 'Audio to MIDI', true)
  if visible then
    --if topmost then window_flags = window_flags | ImGui.WindowFlags_TopMost  end
    --rv, topmost = ImGui.Checkbox(ctx, 'Always on top',topmost)
    rv,values.onset = ImGui.SliderDouble(ctx, 'ONSET_THRESHOLD', values.onset,0.0, 1.0)
    rv,values.frame = ImGui.SliderDouble(ctx, 'FRAME_THRESHOLD', values.frame,0.0, 1.0)
    rv,values.minlength = ImGui.SliderDouble(ctx, 'MINIMUM_NOTE_LENGTH', values.minlength,100, 10000)
    rv,values.minfreq = ImGui.SliderDouble(ctx, 'MINIMUM_FREQUENCY', values.minfreq,40, 1000)
    rv,values.maxfreq = ImGui.SliderDouble(ctx, 'MAXIMUM_FREQUENCY', values.maxfreq,1000, 20000)
    if ImGui.Button(ctx, 'Convert to midi', ImGui.GetWindowWidth(ctx), 40) then
      main(values)
    end
    ImGui.End(ctx)
  end
  --end
  ImGui.PopFont(ctx)
  if open then
    reaper.defer(gui)
  end
end

ImGui.Attach(ctx, font)
reaper.defer(gui)
