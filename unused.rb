require 'pathname'
require 'fileutils'

location = ARGV.first
loop do
	begin
		# Try to change directory
		Dir.chdir(location.to_s)
	rescue StandardError => e
		# If an exception is raised, it means the location doesn't exist
		puts e
		puts "Please enter your project's path or ctrl-c to cancel"
		location = STDIN.gets.chomp
		next
	end
	# If no exception is raised, break and carry on
	break
end
# All the files
files = Dir['**/*.{m,mm,h,c,cpp,html}']
# All the file paths to our images
image_paths = Dir['**/*.{jpg,png,jpeg,tiff,tif,gif,bmp,BMPf,ico,cur,xbm}']
images = []
# Enter your excluded folders and images here. 
# Folders: External libraries and classes, for example.
# Images: Icons and loading screens, for example.
excluded = ['vendor', 'default', 'icon']
# Create an array with only the image names but not the ones under excluded folders
image_paths.each do |path|
	do_next = false
	excluded.each do |e|
		if path.to_s.downcase.include?(e)
			do_next = true
			break
		end
	end
	next if do_next
	images << File.basename(path, '.*').to_s
end
# Trim '@2x' if it exists
images.each do |image|
	images.delete(image) if image.include?("@2x")
end
# Search for occurences of each image name in all our files
# NOTE: It WILL search within excluded folders for YOUR images
# since there's the chance one has modified external libraries with his own images
files.each do |file|
	puts file
	images.each do |image|
		unless File.directory?(file)
			# Just the start of the string, because you can define the image as imageNamed: @"image"
			# But also as imageNamed: @"image.png", or even imageNamed: @"image@2x.png". 
			# We want to cover everything.
			if File.read(file).downcase =~ /@\"#{image.downcase}/
				puts image
				images.delete(image)
			end
		end
	end
end
# Find our files
files_to_be_deleted = []
Dir['**/*.*'].each do |file|
	images.each do |image|
		# Check if the last path component equals either the image name, or the image name + @2x, since we excluded those from the initial search
		if File.basename(file, '.*').to_s.downcase == image.downcase || File.basename(file, '.*').to_s.downcase == image.downcase + '@2x'
			files_to_be_deleted << file
			break
		end
	end
end
unless files_to_be_deleted.count == 0
	puts '---'
	puts 'Unused images:'
	puts '---'
	puts files_to_be_deleted.sort_by{ |m| m.downcase }
	puts "---"
	puts 'Do you wish to delete them? Or you can go through them one by one. d(elete)/c(ancel)/o(ne by one)'
	answer = STDIN.gets.chomp
	deleted_files = []
	files_to_be_deleted.sort_by{ |m| m.downcase }.each do |file|
		if answer.downcase == 'd' or answer.downcase == 'delete'
			# File.delete(file)
			deleted_files << file
			FileUtils.rm_f(file)
		elsif answer.downcase == 'o' or answer.downcase == 'one by one'
			puts 'Delete ' + file + '? y(es)/n(o)'
			individual_answer = STDIN.gets.chomp
			if individual_answer == 'y' or individual_answer == 'yes'
				deleted_files << file
				# File.delete(file) 	
				FileUtils.rm_f(file)
			end
		end
	end
	unless answer == 'c' or answer == 'cancel'
		puts '---'
		puts 'Files deleted:'
		puts '---'
		puts deleted_files
		puts '---'
		puts 'Done'
	end
else
	puts 'Your project contains no unused assets. Bravo!'
end