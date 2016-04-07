require 'ostruct'
require 'thread'

v4l2grab = 'v4l2grab'
device = '/dev/video1'
delta = 4

uploading = Mutex.new
next_time = Time.now + delta

while true
  if Time.now > next_time && uploading.try_lock
    now = Time.now
    next_time = now + delta

    Thread.new do
      path = "~/images/#{now.year}/#{now.month}/#{now.day}/#{now.hour}/"
      `mkdir -p #{path}`

      date_string = now.to_i.to_s
      filename = "#{path}/#{date_string}.jpg"

      `#{v4l2grab} -d #{device} -W 720 -I -1 -o #{filename}`
      `montage -font Helvetica -geometry +0+0 -label "#{`date`}" #{filename} #{filename}`

      puts "Uploaded #{filename} at #{Time.now}."
      `aws s3 cp #{filename} s3://najatis-motorcycle/#{now.year}/#{now.month}/#{now.day}/#{now.hour}/#{date_string}.jpg`
      `aws s3 cp #{filename} s3://najatis-motorcycle/latest.jpg`
      uploading.unlock
    end
  end
end

# `convert #{filename} -crop 250x150+350+310 -colorspace Gray +repage #{bike_filename}`
