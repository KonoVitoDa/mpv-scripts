-- Original script: https://github.com/samhippo/mpv-scripts/blob/master/cut-video.lua
-- This is an improved version of cut-video.lua by samhippo. Some of the new features are: export GIFs; burn subtitles; show milliseconds in output filename; preserve cut points after generating clip; and some more minor chages.
-- To use all the new features you'll need to add some new settings to your mpv.conf and input.conf, but since I'm too lazy detail everything, I'm just sharing below what I'm currently using in my conf files:
-- input.conf:
--    Shift+PGUP	script-message cut-left
--    Shift+PGDWN	script-message cut-right
--    Ctrl+Shift+PGUP	script-message cut-start
--    Ctrl+Shift+PGDWN	script-message cut-end
--    Shift+PGUP	{cut-video-long} script-message cut-left-long
--    Shift+PGDWN	{cut-video-long} script-message cut-right-long
--    Ctrl+Shift+PGUP	{cut-video-long} script-message cut-start-long
--    Ctrl+Shift+PGDWN	{cut-video-long} script-message cut-end-long
--    Shift+ENTER	script-message cut-finish "mkv" "-c copy -map 0" ; show-text "Generating MKV file (copy)"
--    Shift+ENTER	{mp4} script-message cut-finish "mp4" "-c copy -map 0" ; show-text "Generating MP4 file (copy)"
--    Ctrl+ENTER	script-message cut-finish "mp4" "-c:v libx264 -crf 18 -c:a aac -b:a 512k -map_chapters -1" ; show-text "Generating MP4 file (reencode)"
--    Alt+ENTER	script-message cut-finish-gif "gif" "-filter_complex scale=1280:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse" ; show-text "Generating GIF file"
--    CtrL+Alt+ENTER	script-message cut-finish-subs "mp4" "-c:v libx264 -crf 18 -c:a aac -b:a 512k" ; show-text "Burning subs"
--    Ctrl+Shift+ENTER	script-message cut-finish "mkv" "-c:v libx264 -crf 18 -c:a aac -b:a 512k -map 0 -map_chapters -1" ; show-text "Generating MKV file (reencode)"
--
--
-- mpv.conf:
--    [long-video]
--    profile-cond=duration >= 3600 and mp.command('enable-section cut-video-long')
--    profile-restore=copy-equal
--
--    [not-long-video]
--    profile-cond=not(duration >= 3600) and mp.command('disable-section cut-video-long')
--
--    [mp4]
--    profile-cond=path:find('.mp4') and mp.command('enable-section mp4')
--    profile-restore=copy-equal

--    [not-mp4]
--    profile-cond=not(path:find('.mp4')) and mp.command('disable-section mp4')
--    profile-restore=copy-equal



local start_time_formated = nil
local start_time_seconds = nil
local end_time_formated = nil
local end_time_seconds = nil
local is_processing = false
local utils = require "mp.utils"
local ov = mp.create_osd_overlay("ass-events")

function fn_cut_finish(p1,p2)
  if(start_time_seconds == nil or end_time_seconds == nil) then
    mp.osd_message("Time not set")
  else
    local video_args = '-c copy'
    local output_format =  mp.get_property("filename"):match("[^.]+$")
    if((p1 == nil and p2 == nil) or (p1 == '' and p2 == '')) then
    else
      if(p1 == nil or p1 == '') then
      else
        output_format = p1
      end
      if(p2 == nil or p2 == '') then
        video_args = ''
      else
        video_args = p2
      end
    end
    local output_directory, _ = utils.split_path(mp.get_property("path"))
    local output_filename = mp.get_property("filename/no-ext").."_"..string.gsub(start_time_formated,":",".").." – "..string.gsub(end_time_formated,":",".").."."..output_format
    local output_path = utils.join_path(output_directory, output_filename)
    local args = {"ffmpeg", "-ss", tostring(start_time_seconds), "-i", tostring(mp.get_property("path")), "-to", tostring(end_time_seconds-start_time_seconds)}
    for token in string.gmatch(video_args, "[^%s]+") do
      table.insert(args,token)
    end
    table.insert(args,output_path)
    --utils.subprocess_detached({args = args, playback_only = false})


  is_processing = true
  ov.data = "\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}".."Processing..."
  ov:update()

    local r = mp.command_native({
      name = "subprocess",
      playback_only = false,
      capture_stdout = true,
      detach = false,
      args = args,
  })

    print("result: " .. r.stdout)

    is_processing = false
    ov:remove()
  end
end

function fn_cut_finish_gif(p1,p2)
  if(start_time_seconds == nil or end_time_seconds == nil) then
    mp.osd_message("Time not set")
  else
    local video_args = '-c copy'
    local output_format =  mp.get_property("filename"):match("[^.]+$")
    if((p1 == nil and p2 == nil) or (p1 == '' and p2 == '')) then
    else
      if(p1 == nil or p1 == '') then
      else
        output_format = p1
      end
      if(p2 == nil or p2 == '') then
        video_args = ''
      else
        video_args = p2
      end
    end
    local output_directory, _ = utils.split_path(mp.get_property("path"))
    local output_filename = mp.get_property("filename/no-ext").."_"..string.gsub(start_time_formated,":",".").." – "..string.gsub(end_time_formated,":",".").."."..output_format
    local output_path = utils.join_path(output_directory, output_filename)
    local args = {'ffmpeg', '-ss', tostring(start_time_seconds), "-to", tostring(end_time_seconds), "-i", tostring(mp.get_property("path"))}
    for token in string.gmatch(video_args, "[^%s]+") do
      table.insert(args,token)
    end
    table.insert(args,output_path)
    --utils.subprocess_detached({args = args, playback_only = false})


  is_processing = true
  ov.data = "\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}".."Processing..."
  ov:update()

    local r = mp.command_native({
      name = "subprocess",
      playback_only = false,
      capture_stdout = true,
      detach = false,
      args = args,
  })

    print("result: " .. r.stdout)

    is_processing = false
    ov:remove()
  end
