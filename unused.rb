require 'pathname'
require 'fileutils'

location = ARGV.first
VERBOSE = false 
# In case you wonder why a certain image is marked as unused,
# set to true and it will show what images are found in which file.
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
excluded_folders = ['vendor', '.appiconset', '.launchimage']
excluded_images = []
imagesets = ['.imageset']
# Create an array with only the image names but not the ones under excluded folders.
image_paths.each do |path|
	do_next = false
	excluded_folders.each do |e|
		if path.to_s.include?(e) && File.basename(path, '.*').to_s != e
			do_next = true
			break
		end
	end
	excluded_images.each do |e|
		if File.basename(path, '.*').to_s == e
			do_next = true
			break
		end
	end
	imagesets.each do |i|
		if path.to_s.include?(i)  && File.basename(path, '.*').to_s != i
			images << /(\/.+)\/(.+)(#{i})\//.match(path.to_s.downcase)[2]
			do_next = true
			break
		end
	end
	next if do_next
	images << File.basename(path, '.*').to_s
end
images.uniq!
images.sort_by! { |m| m.downcase }
p images if VERBOSE
# Trim '@2x' if it exists.
images.each do |image|
	images.delete(image) if image.include?("@2x")
end
# Search for occurences of each image name in all our files.
# NOTE: It WILL search within excluded folders for YOUR images,
# since there's the chance you have modified external libraries with your own images.
files.each do |file|
	p file if VERBOSE
	# Remove from the images array what we find: these will be kept.
	images.delete_if do |image|
		unless File.directory?(file)
			# An image can be defined with 
			# imageNamed: @"image", imageNamed: @"image.png", or imageNamed: @"image@2x.png".
			if File.read(file).include?('imageNamed:@"' + image + '@2x.png"') or
				File.read(file).include?('imageNamed:@"' + image + '.png"') or
				File.read(file).include?('imageNamed:@"' + image + '"') or
				File.read(file).include?('imageNamed: @"' + image + '@2x.png"') or
				File.read(file).include?('imageNamed: @"' + image + '.png"') or
				File.read(file).include?('imageNamed: @"' + image + '"')
				p image if VERBOSE
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
		# If the last path component does equal the image name BUT the file path also includes the containing imageset, don't remove it, we will just remove the imageset altogether
		if (File.basename(file, '.*').to_s == image and !file.to_s.include?('.imageset')) or
			(File.basename(file, '.*').to_s.downcase == image + '@2x' and !file.to_s.include?('.imageset')) or
			File.basename(file).to_s == image + '.imageset'
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
		image_to_remove_from_project = ''
		pbxproj = nil
		lines = []
		# Pbxproj doesn't need updating when deleting imagesets, it updates the project automatically.
		if File.extname(file) != '.imageset'
			Dir['*/*.*'].each do |f|
				if File.extname(f) == '.pbxproj'
					image_to_remove_from_project = File.basename(file)
					# If pbxproj contains the file we are asking to delete.
					if File.read(f).include?(image_to_remove_from_project)
						# Read the contents of pbxproj into an array.
						lines = File.readlines(f)
						lines.delete_if do |l|
							# Delete the line that contains the file we are asking to delete;
							# it will rewrite pbxproj in the next step, only if you choose yes or delete
							true if l.include?(image_to_remove_from_project)
						end
						pbxproj = f
					end
				end
			end
		end
		if answer.downcase == 'd' or answer.downcase == 'delete'
			deleted_files << file
			FileUtils.rm_rf(file)
			# Pbxproj doesn't need updating when deleting imagesets, it updates the project automatically.
			if File.extname(file) != '.imageset'
				File.open(pbxproj, 'w') do |f|
					f.write(lines.join(''))
				end
			end
		elsif answer.downcase == 'o' or answer.downcase == 'one by one'
			puts 'Delete ' + file + '? y(es)/n(o)'
			individual_answer = STDIN.gets.chomp
			if individual_answer == 'y' or individual_answer == 'yes'
				deleted_files << file
				FileUtils.rm_rf(file)
				# Pbxproj doesn't need updating when deleting imagesets, it updates the project automatically.
				if File.extname(file) != '.imageset'
					File.open(pbxproj, 'w') do |f|
						f.write(lines.join(''))
					end
				end
			end
		end
	end
	unless answer == 'c' or answer == 'cancel'
		unless deleted_files.count == 0
			puts '---'
			puts 'Files deleted:'
			puts deleted_files
			puts '---'
			puts 'Done'
		else
			p '---'
			p 'No files harmed.'
		end
	end
else
	puts '---'
	puts 'Your project contains no unused assets. Bravo!'
end