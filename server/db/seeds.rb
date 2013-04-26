# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

conf_a = <<-eos
import bpy

# --- we set the render context to the variable r
r=bpy.context.scene.cycles

r.device = 'CPU'
#r.samples = 150

# --- here we set the render resolution and pixel aspect ratio to Full HD
#r.resolution_x=1920
#r.resolution_y=1080
r.pixel_aspect_x=1
r.pixel_aspect_y=1
r.resolution_percentage=100

# --- we might want to make sure AA is ON, and force to use 8 samples
r.use_antialiasing=True
r.antialiasing_samples='8'

# --- final production renders should not have stamps, make sure they are not used
r.use_stamp=False

# the same goes for scene simplifications,
r.use_simplify=False
eos

conf_b = <<-eos
import bpy

bpy.context.user_preferences.system.compute_device_type = 'CUDA'

# --- we set the render context to the variable r
r=bpy.context.scene.cycles

r.device = 'GPU'
#r.samples = 150

# --- here we set the render resolution and pixel aspect ratio to Full HD
#r.resolution_x=1920
#r.resolution_y=1080
r.pixel_aspect_x=1
r.pixel_aspect_y=1
r.resolution_percentage=100

# --- we might want to make sure AA is ON, and force to use 8 samples
r.use_antialiasing=True
r.antialiasing_samples='8'

# --- final production renders should not have stamps, make sure they are not used
r.use_stamp=False

# the same goes for scene simplifications,
r.use_simplify=False
eos

BlenderConfig.create(:name => "Cycles with CPU", :description => "Cycles with CPU", :config => conf_a, :public => 1)
BlenderConfig.create(:name => "Cycles with GPU", :description => "Cycles with GPU and CUDA", :config => conf_b, :public => 1)

Group.create(:name => "Default", :description => "Default group")
Group.create(:name => "Public Event", :description => "Public event")
