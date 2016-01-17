require 'ostruct'

files = []

next_time = Time.now + 1
while true
  if Time.now > next_time
    next_time = Time.now + 1

    date_string = `date +%s`.chomp
    filename = "#{date_string}.jpg"
    bike_filename = "#{date_string}_bike.jpg"

    files << OpenStruct.new(full: filename, bike: bike_filename, keep: false)

    `./v4l2grab -d /dev/video1 -W 720 -I -1 -o #{filename}`
    `convert #{filename} -crop 250x150+350+310 +repage #{bike_filename}`
    `montage -font Helvetica -geometry +0+0 -label "#{`date`}" #{filename} #{filename}`
    
    if files.length > 10
      old_file = files.shift
      if old_file.keep
        puts "uploading #{old_file.full}"
        # `aws s3 cp #{old_file.full} s3://najatis-motorcycle/#{old_file.full}`
        # `aws s3 cp s3://najatis-motorcycle/#{old_file.full} s3://najatis-motorcycle/latest.jpg`
        # puts "Uploaded #{filename} at #{Time.now}."
      else
        `rm #{old_file.full}`
        `rm #{old_file.bike}`
      end
    end

    files.each_with_index do |other_file, i|
      `compare #{files[0].bike} #{other_file.bike} -fuzz 2500 -lowlight-color Transparent -compose src other_diff.png`      

      if i == 0
        `cp other_diff.png diff.png`
      else
        `convert diff.png other_diff.png -compose overlay -composite diff.png`
      end
    end

    active_pixels = `convert diff.png -alpha extract  -format "%[fx:round(mean*w*h)]" info:`.to_i
    total_pixels = `convert diff.png -format "%[fx:w*h]" info:`.to_i
    activity = active_pixels/total_pixels.to_f
    if activity > 0.5
      puts "#{active_pixels} of #{total_pixels} is #{activity.round(2)} at #{Time.now}"
      
      files.each { |f| f.keep = true }
      `convert -delay 100 #{files.map(&:full).join(' ')} -loop 0 #{files.last.full.gsub('jpg','gif')}`
    end
  end
end