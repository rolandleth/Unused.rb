require 'pathname'
require 'fileutils'

location = ARGV.first
loop do
	begin
		# Try to change directory.
		Dir.chdir(location.to_s)
	rescue StandardError => e
		# If an exception is raised, it means the location doesn't exist.
		puts e
		puts "Please enter your project's path or ctrl-c to cancel"
		location = STDIN.gets.chomp
		next
	end
	# If no exception is raised, break and carry on.
	break
end
# All the files.
files = Dir['**/*.{m,mm,h,c,cpp,html}']
# All the file paths to our images.
image_paths = Dir['**/*.{jpg,png,jpeg,tiff,tif,gif,bmp,BMPf,ico,cur,xbm}']
images = []
# Enter your excluded folders and images here. 
# Folders: External libraries and classes, for example.
# Images: Icons and loading screens, for example.
excluded = ['vendor', 'default', 'icon']
# Create an array with only the image names but not the ones under excluded folders.
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
# Trim '@2x' if it exists.
images.each do |image|
	images.delete(image) if image.include?("@2x")
end
# Search for occurences of each image name in all our files.
# NOTE: We WILL search within excluded folders for YOUR images,
# since there's the chance you have modified external libraries with your own images.
files.each do |file|
	puts file
	# Remove from the images array what we want to keep. Anything we find in files, that is.
	images.delete_if do |image|
		unless File.directory?(file)
			# Just the start of the string, because an image can be defined with imageNamed: @"image",
			# but also with imageNamed: @"image.png", or even imageNamed: @"image@2x.png".
			# We want to cover everything.
			if File.read(file).downcase.include?('@"' + image.downcase)
				puts image
				true
			end
		end
	end
end
# Find the files.
files_to_be_deleted = []
Dir['**/*.*'].each do |file|
	images.each do |image|
		# Check if the last path component equals either the image name, or the image name + @2x, since we excluded those from the initial search.
		if File.basename(file, '.*').to_s.downcase == image.downcase or
			File.basename(file, '.*').to_s.downcase == image.downcase + '@2x' or
			File.basename(file, '.*').to_s.downcase == image.downcase + '.imageset'
			files_to_be_deleted << file
			break
		end
	end
end
unless files_to_be_deleted.count == 0
	puts '---'
	puts 'Unused images:'
	puts files_to_be_deleted.sort_by{ |m| m.downcase }
	puts "---"
	puts 'You can delete them all at once, or you can go through them one by one. d(elete)/c(ancel)/o(ne by one)'
	answer = STDIN.gets.chomp
	deleted_files = []
	imagesets_to_delete = {}
	files_to_be_deleted.sort_by{ |m| m.downcase }.each do |file|
		if answer.downcase == 'd' or answer.downcase == 'delete'
			deleted_files << file
			FileUtils.rm_f(file)
		elsif answer.downcase == 'o' or answer.downcase == 'one by one'
			puts 'Delete ' + file + '? y(es)/n(o)'
			individual_answer = STDIN.gets.chomp
			if individual_answer == 'y' or individual_answer == 'yes'
				deleted_files << file
				if File.directory?(file)
					# Maybe we don't want to delete some imagesets.
					imagesets_to_delete[file.to_sym] = 'yes'
				else
					FileUtils.rm_f(file)
				end
			end
		end
	end
	# Iterate again to check for empty imageset folders.
	files_to_be_deleted.sort_by{ |m| m.downcase }.each do |file|
		if File.directory?(file) and
			Dir.entries(file).count == 3 and
			Dir.entries(file)[0] == "." and
			Dir.entries(file)[1] == ".." and
			Dir.entries(file)[2] == "Contents.json" and
			imagesets_to_delete[file.to_sym] == 'yes' # Delete only what was chosen to be deleted on the previous step.
			FileUtils.rm_r(file)
		end
	end
	unless answer == 'c' or answer == 'cancel'
		puts '---'
		puts 'Files deleted:'
		puts deleted_files
		puts '---'
		puts 'Done'
	end
else
	puts '---'
	puts 'Your project contains no unused assets. Bravo!'
end