end

-- Due to FFmpeg limitations, this function will only work if mpv's working-directory is also the directory of the playing video. All you need to do is open the file directly from the File Explorer.
function fn_cut_finish_subs(p1,p2)
  if(start_time_seconds == nil or end_time_seconds == nil) then
    mp.osd_message("Time not set")
  else
    local video_args = '-c copy'
    local output_format =  mp.get_property("filename"):match("[^.]+$")
    if((p1 == nil and p2 == nil) or (p1 == '' and p2 == '')) then
    else
      if(p1 == nil or p1 == '') then
      else
        output_format = p1
      end
      if(p2 == nil or p2 == '') then
        video_args = ''
      else
        video_args = p2
      end
    end
    local output_directory, _ = utils.split_path(mp.get_property("path"))
    local output_filename = mp.get_property("filename/no-ext").."_"..string.gsub(start_time_formated,":",".").." – "..string.gsub(end_time_formated,":",".").."(Hardsub)".."."..output_format
    local output_path = utils.join_path(output_directory, output_filename)
	local args = {"ffmpeg", "-ss", tostring(start_time_seconds), "-to", tostring(end_time_seconds), "-copyts", "-i", tostring(mp.get_property("path")), "-ss", tostring(start_time_seconds), "-filter_complex", "subtitles='"..mp.get_property("filename").."':si="..math.floor(mp.get_property("sid")-1)}
    for token in string.gmatch(video_args, "[^%s]+") do
      table.insert(args,token)
    end
    table.insert(args,output_path)
    --utils.subprocess_detached({args = args, playback_only = false})


  is_processing = true
  ov.data = "\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}".."Processing..."
  ov:update()

    local r = mp.command_native({
      name = "subprocess",
      playback_only = false,
      capture_stdout = true,
      detach = false,
      args = args,
  })

    print("result: " .. r.stdout)

    is_processing = false
    ov:remove()
  end
end

function fn_cut_start()
  start_time_seconds = 0
  start_time_formated = mp.get_property_osd('time-start/full'):sub(4)
  mp.msg.info("START TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_end()
  end_time_seconds = mp.get_property_number("duration")
  end_time_formated = mp.get_property_osd('duration/full'):sub(4)
  mp.msg.info("END TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_left()
  start_time_seconds = mp.get_property_number("time-pos")
  start_time_formated = mp.get_property_osd('time-pos/full'):sub(4)
  mp.msg.info("START TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_right()
  end_time_seconds = mp.get_property_number("time-pos")
  end_time_formated = mp.get_property_osd('time-pos/full'):sub(4)
  mp.msg.info("END TIME: "..end_time_seconds)
 showOnScreen()
end

function fn_cut_start_long()
  start_time_seconds = 0
  start_time_formated = mp.get_property_osd('time-start/full')
  mp.msg.info("START TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_end_long()
  end_time_seconds = mp.get_property_number("duration")
  end_time_formated = mp.get_property_osd('duration/full')
  mp.msg.info("END TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_left_long()
  start_time_seconds = mp.get_property_number("time-pos")
  start_time_formated = mp.get_property_osd('time-pos/full')
  mp.msg.info("START TIME: "..start_time_seconds)
  showOnScreen()
end

function fn_cut_right_long()
  end_time_seconds = mp.get_property_number("time-pos")
  end_time_formated = mp.get_property_osd('time-pos/full')
  mp.msg.info("END TIME: "..end_time_seconds)
 showOnScreen()
 end

function showOnScreen()
  local st = (start_time_formated == nil and '' or start_time_formated)
  local et = (end_time_formated == nil and '' or end_time_formated)
  ov.data = "{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}".."Start:  "..st.."\n{\\an4}{\\b1}{\\fs20}{\\1c&H00FFFF&}".."End:  "..et
  ov:update()
end

mp.register_script_message('cut-start', fn_cut_start)
mp.register_script_message('cut-end', fn_cut_end)
mp.register_script_message('cut-left', fn_cut_left)
mp.register_script_message('cut-right', fn_cut_right)
mp.register_script_message('cut-start-long', fn_cut_start_long)
mp.register_script_message('cut-end-long', fn_cut_end_long)
mp.register_script_message('cut-left-long', fn_cut_left_long)
mp.register_script_message('cut-right-long', fn_cut_right_long)
mp.register_script_message('cut-finish', fn_cut_finish)
mp.register_script_message('cut-finish-gif', fn_cut_finish_gif)
mp.register_script_message('cut-finish-subs', fn_cut_finish_subs)
